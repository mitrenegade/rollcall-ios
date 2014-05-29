//
//  PracticeViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 3/27/13.
//  Copyright (c) 2013 Bobby Ren. All rights reserved.
//

#import "PracticeViewController.h"

@interface PracticeViewController ()

@end

@implementation PracticeViewController

@synthesize practiceArray;
@synthesize delegate;
@synthesize attendancesDict;

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
    
    practiceArray = [[NSMutableArray alloc] init];
    attendancesDict = [[NSMutableDictionary alloc] init];
    [self queryForAllPracticesWithBlock:^(NSArray * results, NSError * error) {
        if (error)
            NSLog(@"Error! %@", [error description]);
        else {
            for (PFObject * obj in results) {
                Practice * practice = [[Practice alloc] initWithPFObject:obj];
                [practiceArray addObject:practice];
            }
            NSLog(@"Loaded %d practices from Parse", [practiceArray count]);
            [self.tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return [practiceArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 30)];
        UILabel * subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 25, 300, 15)];
        [titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
        [subtitleLabel setFont:[UIFont systemFontOfSize:12]];
        [titleLabel setTag:TAG_TITLE];
        [subtitleLabel setTag:TAG_SUBTITLE];
        
        [cell.contentView addSubview:titleLabel];
        [cell.contentView addSubview:subtitleLabel];
    }
    
    // Configure the cell...
    int row = indexPath.row;
    if (row >= [practiceArray count])
        return nil;
    
    Practice * practice = [practiceArray objectAtIndex:row];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *date = [dateFormatter stringFromDate:practice.practiceDate];
    
    NSString * __block title = date;
    if ([attendancesDict objectForKey:practice.pfObject.objectId]) {
        NSMutableArray * attendances = [attendancesDict objectForKey:practice.pfObject.objectId];
        title = [NSString stringWithFormat:@"%@ - %d people", date, [attendances count]];
    }
    else {
        [self getAttendancesForPractice:practice withBlock:^(NSArray * results)  {
            title = [NSString stringWithFormat:@"%@ - %d people", date, [results count]];
            UILabel * titleLabel = (UILabel*)[cell.contentView viewWithTag:TAG_TITLE];
            titleLabel.text = title;
        }];
    }
    
    UILabel * titleLabel = (UILabel*)[cell.contentView viewWithTag:TAG_TITLE];
    UILabel * subtitleLabel = (UILabel*)[cell.contentView viewWithTag:TAG_SUBTITLE];
    titleLabel.text = title;
    subtitleLabel.text = practice.notes;
    
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
    int row = indexPath.row;
    if (row >= [practiceArray count])
        return;
    
    Practice * practice = [practiceArray objectAtIndex:row];
    NSMutableArray * attendanceArray = [attendancesDict objectForKey:practice.pfObject.objectId];
    
    PracticeDetailsViewController * detailsController = [[PracticeDetailsViewController alloc] init];
    [detailsController setPractice:practice];
    [detailsController setAttendanceArray:attendanceArray];
    
    if (!attendanceArray) {
        [self getAttendancesForPractice:practice withBlock:^(NSArray * attendances) {
            NSMutableArray * attendancesArray = [NSMutableArray arrayWithArray:attendances];
            [attendancesDict setObject:attendancesArray forKey:practice.pfObject.objectId];
            [detailsController setAttendanceArray:attendancesArray];
            [detailsController.tableView reloadData];
        }];
    }

    [self.navigationController pushViewController:detailsController animated:YES];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

-(void)queryForAllPracticesWithBlock:(void (^)(NSArray *, NSError *))gotPractices {
    [ParseHelper queryForAllParseObjectsWithClass:@"Practice" withBlock:^(NSArray * results, NSError * error) {
        gotPractices(results, error);
    }];
}

-(void)getAttendancesForPractice:(Practice*)practice withBlock:(void(^)(NSArray*))didGetAttendances{
    // get relations
    PFObject * practiceObject = practice.pfObject;
    PFRelation * relation = [practiceObject relationforKey:@"attendedBy"];
    PFQuery *query = [relation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        // results are a list of attendances for this practice
        
        // tell cell to update count
        didGetAttendances(results);
        
        // create and populate attendanceDict
        NSMutableArray * attendances = [[NSMutableArray alloc] init];
        for (PFObject * obj in results) {
            Attendance * attendance = [[Attendance alloc] initWithPFObject:obj];
            [attendances addObject:attendance];
        }
        [attendancesDict setObject:attendances forKey:practice.pfObject.objectId];
    }];
}

@end
