//
//  OnsiteSignupViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class Practice;
@class RatingViewController;
@interface OnsiteSignupViewController : UIViewController <UITextFieldDelegate, MFMailComposeViewControllerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UITextField *inputName;
    IBOutlet UITextField *inputEmail;
    IBOutlet UITextField *inputAbout;
    
    IBOutlet UILabel *labelAttendanceCount;
    NSMutableArray *newAttendees;
    
    UITextField *currentInput;
    
    IBOutlet NSLayoutConstraint *constraintTopOffset;
    
    IBOutlet UILabel *labelWelcome;
    
    RatingViewController *rater;
    BOOL didShowRater;

    IBOutlet UIButton *buttonPhoto;
    UIImage *newPhoto;
}

@property (nonatomic) Practice *practice;

-(IBAction)didClickSignup:(id)sender;
- (IBAction)didClickAddPhoto:(id)sender;

@end
