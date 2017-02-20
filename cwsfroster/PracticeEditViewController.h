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

#define FUTURE_DAYS 14

@protocol PracticeEditDelegate <NSObject>

-(void)didCreatePractice;
-(void)didEditPractice;

@end

@class Practice;
@class RatingViewController;
@interface PracticeEditViewController : UIViewController < UIPickerViewDelegate, UIPickerViewDataSource, RatingDelegate>
{
    IBOutlet UITextField *inputDate;
    IBOutlet UITextField *inputDetails;
    IBOutlet UITextView *inputNotes;

    NSMutableDictionary *dateForDateString;
    NSMutableArray *datesForPicker; // at most 14, but not before the user's creation date
    NSString *lastInputDate;
    NSString *originalDescription;
    
    IBOutlet UIView *viewInfo;

    IBOutlet UIButton *buttonDrawing;

    NSMutableArray *drawn;

    NSString *emailFrom;
    NSString *emailTo;
    
    RatingViewController *rater;
    BOOL didShowRater;
    
    int currentRow;
}

@property (nonatomic, assign) BOOL isNewPractice;
@property (nonatomic) NSMutableDictionary *dateForDateString;


@property (nonatomic) Practice *practice;
@property (nonatomic) id<PracticeEditDelegate> delegate;

@property (nonatomic) IBOutlet UILabel *labelTitle;
@property (nonatomic) IBOutlet UITextField *inputDate;
@property (nonatomic) IBOutlet UITextField *inputDetails;
@property (nonatomic) IBOutlet UITextView *inputNotes;

@property (nonatomic) IBOutlet UIButton *buttonAttendees;
@property (nonatomic) IBOutlet NSLayoutConstraint *constraintButtonAttendeesHeight;
@property (nonatomic) IBOutlet NSLayoutConstraint *constraintButtonEmailHeight;

@property (nonatomic) NSString *originalDescription;

@property (nonatomic) IBOutlet UIButton *buttonEmail;
@property (nonatomic) IBOutlet UIButton *buttonDrawing;

@property (assign) int currentRow;
@property (nonatomic) NSString *lastInputDate;
@property (nonatomic) NSString *emailTo;

@property (nonatomic) IBOutlet UIView *activityOverlay;

-(NSString *)titleForDate:(NSDate *)date;

-(IBAction)didClickAttendees:(id)sender;
@end
