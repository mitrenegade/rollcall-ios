//
//  AttendancesViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 7/23/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "AttendancesViewController.h"
#import "Practice+Parse.h"
#import "Util.h"
#import "Member+Parse.h"
#import "Attendance+Parse.h"
#import "Member+Info.h"
#import "Attendance+Info.h"
#import "PracticeEditViewController.h"
#import "Payment+Info.h"

@interface AttendancesViewController ()

@end

@implementation AttendancesViewController

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
    // Do any additional setup after loading the view.

    self.title = self.practice.title;
    if (!self.practice.pfObject) {
        [self.practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
        }];
    }

    membersActive = [NSMutableArray array];
    membersInactive = [NSMutableArray array];
    attendances = [NSMutableArray array];

    [self reloadData];

    [self listenFor:@"member:deleted" action:@selector(reloadData)];
    [self listenFor:@"member:updated" action:@selector(reloadData)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    [self stopListeningFor:@"member:deleted"];
    [self stopListeningFor:@"member:updated"];
}

-(IBAction)didClickEdit:(id)sender {
    NSLog(@"Edit");
}

#pragma mark - Navigation
-(IBAction)didClickClose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"AttendanceToEditPractice"]) {
        PracticeEditViewController *controller = (PracticeEditViewController *)[segue destinationViewController];
        [controller setPractice:self.practice];
        [controller setDelegate:self];
    }
}
#pragma mark - Table view data source
-(void)reloadData {
    membersActive = [[[[Member where:@{}] not:@{@"status":@(MemberStatusInactive)}] all] mutableCopy];
    membersInactive = [[[Member where:@{@"status":@(MemberStatusInactive)}] all] mutableCopy];
    attendances = [[[[Attendance where:@{@"practice.parseID": self.practice.parseID}] not:@{@"attended":@(DidNotAttend)}] all] mutableCopy];
    for (Attendance *attendance in attendances) {
        Member *member = attendance.member;
        [membersActive removeObject:member];
        [membersInactive removeObject:member];
    }

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    membersActive = [[membersActive sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    membersInactive = [[membersInactive sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"member.name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    attendances = [[attendances sortedArrayUsingDescriptors:@[sortDescriptor2]] mutableCopy];

    [self.tableView reloadData];
}

-(void)saveNewAttendanceForMember:(Member *)member completion:(void(^)(BOOL success, Attendance *attendance))completion{
    NSLog(@"Need to create an attendance for member %@", member.name);
    Attendance *newAttendance = (Attendance *)[Attendance createEntityInContext:_appDelegate.managedObjectContext];
    newAttendance.organization = [Organization currentOrganization];
    newAttendance.practice = self.practice;
    newAttendance.member = member;
    NSNumber *status = @(DidAttend); // attended by default
    if ([member isBeginner]) {
        status = @(DidAttendFreebie);
    }
    [newAttendance updateEntityWithParams:@{@"date":self.practice.date, @"attended":status}];
    [self reloadData];
    [newAttendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            [_appDelegate.managedObjectContext save:nil];
            if (completion)
                completion(YES, newAttendance);
        }
        else {
            NSLog(@"Could not save member!");
            if (completion)
                completion(NO, nil);
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // first section is all attendees (attendance status = attended)
    // second section is all active members (member status = active or beginner, no attendance or attendance status = not attended)
    // third section is all inactive members (member status = inactive, no atendance or attendance status = not attended)

    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Attendees";
    }
    else if (section == 1) {
        return @"Active members";
    }
    else if (section == 2) {
        return @"Inactive members";
    }
    return @"Other";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return attendances.count;
    }
    else if (section == 1) {
        return membersActive.count;
    }
    else if (section == 2) {
        return membersInactive.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttendanceCell" forIndexPath:indexPath];

    // Configure the cell...
    int section = indexPath.section;
    int row = indexPath.row;

    UILabel *statusView = (UILabel *)[cell viewWithTag:1];
    statusView.layer.borderWidth = 2;
    statusView.layer.cornerRadius = 5;
    
    NSString *name;
    if (section == 0) {
        Attendance *attendance = attendances[row];
        name = attendance.member.name;

        if (attendance.payment) {
            statusView.layer.borderColor = [[UIColor greenColor] CGColor];
            statusView.text = @"Paid";
        }
        else if ([attendance isFreebie]) {
            statusView.layer.borderColor = [[UIColor yellowColor] CGColor];
            statusView.text = @"Trial";
        }
        else {
            statusView.layer.borderColor = [[UIColor redColor] CGColor];
            statusView.text = @"!";
        }
    }
    else if (section == 1) {
        Member *member = membersActive[row];
        name = member.name;

        statusView.layer.borderColor = [[member colorForStatusForMonth:self.practice.date] CGColor];
        statusView.text = [member textForStatusForMonth:self.practice.date];
    }
    else if (section == 2) {
        Member *member = membersInactive[row];
        name = member.name;

        statusView.layer.borderColor = [[member colorForStatusForMonth:self.practice.date] CGColor];
        statusView.text = [member textForStatusForMonth:self.practice.date];
    }
    cell.accessoryView = statusView.superview;
    cell.textLabel.text = name;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = indexPath.section;
    int row = indexPath.row;

    if (section == 0) {
        // clicked on an attendance
        Attendance *attendance = attendances[row];
        attendance.attended = @(DidNotAttend);
        NSLog(@"old payment: %@", attendance.payment);
        [attendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
            NSLog(@"new payment: %@", attendance.payment);
            [self reloadData];
        }];
    }
    else {
        Member *member;
        if (section == 1) {
            member = membersActive[row];
        }
        else {
            member = membersInactive[row];
        }

        // if member has an attendance that is not attended
        NSArray *at = [[Attendance where:@{@"member.parseID":member.parseID, @"practice.parseID":self.practice.parseID}] all];
        if (at.count) {
            Attendance *attendance = at[0];
            NSNumber *status = @(DidAttend); // attended by default
            if ([attendance.member isBeginner]) {
                status = @(DidAttendFreebie);
            }
            attendance.attended = status;
            [attendance saveOrUpdateToParseWithCompletion:nil];
        }
        else {
            // create attendance
            [self saveNewAttendanceForMember:member completion:^(BOOL success, Attendance *attendance) {
                [self reloadData];
            }];
        }
    }
    [self reloadData];
}

- (IBAction)didTapAccessory:(id)sender event:(id)event{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil){
        NSString *message;
        if (indexPath.section == 0) {
            // clicked on an attendance
            Attendance *attendance = attendances[indexPath.row];
            Payment *payment = attendance.payment;
            if (payment) {
                if ([payment isMonthly])
                    message = @"is paid for the month";
                else
                    message = @"paid for a day pass";
            }
            else if ([attendance isFreebie]) {
                message = @"has a free pass for the day";
            }
            else {
                message = @"needs to pay for this attendance";
            }
            message = [NSString stringWithFormat:@"%@ %@", attendance.member.name, message];
        }
        else {
            Member *member;
            if (indexPath.section == 1) {
                member = membersActive[indexPath.row];
                Payment *payment = [member paymentForMonth:self.practice.date];
                if (payment)
                    message = @"is paid for the month";
                else if ([member.currentDailyPayment daysLeft])
                    message = [NSString stringWithFormat:@"has %d days left on a day pass", [member.currentDailyPayment daysLeft]];
                else if ([member isBeginner])
                    message = @"gets freebie attendances";
                else
                    message = @"has not paid for the month";
            }
            else {
                member = membersInactive[indexPath.row];
                message = @"is inactive for the month";
            }
            message = [NSString stringWithFormat:@"%@ %@", member.name, message];
        }
        if (message) {
            [UIAlertView alertViewWithTitle:nil message:message];
        }
    }
}

#pragma mark PracticeEditDelegate
-(void)didEditPractice {
    self.title = self.practice.title;

    [self notify:@"practice:info:updated"];

    // update all attendances
    for (Attendance *attendance in self.practice.attendances) {
        attendance.date = self.practice.date;
        [attendance saveOrUpdateToParseWithCompletion:nil];
    }
}

@end
