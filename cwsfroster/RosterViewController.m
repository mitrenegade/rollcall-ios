//
//  RosterViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 10/1/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import "RosterViewController.h"

@interface RosterViewController ()

@end

@implementation RosterViewController

@synthesize delegate;
@synthesize rosterArray;
@synthesize bCanAddNewMember;

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
    rosterArray = nil;
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refresh {
    [delegate rosterView:self getRosterWithBlock:^(NSArray * ra, NSError * error) {
        if (error)
            NSLog(@"Error: %@", [error description]);
        else {
            NSLog(@"New roster array: %d members", [ra count]);
            [self setRosterArray:ra];
            [self.tableView reloadData];
        }
    }];
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
    if (bCanAddNewMember)
        return [rosterArray count] + 1;
    return [rosterArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (indexPath.row == [rosterArray count]) {
        // "Add an attendee"
        [cell.textLabel setText:@"Add an attendee"];
        [cell.textLabel setTextColor:[UIColor redColor]];
    }
    else {
        Member * member = [rosterArray objectAtIndex:indexPath.row];
        [cell.textLabel setText:member.name];
        [cell.textLabel setTextColor:[UIColor blackColor]];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"Status: %@ Paid in month: %d", member.status, [member.monthPaid intValue]]];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (!bCanAddNewMember) {
        // main member roster
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    return cell;
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
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (indexPath.row == [rosterArray count]) {
        [delegate rosterView:self addMemberWithBlock:^(BOOL success, Member * newMember) {
            if (success) {
                NSLog(@"Added member %@!", newMember.name);
                //[self refresh];
//                [self close];
            }
            else
                NSLog(@"Could not add member!");
        }];
    }
    else {
        if (indexPath.row > [rosterArray count])
            return;
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        Member * member = (Member*) [rosterArray objectAtIndex:indexPath.row];
        [delegate rosterView:self didSelectMember:member];
    }
}

// bar button
-(void)addSelected:(id)sender {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSMutableArray * selectedMember = [[NSMutableArray alloc] init];
    for (NSIndexPath *selectionIndex in selectedRows) {
        int row = selectionIndex.row;
        [selectedMember addObject:(Member*)[rosterArray objectAtIndex:row]];
    }
    NSLog(@"Adding %d selected members!", [selectedMember count]);
    [delegate didAddMultipleMembers:selectedMember];
}

@end
