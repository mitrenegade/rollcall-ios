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
    IBOutlet UIImageView *logo;

    IBOutlet UITextField *inputLogin;
    IBOutlet UITextField *inputPassword;
    IBOutlet UITextField *inputConfirmation;

    IBOutlet UIButton *buttonLogin;
    IBOutlet UIButton *buttonSignup;
    IBOutlet UIButton *buttonReset;

    NSMutableDictionary *ready;

    MBProgressHUD *progress;
    BOOL isFailed;

    IBOutlet TutorialScrollView *tutorialView;
}

-(IBAction)didClickLogin:(id)sender;
-(IBAction)didClickSignup:(id)sender;
-(IBAction)didClickPasswordReset:(id)sender;
-(void)reset:(BOOL)showLogin;
-(void)enableButtons:(BOOL)enabled;
@end

