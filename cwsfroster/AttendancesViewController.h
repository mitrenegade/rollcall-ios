//
//  AttendancesViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 7/23/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PracticeEditViewController.h"
#import "RatingViewController.h"

@class Practice;
@class RatingViewController;

@interface AttendancesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, RatingDelegate>
{
    NSMutableArray *attendances;
    NSMutableArray *membersActive;
    NSMutableArray *membersInactive;

    RatingViewController *rater;
    BOOL didShowRater;
}
@property (nonatomic, weak) Practice *practice;

- (IBAction)didTapAccessory:(id)sender event:(id)event;
@end
