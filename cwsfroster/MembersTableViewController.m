//
//  MembersTableViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "MembersTableViewController.h"
#import "Member+Parse.h"
#import "Member+Info.h"
#import "Attendance+Parse.h"
#import "Payment+Parse.h"

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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:@[sortDescriptor, sortDescriptor2]];

    //    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %d", @"status", MemberStatusInactive];
    //    [request setPredicate:predicate];

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
        case MemberStatusBeginner:
            title = @"Beginner";
            break;
        case MemberStatusActive:
            title = @"Active";
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
    Member *member = [self.memberFetcher objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"MembersToAddMember" sender:member];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        Member *member = [self.memberFetcher objectAtIndexPath:indexPath];
        [self deleteMember:member];
    }
}

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
    [self performSegueWithIdentifier:@"MembersToAddMember" sender:self.navigationItem.rightBarButtonItem];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MembersToAddMember"]) {
        MemberViewController *controller = (MemberViewController *)segue.destinationViewController;
        [controller setDelegate:self];

        if ([sender isKindOfClass:[Member class]]) {
            [controller setMember:sender];
        }
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark Delegate
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status {
    Member *member = (Member *)[Member createEntityInContext:_appDelegate.managedObjectContext];
    [member updateEntityWithParams:@{@"name":name, @"status":@(status)}];
    [self notify:@"member:updated"];

    [self.navigationController popViewControllerAnimated:YES];
    [self reloadMembers];

    [member saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {

            NSError *error;
            if ([_appDelegate.managedObjectContext save:&error]) {
                [self reloadMembers];
            }
        }
        else {
            NSLog(@"Could not save member!");
            [UIAlertView alertViewWithTitle:@"Save error" message:@"Your last member edit was not saved"];
        }
    }];
}

-(void)updateMember:(Member *)member {
    [self.navigationController popViewControllerAnimated:YES];
    [member saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {

            NSError *error;
            if ([_appDelegate.managedObjectContext save:&error]) {
                [self reloadMembers];
                [self notify:@"member:updated"];
            }
        }
        else {
            NSLog(@"Could not update member!");
        }
    }];
}

-(void)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)deleteMember:(Member *)member {
    NSSet *attendances = member.attendances;
    NSSet *payments = member.payments;
    for (Attendance *at in attendances) {
        // manually cascade deletion on parse
        [at.pfObject deleteInBackgroundWithBlock:nil];
    }
    for (Payment *p in payments) {
        [p.pfObject deleteInBackgroundWithBlock:nil];
    }
    [member.pfObject deleteInBackgroundWithBlock:nil];
    [_appDelegate.managedObjectContext deleteObject:member];

    [self reloadMembers];
    [self notify:@"member:deleted"];
}
@end
