//
//  MembersTableViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "MembersTableViewController.h"

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
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"hamburger4-square"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    [button addTarget:self action:@selector(goToSettings:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = left;

    UIButton *rightbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightbutton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [rightbutton setFrame:CGRectMake(0, 0, 30, 30)];
    [rightbutton addTarget:self action:@selector(goToAddMember:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:rightbutton];
    self.navigationItem.rightBarButtonItem = right;

    [self listenFor:@"payment:updated" action:@selector(reloadMembers)];
    [self reloadMembers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadMembers {
    [self.tableView reloadData];
}

-(void)goToSettings:(id)sender {
    [self notify:@"goToSettings"];
}

-(void)goToAddMember:(id)sender {
    [self performSegueWithIdentifier:@"toAddMember" sender:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[Organization current] members] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberCell" forIndexPath:indexPath];
    
    // Configure the cell...

    Member *member = [[Organization current] members][indexPath.row];
    [cell configureWithMember: member row:indexPath.row];
    
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
    MemberInfoViewController *controller = (MemberInfoViewController *)(nav.topViewController);
    if ([segue.identifier isEqualToString:@"toEditMember"]) {
        Member *member = [[Organization current] members][[self.tableView indexPathForSelectedRow].row];
        [controller setDelegate:self];
        [controller setMember:member];
    }
    else if ([segue.identifier isEqualToString:@"toAddMember"]) {
        [controller setDelegate:self];
        [controller setMember: nil];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark Delegate
-(void)didUpdateMember:(Member *)member {
    [self reloadMembers];
    [self notify:@"member:updated"];
    [ParseLog logWithTypeString:@"MemberUpdated" title:[member objectId] message:nil params:nil error:nil];
}

-(void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)deleteMemberAtIndexPath:(NSIndexPath *)indexPath {
    Member *member = [[Organization current] members][indexPath.row];
    [member deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [Organization queryForMembersWithCompletion:^(NSArray<Member *> * _Nullable members, NSError * _Nullable error) {
                [self.tableView reloadData];
                [self notify:@"member:deleted"];
                [ParseLog logWithTypeString:@"MemberDeleted" title:[member objectId] message:nil params:nil error:nil];
            }];
        }
    }];
}
@end
