//
//  PracticesTableViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticesTableViewController.h"
#import "Util.h"
#import "SettingsViewController.h"

@interface PracticesTableViewController ()

@end

@implementation PracticesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"hamburger4-square"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    [button addTarget:self action:@selector(goToSettings:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = left;

    UIButton *rightbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightbutton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [rightbutton setFrame:CGRectMake(0, 0, 30, 30)];
    [rightbutton addTarget:self action:@selector(goToAddEvent:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:rightbutton];
    self.navigationItem.rightBarButtonItem = right;

    [self reloadPractices];

    [self listenFor:@"practice:info:updated" action:@selector(reloadPractices)];
    
    if ([[Organization current] shouldPromptForPowerUserFeedback]) {
        [self promptForPowerUserFeedback];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)goToSettings:(id)sender {
    [self notify:@"goToSettings"];
}

-(void)goToAddEvent:(id)sender {
    [self performSegueWithIdentifier:@"toNewEvent" sender:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[Organization current] practices] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PracticeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Practice *practice = [[Organization current] practices][indexPath.row];
    cell.textLabel.text = practice.title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    cell.textLabel.textColor = [UIColor blackColor];

    cell.detailTextLabel.text = practice.details;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [self deletePracticeAtIndexPath:indexPath];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"EventListToDetail" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"toNewEvent"]) {
        // create new practice
        UINavigationController *nav = (UINavigationController *)segue.destinationViewController;
        PracticeEditViewController *controller = (PracticeEditViewController *)nav.viewControllers[0];
        [controller setDelegate:self];
        controller.isNewPractice = YES;
    }
    else if ([segue.identifier isEqualToString:@"EventListToDetail"]) {
        // Edit practice details
        UINavigationController *nav = (UINavigationController *)segue.destinationViewController;
        PracticeEditViewController *controller = (PracticeEditViewController *)nav.viewControllers[0];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath.row < [[[Organization current] practices] count])
            [controller setPractice:[[Organization current] practices][indexPath.row]];
        [controller setDelegate:self];
        controller.isNewPractice = NO;
    }
}


/*
-(void)didEditPractice {
    self.title = self.practice.title;
    
    [self notify:@"practice:info:updated"];
    
    // update all attendances
    for (Attendance *attendance in self.practice.attendances) {
        attendance.date = self.practice.date;
        [attendance saveOrUpdateToParseWithCompletion:nil];
    }
}
 */

@end
