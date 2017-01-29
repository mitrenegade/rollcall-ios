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
#import "Organization+Parse.h"

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
    
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_white"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettings:)];
    self.navigationItem.leftBarButtonItem = left;

    [self listenFor:@"payment:updated" action:@selector(reloadMembers)];
    [self reloadMembers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadMembers {
    [self.memberFetcher performFetch:nil];
    [self.tableView reloadData];
}

-(void)goToSettings:(id)sender {
    [self notify:@"goToSettings"];
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
            title = @"Guest";
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberCell" forIndexPath:indexPath];

    // Configure the cell...

    Member *member = [self.memberFetcher objectAtIndexPath:indexPath];
    UILabel *label = [cell viewWithTag:2];
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor darkGrayColor];
    label.text = member.name;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [self deleteMemberAtIndexPath:indexPath];
    }
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *nav = segue.destinationViewController;
    MemberViewController *controller = (MemberViewController *)(nav.topViewController);
    if ([segue.identifier isEqualToString:@"MembersToEditMember"]) {
        Member *member = [self.memberFetcher objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        [controller setDelegate:self];
        [controller setMember:member];
    }
    else if ([segue.identifier isEqualToString:@"MembersToAddMember"]) {
        [controller setDelegate:self];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark Delegate
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status photo:(UIImage *)newPhoto {
    Member *member = (Member *)[Member createEntityInContext:_appDelegate.managedObjectContext];
    member.organization = [Organization currentOrganization];
    [member updateEntityWithParams:@{@"name":name, @"status":@(status)}];
    if (newPhoto) {
        member.photo = UIImageJPEGRepresentation(newPhoto, 0.8);
    }
    [self notify:@"member:updated"];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    [PFAnalytics trackEvent:@"member created"];
}

-(void)updateMember:(Member *)member {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    
    [PFAnalytics trackEvent:@"member updated"];
}

-(void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)deleteMemberAtIndexPath:(NSIndexPath *)indexPath {
    Member *member = [self.memberFetcher objectAtIndexPath:indexPath];
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

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.memberFetcher performFetch:nil];
    [self notify:@"member:deleted"];
    
    [PFAnalytics trackEvent:@"member deleted"];
}
@end
