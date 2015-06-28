//
//  PracticesTableViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticesTableViewController.h"
#import "Practice+Parse.h"
#import "Attendance+Parse.h"
#import "Util.h"
#import "AttendancesViewController.h"
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
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_white"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettings:)];
    self.navigationItem.leftBarButtonItem = left;

    [self reloadPractices];

    [self listenFor:@"practice:info:updated" action:@selector(reloadPractices)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadPractices {
    [self.practiceFetcher performFetch:nil];
    [self.tableView reloadData];
}

-(void)goToSettings:(id)sender {
    [self notify:@"goToSettings"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.practiceFetcher fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PracticeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Practice *practice = [self.practiceFetcher objectAtIndexPath:indexPath];
    cell.textLabel.text = practice.title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    cell.textLabel.textColor = [UIColor blackColor];

    cell.detailTextLabel.text = practice.details;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

-(NSFetchedResultsController *)practiceFetcher {
    if (_practiceFetcher) {
        return _practiceFetcher;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Practice"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];

    // todo: use months as section?
    _practiceFetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    NSError *error;
    [_practiceFetcher performFetch:&error];

    return _practiceFetcher;
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UINavigationController *nav = [segue destinationViewController];

    if ([segue.identifier isEqualToString:@"EventListToNewEvent"]) {
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
        if (indexPath.row < [self.practiceFetcher.fetchedObjects count])
            [controller setPractice:self.practiceFetcher.fetchedObjects[indexPath.row]];
        [controller setDelegate:self];
    }
}

#pragma mark PracticeEditDelegate
-(void)didEditPractice {
    [self reloadPractices];
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

-(void)deletePracticeAtIndexPath:(NSIndexPath *)indexPath {
    Practice *practice = [self.practiceFetcher objectAtIndexPath:indexPath];
    NSSet *attendances = practice.attendances;
    for (Attendance *at in attendances) {
        // manually cascade deletion on parse
        [at.pfObject deleteInBackgroundWithBlock:nil];
    }
    [practice.pfObject deleteInBackgroundWithBlock:nil];

    [_appDelegate.managedObjectContext deleteObject:practice];

    [self.practiceFetcher performFetch:nil];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    [self notify:@"practice:deleted"]; // no one listens for this now
}
@end
