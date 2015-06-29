//
//  PracticeEditViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "RatingViewController.h"

@protocol PracticeEditDelegate <NSObject>

-(void)didEditPractice;

@end

@class Practice;
@class RatingViewController;
@interface PracticeEditViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate, RatingDelegate>
{
    IBOutlet UITextField *inputDate;
    IBOutlet UITextField *inputDetails;

    NSMutableDictionary *dateForDateString;
    NSMutableArray *datesForPicker; // at most 14, but not before the user's creation date
    NSString *lastInputDate;
    NSString *originalDescription;
    
    IBOutlet UIView *viewInfo;
    IBOutlet UIButton *buttonEditAttendees;
    IBOutlet UIButton *buttonRollCall;

    IBOutlet UIView *viewEmail;
    IBOutlet UITextField *inputTo;
    IBOutlet UIButton *buttonEmail;

    IBOutlet UIView *viewDrawing;
    IBOutlet UIButton *buttonDrawing;

    NSMutableArray *drawn;

    NSString *emailFrom;
    NSString *emailTo;
    
    RatingViewController *rater;
    BOOL didShowRater;
}

@property (nonatomic) Practice *practice;
@property (nonatomic) id delegate;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickSave:(id)sender;
-(IBAction)didClickEmail:(id)sender;
-(IBAction)didClickDrawing:(id)sender;
-(IBAction)didClickAttendees:(id)sender;
@end
