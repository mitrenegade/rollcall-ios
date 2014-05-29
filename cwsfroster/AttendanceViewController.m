//
//  AttendanceViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 9/30/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import "AttendanceViewController.h"
#import "Practice.h"

@interface AttendanceViewController ()

@end

@implementation AttendanceViewController

@synthesize rosterController;
@synthesize attendanceController;
@synthesize delegate;
@synthesize currentAttendance, currentAttendanceIDs;
@synthesize addMemberCallback;
@synthesize inputNotes;

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
    
    // shows roster of current class
    attendanceController = [[RosterViewController alloc] init];
    [attendanceController setDelegate:self];
    [attendanceController setBCanAddNewMember:YES];
    CGRect frame = CGRectMake(0, self.inputNotes.frame.origin.y + 80, 320, self.view.frame.size.height - self.inputNotes.frame.origin.y + 80);
    [attendanceController.view setFrame:frame];
    [self.view addSubview:attendanceController.view];
    
    currentAttendance = [[NSMutableArray alloc] init];
    currentAttendanceIDs = [[NSMutableSet alloc] init];
    
    [datePicker setFrame:CGRectMake(0, 0, 320, 80)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark RosterDelegate 

-(void)rosterView:(RosterViewController*)rosterView getRosterWithBlock:(void(^)(NSArray *, NSError *))gotCurrentRoster {
    if (rosterView == rosterController)
        [delegate getRosterWithBlock:gotCurrentRoster]; // request full roster from delegate
    else if (rosterView == attendanceController) {
        gotCurrentRoster(currentAttendance, nil); // send over current delegate
    }
}

-(void)rosterView:(RosterViewController*)rosterView addMemberWithBlock:(void(^)(BOOL, Member*))didAddMember {
    // display full roster to select from
    rosterController = [[RosterViewController alloc] init];
    [rosterController setDelegate:self];
    [self.navigationController pushViewController:rosterController animated:YES];
    
    // add "add all" button
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Add selected" style:UIBarButtonItemStyleBordered target:rosterController action:@selector(addSelected:)];
    [rosterController.navigationItem setRightBarButtonItem:done];
    
    // store callback
    [self setAddMemberCallback:didAddMember];
}

-(void)rosterView:(RosterViewController*)rosterView didSelectMember:(Member *)member {
    /*
    if (rosterView == rosterController) {
        // selected a person to add to our attendance list
        [currentAttendance addObject:member];
        [attendanceController refresh];
        addMemberCallback(YES, member);
    }
    else if (rosterView == attendanceController) {
        // selected a person from current attendance list
        NSLog(@"Do nothing!");
    }
     */
    // do nothing - allow multiselect
}

-(void)didAddMultipleMembers:(NSMutableArray *)selectedMembers {
    for (Member * member in selectedMembers) {
        if ([currentAttendanceIDs containsObject:member.pfObject.objectId])
            continue;
        [currentAttendance addObject:member];
        [currentAttendanceIDs addObject:member.pfObject.objectId];
    }
    [self.navigationController popViewControllerAnimated:YES];
    [self.attendanceController refresh];
}

#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

/*
-(void)closeRosterView:(RosterViewController *)rosterView {
    if (rosterController) { //rosterView == rosterController) {
        [self.navigationController popViewControllerAnimated:YES];
        rosterController = nil;
    }
}*/

-(void)save:(id)sender {
    NSDate * date = datePicker.date;
    NSLog(@"Saving practice on %@ with %d members!", date, [currentAttendance count]);
    
    [delegate didSaveWithDate:date andNotes:self.inputNotes.text andRoster:currentAttendance];
}
@end
