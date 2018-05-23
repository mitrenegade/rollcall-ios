//
//  IntroViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;
@class TutorialScrollView;

@interface IntroViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    IBOutlet UITextField *inputLogin;
    IBOutlet UITextField *inputPassword;
    IBOutlet UITextField *inputConfirmation;

    IBOutlet NSLayoutConstraint *constraintConfirmationHeight;
    
    NSMutableDictionary *ready;

    MBProgressHUD *progress;
    BOOL isFailed;

    IBOutlet TutorialScrollView *tutorialView;
}

@property (nonatomic) BOOL isSignup;
@property (weak, nonatomic) IBOutlet UIButton *buttonLoginSignup;
@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchMode;
@property (weak, nonatomic) IBOutlet UITextField *inputLogin;
@property (weak, nonatomic) IBOutlet UITextField *inputPassword;
@property (weak, nonatomic) IBOutlet UITextField *inputConfirmation;

-(void)refresh;
-(void)enableButtons:(BOOL)enabled;

-(void)loginToParse;
-(void)signup;
-(void)goToPracticesHelper;
@end

