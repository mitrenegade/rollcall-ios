//
//  OnsiteSignupViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Practice;
@interface OnsiteSignupViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *inputName;
    IBOutlet UITextField *inputEmail;
    IBOutlet UITextField *inputAbout;
    
    IBOutlet UILabel *labelAttendanceCount;
    NSMutableArray *newAttendees;
    
    UITextField *currentInput;
    
    IBOutlet NSLayoutConstraint *constraintTopOffset;
    
    IBOutlet UILabel *labelWelcome;
}

@property (nonatomic) Practice *practice;

-(IBAction)didClickSignup:(id)sender;

@end
