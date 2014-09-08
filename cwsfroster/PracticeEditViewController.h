//
//  PracticeEditViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PracticeEditDelegate <NSObject>

-(void)didEditPractice;

@end

@class Practice;
@interface PracticeEditViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UITextField *inputDate;
    IBOutlet UITextField *inputDetails;

    NSMutableDictionary *dateForDateString;
    NSMutableArray *datesForPicker; // at most 14, but not before the user's creation date
    NSString *lastInputDate;
    NSString *originalDescription;

    IBOutlet UIView *viewEmail;
    IBOutlet UITextField *inputTo;
    IBOutlet UITextField *inputFrom;
    IBOutlet UIButton *buttonEmail;

    IBOutlet UIView *viewDrawing;
    IBOutlet UIButton *buttonDrawing;

    NSMutableArray *drawn;
}

@property (nonatomic) Practice *practice;
@property (nonatomic) id delegate;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickSave:(id)sender;
-(IBAction)didClickEmail:(id)sender;
-(IBAction)didClickDrawing:(id)sender;
@end
