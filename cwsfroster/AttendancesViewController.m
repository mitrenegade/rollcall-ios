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

    rater = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RatingViewController"];
    rater.delegate = self;
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
    if (!didShowRater) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        if (![rater showRatingsIfConditionsMetFromView:self.view forced:NO]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        didShowRater = YES;
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)didCloseRating {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
#pragma mark - Table view data source
-(void)reloadData {
    membersActive = [[[[Member where:@{}] not:@{@"status":@(MemberStatusInactive)}] all] mutableCopy];
    membersInactive = [[[Member where:@{@"status":@(MemberStatusInactive)}] all] mutableCopy];
    attendances = [[[[Attendance where:@{@"practice.parseID": self.practice.parseID}] not:@{@"attended":@(AttendedStatusNone)}] all] mutableCopy];
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
    NSNumber *status = @(AttendedStatusPresent); // attended by default
    if ([member isBeginner]) {
        status = @(AttendedStatusFreebie);
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
        return @"Attendees of event";
    }
    else if (section == 1) {
        return @"Active members not at event";
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
        if (attendances.count > 0) {
            return attendances.count;
        }
        return 1;
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
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    UILabel *label = [cell viewWithTag:2];

    NSString *name;
    if (section == 0) {
        if (attendances.count == 0) {
            name = @"Click a row to add a member";
            
            label.alpha = 0.5;
        }
        else {
            label.alpha = 1;
            
            Attendance *attendance = attendances[row];
            name = attendance.member.name;
        }
    }
    else if (section == 1) {
        Member *member = membersActive[row];
        name = member.name;
    }
    else if (section == 2) {
        Member *member = membersInactive[row];
        name = member.name;
    }
    label.text = name;
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor darkGrayColor];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    if (section == 0) {
        if (attendances.count == 0) {
            return;
        }
        // clicked on an attendance
        Attendance *attendance = attendances[row];
        attendance.attended = @(AttendedStatusNone);
        NSLog(@"old payment: %@", attendance.payment);
        [attendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
            NSLog(@"new payment: %@", attendance.payment);
            [self reloadData];
        }];
        
        [ParseLog logWithTypeString:@"AttendanceRemoved" title:nil message:nil params:nil error:nil];
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
            NSNumber *status = @(AttendedStatusPresent); // attended by default
            if ([attendance.member isBeginner]) {
                status = @(AttendedStatusFreebie);
            }
            attendance.attended = status;
            [attendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
                NSLog(@"new payment: %@", attendance.payment);
                [self reloadData];
            }];
        }
        else {
            // create attendance
            [self saveNewAttendanceForMember:member completion:^(BOOL success, Attendance *attendance) {
                [self reloadData];
            }];
        }
        
        [ParseLog logWithTypeString:@"AttendanceAdded" title:nil message:nil params:nil error:nil];
    }
    [self reloadData];
}


@end
