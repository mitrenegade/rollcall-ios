//
//  DashboardViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 9/30/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import "DashboardViewController.h"
#import <Parse/Parse.h>
#import "Member.h"
#import "AttendanceViewController.h"
#import "RosterViewController.h"
#import "MKAdditions/UIAlertView+MKBlockAdditions.h"

@interface DashboardViewController ()

@end

@implementation DashboardViewController

@synthesize members, memberIDs;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)newMember:(id)sender {
    if ([inputName.text length] == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid name" message:@"Please enter a member name" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return;
    }
    NSString * name = inputName.text;
    NSString * email = inputEmail.text;
    if (email == 0) {
        email = @"";
    }
    
    [self addMemberToRosterWithName:name andEmail:email];
}

-(IBAction)newPractice:(id)sender {
    AttendanceViewController * attendanceController = [[AttendanceViewController alloc] init];
    [attendanceController setDelegate:self];
    [self.navigationController pushViewController:attendanceController animated:YES];
    
    // add "Save" button
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:attendanceController action:@selector(save:)];
    [attendanceController.navigationItem setRightBarButtonItem:done];

}

-(void)queryForAllMembersWithBlock:(void (^)(NSArray *, NSError *))gotCurrentRoster {
    if (members == nil) {
        members = [[NSMutableArray alloc] init];
    }
    [members removeAllObjects];
    if (memberIDs == nil) {
        memberIDs = [[NSMutableSet alloc] init];
    }
    [memberIDs removeAllObjects];

    [ParseHelper queryForAllParseObjectsWithClass:@"Member" withBlock:^(NSArray * results, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
                NSLog(@"Error! %@", [error description]);
            else {
                for (PFObject * p in results) {
                    NSLog(@"Searching for %@ in memberIDs %@", [p objectId], memberIDs);
                    if (![memberIDs containsObject:[p objectId]]) {
                        Member * m = [[Member alloc] initWithPFObject:p];
                        [members addObject:m];
                        [memberIDs addObject:[p objectId]];
                    }
                }
                NSLog(@"Loaded %d members from Parse", [members count]);
                
                gotCurrentRoster(members, nil);
            }
        });
    }];
}

-(void)addMemberToRosterWithName:(NSString*)name andEmail:(NSString*)email {
    
    // Create a PFObject using the Post class and set the values we extracted above
    
    Member * member = [[Member alloc] initWithName:name andEmail:email];
    PFObject *postObject = [member toPFObject];
    
    [ParseHelper addParseObjectToParse:postObject withBlock:^(BOOL succeeded, NSError * error) {
        if (error) // Failed to save, show an alert view with the error message
        {
            UIAlertView *alertView =
            [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"]
                                       message:nil
                                      delegate:self
                             cancelButtonTitle:nil
                             otherButtonTitles:@"Ok", nil];
            [alertView show];
            return;
        }
        if (succeeded) // Successfully saved, post a notification to tell other view controllers
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView =
                [[UIAlertView alloc] initWithTitle:@"Success"
                                           message:@"New member created"
                                          delegate:self
                                 cancelButtonTitle:nil
                                 otherButtonTitles:@"Ok", nil];
                [alertView show];
            });
        }    
    }];
}

-(void)newMonth:(id)sender {
    // clears status for all members
    [UIAlertView alertViewWithTitle:@"Start new month?" message:@"Do you want to reset all payments and statuses?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"OK"] onDismiss:^(int buttonIndex) {
        PFQuery * query = [PFQuery queryWithClassName:@"Member"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
            for (PFObject * obj in results) {
                NSLog(@"Resetting status and paid for %@", [obj objectForKey:@"name"]);
                [obj setObject:[NSNumber numberWithFloat:0] forKey:@"monthPaid"];
                [obj setObject:@"regular" forKey:@"status"];
                //[obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSError * error;
                [obj save:&error];
                if (error) {
                    NSLog(@"Error resetting status for %@: %@", [obj objectForKey:@"name"], error);
                    //[obj refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    [obj refresh:&error];
                    if (error) {
                        NSLog(@"Refreshed! Try saving");
                        [obj setObject:[NSNumber numberWithFloat:0] forKey:@"monthPaid"];
                        [obj setObject:@"regular" forKey:@"status"];
                        [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            NSLog(@"Success? %d error? %@", succeeded, error);
                        }];
                    }
                }
            }
            [UIAlertView alertViewWithTitle:@"Done!" message:@"Member information has been reset!"];
        }];
    } onCancel:^{
        return;
    }];
}

