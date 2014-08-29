//
//  IntroViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;
@class AsyncImageView;
@interface IntroViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet AsyncImageView *logo;

    IBOutlet UITextField *inputLogin;
    IBOutlet UITextField *inputPassword;
    IBOutlet UITextField *inputConfirmation;

    IBOutlet UIButton *buttonLogin;
    IBOutlet UIButton *buttonSignup;

    NSMutableDictionary *ready;

    MBProgressHUD *progress;
    BOOL isFailed;
}

-(IBAction)didClickLogin:(id)sender;
-(IBAction)didClickSignup:(id)sender;
@end
