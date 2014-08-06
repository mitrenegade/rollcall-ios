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
#pragma mark - Table view data source
-(void)reloadMembers {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    attendees = [self.practice.attendances sortedArrayUsingDescriptors:@[descriptor]];
    members = [[[Member where:@{}] all] mutableCopy];
    for (Attendance *a in attendees) {
        Member *m = a.member;
        if ([members containsObject:m])
            [members removeObject:m];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"All members";
    }
    return @"Attendees";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        // all members not in this practice
        return [members count];
    }
    else if (section == 1) {
        return [attendees count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttendanceCell" forIndexPath:indexPath];

    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    Member *member;
    if (section == 0) { // not at practice
        member = members[row];
    }
    else if (section == 1) { // current at practice
        Attendance *attendance = attendees[row];
        member = attendance.member;
    }
    cell.textLabel.text = member.name;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"PracticesTableToAttendances" sender:self];
}

@end
