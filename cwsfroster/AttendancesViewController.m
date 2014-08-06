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
    [self reloadMembers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(NSFetchedResultsController *)memberFetcher {
    if (memberFetcher) {
        return memberFetcher;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Member"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %d", @"status", MemberStatusInactive];
    [request setSortDescriptors:@[sortDescriptor, sortDescriptor2]];
    [request setPredicate:predicate];

    memberFetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    NSError *error;
    [memberFetcher performFetch:&error];

    return memberFetcher;
}

-(NSFetchedResultsController *)attendanceFetcher {
    if (attendanceFetcher) {
        return attendanceFetcher;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Attendance"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"practice.parseID = %@", self.practice.parseID]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"attended" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor, sortDescriptor2]];
    attendanceFetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_appDelegate.managedObjectContext sectionNameKeyPath:@"attended" cacheName:nil];
    NSError *error;
    [attendanceFetcher performFetch:&error];

    return attendanceFetcher;
}

#pragma mark - Table view data source
-(void)reloadMembers {
#if 0
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    attendees = [self.practice.attendances sortedArrayUsingDescriptors:@[descriptor]];
    members = [[[Member where:@{}] all] mutableCopy];
    for (Attendance *a in attendees) {
        Member *m = a.member;
        if ([members containsObject:m])
            [members removeObject:m];
    }
#else
    NSError *error;
    [self.memberFetcher performFetch:&error];
    [self.attendanceFetcher performFetch:&error];

    // make sure each member has a practice
    BOOL needsReload = NO;
    for (Member *member in self.memberFetcher.fetchedObjects) {
        BOOL attendanceFound = NO;
        for (Attendance *attendance in self.attendanceFetcher.fetchedObjects) {
            if (![member.attendances containsObject:attendance]) {
                NSLog(@"Member %@ does not belong to attendance (%@ %@)", member.name, attendance.name, attendance.date);
            }
            else {
                NSLog(@"Member %@ is has an attendance for %@; attended %@", member.name, attendance.practice.title, attendance.attended);
                attendanceFound = YES;
                break;
            }
        }
        if (!attendanceFound) {
            // attendance does not exist
            [self saveNewAttendanceForMember:member];
            needsReload = YES;
            attendanceFound = YES;
        }
    }

    if (needsReload) {
        [self reloadMembers];
    }
    else {
        [self.tableView reloadData];
    }
#endif
}

-(void)saveNewAttendanceForMember:(Member *)member {
    NSLog(@"Need to create an attendance for member %@", member.name);
    Attendance *newAttendance = (Attendance *)[Attendance createEntityInContext:_appDelegate.managedObjectContext];
    newAttendance.practice = self.practice;
    newAttendance.member = member;
    [newAttendance updateEntityWithParams:@{@"name":member.name, @"date":self.practice.date, @"attended":@NO}];
    [newAttendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            NSError *error;
            [_appDelegate.managedObjectContext save:&error];
        }
        else {
            NSLog(@"Could not save member!");
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.attendanceFetcher sections] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSNumber *sectionTitle = self.attendanceFetcher.sectionIndexTitles[section];
    if ([sectionTitle intValue] == 0)
        return @"All members";
    else if ([sectionTitle intValue] == 1)
        return @"Attendees";
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        // all members not in this practice
//        return [members count];
    }
    else if (section == 1) {
//        return [attendees count];
    }
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.attendanceFetcher.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttendanceCell" forIndexPath:indexPath];

    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    Member *member;
    if (section == 0) { // not at practice
//        member = members[row];
    }
    else if (section == 1) { // current at practice
//        Attendance *attendance = attendees[row];
//        member = attendance.member;
    }
    member = ((Attendance*)[self.attendanceFetcher objectAtIndexPath:indexPath]).member;
    cell.textLabel.text = member.name;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    Attendance *attendance = [self.attendanceFetcher objectAtIndexPath:indexPath];
    if (section == 0) {
        // selecting a member
        attendance.attended = @YES;
    }
    else if (section == 1) {
        attendance.attended = @NO;
    }
    [attendance saveOrUpdateToParseWithCompletion:nil];
    [self refresh];
}

-(void)refresh {
    NSError *error;
    [self.attendanceFetcher performFetch:&error];
    [self.tableView reloadData];
}

@end
