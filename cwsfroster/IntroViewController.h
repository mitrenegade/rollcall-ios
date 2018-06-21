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

}

@property (nonatomic) BOOL isSignup;
@property (weak, nonatomic) IBOutlet UIButton *buttonLoginSignup;
@property (weak, nonatomic) IBOutlet UIButton *buttonSwitchMode;
@property (weak, nonatomic) IBOutlet UITextField *inputLogin;
@property (weak, nonatomic) IBOutlet UITextField *inputPassword;
@property (weak, nonatomic) IBOutlet UITextField *inputConfirmation;
@property (nonatomic) BOOL isParseConversion;

-(void)refresh;
-(void)enableButtons:(BOOL)enabled;

-(void)loginToParse;
-(void)goToPracticesHelper: (BOOL)convertedFromParse;
-(void)showProgress: (NSString *)title;
-(void)hideProgress;
@end

