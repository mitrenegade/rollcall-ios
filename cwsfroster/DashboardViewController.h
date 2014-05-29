//
//  DashboardViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 9/30/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AttendanceViewController.h"
#import "RosterViewController.h"
#import "Practice.h"
#import "Attendance.h"
#import "PracticeViewController.h"

@interface DashboardViewController : UIViewController <UINavigationControllerDelegate, AttendanceViewDelegate, RosterViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
    IBOutlet UIButton * buttonNewPractice;
    IBOutlet UIButton * buttonNewMember;
    IBOutlet UITextField * inputName;
    IBOutlet UITextField * inputEmail;
    Member * editingMember;
}

@property (nonatomic, strong) NSMutableArray * members;
@property (nonatomic, strong) NSMutableSet * memberIDs;

-(IBAction)newPractice:(id)sender;
-(IBAction)newMember:(id)sender;
-(IBAction)newMonth:(id)sender;

-(IBAction)didClickViewMembers:(id)sender;
-(IBAction)didClickViewPractices:(id)sender;
@end
