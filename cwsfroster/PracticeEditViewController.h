//
//  PracticeEditViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

#define FUTURE_DAYS 14

@protocol PracticeEditDelegate <NSObject>

-(void)didCreatePractice;
-(void)didEditPractice;

@end

@class FirebaseEvent;
@interface PracticeEditViewController : UIViewController < UIPickerViewDelegate, UIPickerViewDataSource>
{
}

@property (nonatomic) NSMutableDictionary *dateForDateString;


@property (nonatomic) FirebaseEvent *practice;
@property (nonatomic) NSDictionary *createPracticeInfo;
@property (nonatomic) id<PracticeEditDelegate> delegate;

@property (nonatomic) IBOutlet UILabel *labelTitle;
@property (nonatomic) IBOutlet UITextField *inputDate;
@property (nonatomic) IBOutlet UITextField *inputDetails;
@property (nonatomic) IBOutlet UITextView *inputNotes;

@property (nonatomic) IBOutlet UIButton *buttonAttendees;
@property (nonatomic) IBOutlet NSLayoutConstraint *constraintButtonAttendeesHeight;
@property (nonatomic) IBOutlet NSLayoutConstraint *constraintButtonEmailHeight;

@property (nonatomic) NSString *originalDescription;

@property (nonatomic) IBOutlet UIView *viewEmail;
@property (nonatomic) IBOutlet UITextField *inputTo;
@property (nonatomic) IBOutlet UIButton *buttonEmail;
@property (nonatomic) IBOutlet UIButton *buttonDrawing;

@property (assign) int currentRow;
@property (nonatomic) NSString *lastInputDate;
@property (nonatomic) NSString *emailFrom;
@property (nonatomic) NSString *emailTo;

@property (nonatomic) IBOutlet UIView *activityOverlay;

@property (nonatomic) NSMutableArray *datesForPicker; // at most 14, but not before the user's creation date
    
@property (nonatomic) IBOutlet UIView *viewInfo;
    
@property (nonatomic) NSMutableArray *drawn;
    
-(NSString *)titleForDate:(NSDate *)date;
-(void)generatePickerDates;

@end
