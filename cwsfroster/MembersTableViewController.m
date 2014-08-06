//
//  MembersTableViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "MembersTableViewController.h"
#import "AddMemberViewController.h"
#import "Member+Parse.h"
#import "Member+Info.h"

@interface MembersTableViewController ()

@end

@implementation MembersTableViewController

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
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    [self reloadMembers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadMembers {
    NSError *error;
    [self.memberFetcher performFetch:&error];
    [self.tableView reloadData];
}

#pragma mark FetchedResultsController
-(NSFetchedResultsController *)memberFetcher {
    if (memberFetcher) {
        return memberFetcher;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Member"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %d", @"status", MemberStatusInactive];
    [request setSortDescriptors:@[sortDescriptor, sortDescriptor2]];
    [request setPredicate:predicate];

    memberFetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_appDelegate.managedObjectContext sectionNameKeyPath:@"status" cacheName:nil];
    NSError *error;
    [memberFetcher performFetch:&error];

    return memberFetcher;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.memberFetcher sections] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSNumber *sectionTitle = self.memberFetcher.sectionIndexTitles[section];
    NSString *title = @"";
    switch ([sectionTitle intValue]) {
        case MemberStatusInactive:
            title = @"Inactive";
            break;
        case MemberStatusUnpaid:
            title = @"Unpaid";
            break;
        case MemberStatusPaid:
            title = @"Active";
            break;
        case MemberStatusBeginner:
            title = @"Beginner";
            break;
        case MemberStatusDaily:
            title = @"Daily Pass";
            break;

        default:
            break;
    }
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.memberFetcher.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    // Configure the cell...

    Member *member = [self.memberFetcher objectAtIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.textLabel.text = member.name;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

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
-(IBAction)didClickNew:(id)sender {
    [self performSegueWithIdentifier:@"addNewMemberSegue" sender:self];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"addNewMemberSegue"]) {
        AddMemberViewController *controller = (AddMemberViewController *)segue.destinationViewController;
        [controller setDelegate:self];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark Delegate
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status {
    Member *member = (Member *)[Member createEntityInContext:_appDelegate.managedObjectContext];
    [member updateEntityWithParams:@{@"name":name, @"status":@(status)}];
    [member saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            [self.navigationController popViewControllerAnimated:YES];

            NSError *error;
            if ([_appDelegate.managedObjectContext save:&error]) {
                [self reloadMembers];
                [self.tableView reloadData];
            }
        }
        else {
            NSLog(@"Could not save member!");
        }
    }];
}

-(void)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