#pragma mark AttendanceViewDelegate 

-(void)getRosterWithBlock:(void (^)(NSArray *, NSError *))gotCurrentRoster {
    [self queryForAllMembersWithBlock:gotCurrentRoster];
}

-(void)didSaveWithDate:(NSDate *)date andNotes:(NSString*)notes andRoster:(NSMutableArray *)roster {
    Practice * newPractice = [[Practice alloc] init];
    [newPractice setPracticeDate:date];
    [newPractice setNotes:notes];
    
    PFObject * practiceObject = [newPractice toPFObject];
    PFRelation * relations = [practiceObject relationforKey:@"attendedBy"];
    
    for (Member * member in roster) {
        // create a new attendance
        Attendance * attendance = [[Attendance alloc] init];
        [attendance setPayment:[NSNumber numberWithFloat:0]];
        
        // associate member with attendance
        PFObject * attendanceObject = [attendance toPFObject];
        PFObject * memberObject = member.pfObject;
        PFRelation * memberAttendanceRelation = [attendanceObject relationforKey:@"forUser"];
        [memberAttendanceRelation addObject:memberObject];
        
        // associate practice with attendance
        [attendanceObject save];
        [relations addObject:attendanceObject];
    }
    [practiceObject saveEventually:^(BOOL succeeded, NSError *error) {
        NSLog(@"Added new practice at date %@ with %d attendees. success %d error %@", newPractice.practiceDate, [roster count], succeeded, error.description);
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

#pragma mark RosterView
-(IBAction)didClickViewMembers:(id)sender {
    RosterViewController * rosterViewController = [[RosterViewController alloc] init];
    [rosterViewController setDelegate:self];
    [rosterViewController setBCanAddNewMember:NO];
    
    [self.navigationController pushViewController:rosterViewController animated:YES];
}
-(void)rosterView:(RosterViewController *)rosterView didSelectMember:(Member *)member {
    NSLog(@"Selected member! should view accounting");
    [UIAlertView alertViewWithTitle:@"Edit member" message:[NSString stringWithFormat:@"Change info for member %@", member.name] cancelButtonTitle:@"Back" otherButtonTitles:[NSArray arrayWithObjects:@"Status", @"Month totals", nil] onDismiss:^(int buttonIndex) {
        
        editingMember = member;
        
        UIAlertView * alertView = [[UIAlertView alloc] init];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView addButtonWithTitle:@"Cancel"];
        [alertView addButtonWithTitle:@"OK"];
        [alertView setTag:buttonIndex];
        [alertView setDelegate:self];
        if (buttonIndex == 0) {
            // change status
            [alertView setTitle:[NSString stringWithFormat:@"Update status for %@ to:", member.name]];
            [alertView show];
        }
        else if (buttonIndex == 1) {
            // change monthly total
            [alertView setTitle:[NSString stringWithFormat:@"Update monthly paid for %@ to:", member.name]];
            [alertView show];
        }
    } onCancel:^{
        return;
    }];
}
-(void)rosterView:(RosterViewController*)rosterView getRosterWithBlock:(void(^)(NSArray *, NSError *))gotCurrentRoster {
    [self getRosterWithBlock:gotCurrentRoster];
}
-(void)closeRosterView:(RosterViewController *)rosterView {
    //[self dismissModalViewControllerAnimated:YES];
}

#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark PracticeView

-(IBAction)didClickViewPractices:(id)sender {
    PracticeViewController * practiceViewController = [[PracticeViewController alloc] init];
    [practiceViewController setDelegate:self];
    
    [self.navigationController pushViewController:practiceViewController animated:YES];
}

#pragma mark UIAlertViewDelegate - user roster
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString * str = [alertView textFieldAtIndex:0].text;
    
    if (alertView.tag == 0) {
        // updating status
        editingMember.status = str;
    }
    else if (alertView.tag == 1) {
        // updating monthly paid
        float payment = str.floatValue;
        editingMember.monthPaid = [NSNumber numberWithFloat:[editingMember.monthPaid floatValue] + payment];
    }
    [editingMember.pfObject saveEventually:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // todo: refresh roster
        }
    }];
}

@end
