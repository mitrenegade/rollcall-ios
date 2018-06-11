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
    [self setupSettingsNavButton];
    [self setupPlusNavButton];

    [self reloadPractices];

    [self listenFor:@"practice:info:updated" action:@selector(reloadPractices)];
    
    if ([[Organization current] shouldPromptForPowerUserFeedback]) {
        [self promptForPowerUserFeedback];
    }
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
    }
    else if ([segue.identifier isEqualToString:@"EventListToDetail"]) {
        // Edit practice details
        UINavigationController *nav = (UINavigationController *)segue.destinationViewController;
        PracticeEditViewController *controller = (PracticeEditViewController *)nav.viewControllers[0];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        FirebaseEvent *practice = [self practiceFor:indexPath.row];
        [controller setPractice:practice];
        [controller setDelegate:self];
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
