//
//  PracticeDetailsViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 3/27/13.
//  Copyright (c) 2013 Bobby Ren. All rights reserved.
//

#import "PracticeDetailsViewController.h"

@interface PracticeDetailsViewController ()

@end

@implementation PracticeDetailsViewController

@synthesize practice, attendanceArray;
@synthesize membersDict;

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
    
    membersDict = [[NSMutableDictionary alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *date = [dateFormatter stringFromDate:practice.practiceDate];
    [self.labelDate setText:date];
    
    UIToolbar* keyboardDoneButtonView1 = [[UIToolbar alloc] init];
    keyboardDoneButtonView1.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView1.translucent = YES;
    keyboardDoneButtonView1.tintColor = nil;
    [keyboardDoneButtonView1 sizeToFit];
    UIBarButtonItem* doneButton1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                    style:UIBarButtonItemStyleBordered target:self
                                                                   action:@selector(didFinishEditingNotes)];
    [keyboardDoneButtonView1 setItems:[NSArray arrayWithObjects:doneButton1, nil]];
    [self.textViewNotes setInputAccessoryView:keyboardDoneButtonView1];
    [self.textViewNotes setText:practice.notes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didFinishEditingNotes {
    [self.textViewNotes resignFirstResponder];
    practice.notes = self.textViewNotes.text;
    [practice.pfObject setObject:practice.notes forKey:@"notes"];
    [practice.pfObject saveInBackground];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"Attendances at this practice: %d", [attendanceArray count]);
    return [attendanceArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    // Configure the cell...
    int row = indexPath.row;
    if (row >= [attendanceArray count])
        return nil;
    
    Attendance * attendance = [attendanceArray objectAtIndex:row];
    Member * member = [membersDict objectForKey:attendance.pfObject.objectId];
    if (!member) {
        [self getMemberForAttendance:attendance withBlock:^(NSArray * results) {
            // results is an array of member pfObjects, should only be one
            /*
            for (PFObject * obj in results) {
                Member * member = [[Member alloc] initWithPFObject:obj];
                cell.textLabel.text = member.name;
                [self.tableView reloadData];
            }
             */
            // reload this row
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
    
    cell.textLabel.text = member.name;
    if ([member.status isEqualToString:@"beginner"]) {
        cell.detailTextLabel.text = @"Beginner";
    }
    else if ([member.status isEqualToString:@"monthpaid"]) {
        cell.detailTextLabel.text = @"Paid in full";
    }
    else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Paid: %d Total: %d", [attendance.payment intValue], [member.monthPaid intValue]];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    if (row >= [attendanceArray count])
        return;
    
    Attendance * attendance = [attendanceArray objectAtIndex:row];
    Member * member = [membersDict objectForKey:attendance.pfObject.objectId];
    UIAlertView * alertView = [[UIAlertView alloc] init];
    [alertView setTitle:[NSString stringWithFormat:@"Update payment amount for %@ to:", member.name]];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];    
    [alertView addButtonWithTitle:@"OK"];
    [alertView setTag:row];
    [alertView setDelegate:self];
    [alertView show];
}

-(void)queryForAllPracticesWithBlock:(void (^)(NSArray *, NSError *))gotPractices {
    [ParseHelper queryForAllParseObjectsWithClass:@"Practice" withBlock:^(NSArray * results, NSError * error) {
        gotPractices(results, error);
    }];
}

-(void)getMemberForAttendance:(Attendance*)attendance withBlock:(void(^)(NSArray*))didGetMember{
    // get relations
    PFObject * pfObject = attendance.pfObject;
    PFRelation * relation = [pfObject relationforKey:@"forUser"];
    PFQuery *query = [relation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        // results is an array of a single member
        
        // tell cell to update count
        didGetMember(results);
        
        // create and populate attendanceDict
        for (PFObject * obj in results) {
            Member * member = [[Member alloc] initWithPFObject:obj];
            [membersDict setObject:member forKey:attendance.pfObject.objectId];
        }
    }];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString * str = [alertView textFieldAtIndex:0].text;
    NSLog(@"new value: %@ selected row: %d", str, alertView.tag);
    float payment = str.floatValue;
    int row = alertView.tag;
    
    Attendance * attendance = [attendanceArray objectAtIndex:row];
    [attendance setPayment:[NSNumber numberWithFloat:payment]];
    [attendance.pfObject setObject:attendance.payment forKey:@"payment"];
    [attendance.pfObject saveInBackground];
    
    Member * member = [membersDict objectForKey:attendance.pfObject.objectId];
    member.monthPaid = [NSNumber numberWithFloat:[member.monthPaid floatValue] + payment];
    [member.pfObject saveEventually];

    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
    [self.tableView reloadData];
}

@end
