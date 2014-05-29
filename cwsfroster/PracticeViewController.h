//
//  PracticeViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 3/27/13.
//  Copyright (c) 2013 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParseHelper.h"
#import <Parse/Parse.h>
#import "Practice.h"
#import "Attendance.h"
#import "Member.h"
#import "PracticeDetailsViewController.h"

#define TAG_TITLE 1001
#define TAG_SUBTITLE 1002

@protocol PracticeViewDelegate <NSObject>

@end

@interface PracticeViewController : UITableViewController <UINavigationControllerDelegate>

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSMutableArray * practiceArray;
@property (nonatomic, strong) NSMutableDictionary * attendancesDict;

@end
