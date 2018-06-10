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
@interface OnsiteSignupViewController : UIViewController <UITextFieldDelegate, MFMailComposeViewControllerDelegate>
{
}

@property (nonatomic) FirebaseEvent *practice;

    @property (nonatomic) IBOutlet UITextField *inputName;
    @property (nonatomic) IBOutlet UITextField *inputEmail;
    @property (nonatomic) IBOutlet UITextField *inputAbout;
    
    @property (nonatomic) IBOutlet UILabel *labelAttendanceCount;
    
    @property (nonatomic) UITextField *currentInput;
    
    @property (nonatomic) IBOutlet NSLayoutConstraint *constraintTopOffset;
    
    @property (nonatomic) IBOutlet UILabel *labelWelcome;
    
    @property (nonatomic) RatingViewController *rater;
    @property (nonatomic) BOOL didShowRater;
    
    @property (nonatomic) IBOutlet UIButton *buttonPhoto;
    @property (nonatomic) UIImage *addedPhoto;
    @property (nonatomic) NSMutableArray *addedAttendees;
    
    @property (nonatomic) IBOutlet UIButton *buttonSave;

@end
