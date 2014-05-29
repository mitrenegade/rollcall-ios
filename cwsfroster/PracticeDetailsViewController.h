//
//  PracticeDetailsViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 3/27/13.
//  Copyright (c) 2013 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ParseHelper.h"
#import "Attendance.h"
#import "Member.h"
#import "Practice.h"

@interface PracticeDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel * labelDate;
@property (nonatomic, weak) IBOutlet UITextView * textViewNotes;
@property (nonatomic, weak) IBOutlet UITableView * tableView;

@property (nonatomic, strong) Practice * practice;
@property (nonatomic, strong) NSMutableArray * attendanceArray;
@property (nonatomic, strong) NSMutableDictionary * membersDict;
@end
