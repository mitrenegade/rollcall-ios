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
    NSMutableArray *members;
    NSArray *attendees;
}
@property (nonatomic, weak) Practice *practice;
@end
