//
//  AttendancesViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 7/23/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Practice;
@interface AttendancesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSFetchedResultsController *memberFetcher;
    NSFetchedResultsController *attendanceFetcher;
}
@property (nonatomic, weak) Practice *practice;

-(IBAction)didClickEdit:(id)sender;
@end
