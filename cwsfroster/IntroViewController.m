//
//  IntroViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "IntroViewController.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "TutorialScrollView.h"
#import "UIAlertView+MKBlockAdditions.h"

@implementation IntroViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [self enableButtons:YES];
    [self refresh];
    
    self.isSignup = NO;
}

-(void)refresh {
    if (self.isSignup) {
        constraintConfirmationHeight.constant = 40;
    }
    else {
        constraintConfirmationHeight.constant = 0;
    }
    
    inputPassword.text = nil;
    inputConfirmation.text = nil;
    inputLogin.superview.layer.borderWidth = 1;
    inputLogin.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    inputPassword.superview.layer.borderWidth = 1;
    inputPassword.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    inputConfirmation.superview.layer.borderWidth = 1;
    inputConfirmation.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    inputLogin.alpha = 1;
    inputPassword.alpha = 1;
    
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:.25 animations:^{
        NSString *title = self.isSignup ? @"Sign up" : @"Log in";
        [self.buttonLoginSignup setTitle:title forState:UIControlStateNormal];
        NSString *title2 = self.isSignup ? @"Back to login" : @"New user?";
        [self.buttonSwitchMode setTitle:title2 forState:UIControlStateNormal];
        //[tutorialView setAlpha:self.isSignup ? 0 : 1];
        
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

-(void)loadTutorial {
    [tutorialView setTutorialPages:@[@"IntroTutorial0", @"IntroTutorial1", @"IntroTutorial2", @"IntroTutorial3"]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![PFUser currentUser]) {
        [self loadTutorial];
    }
}

-(void)enableButtons:(BOOL)enabled {
    [self.buttonLoginSignup setAlpha:enabled?1:.5];
    [self.buttonSwitchMode setAlpha:enabled?1:.5];
    [self.buttonLoginSignup setEnabled:enabled];
    [self.buttonSwitchMode setEnabled:enabled];
}

#pragma login
-(void)showProgress: (NSString *)title {
    if (!progress || !progress.taskInProgress) {
        progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    progress.taskInProgress = YES;
    progress.mode = MBProgressHUDModeIndeterminate;
    if (title == nil) {
        progress.labelText = @"Synchronizing data";
    } else {
        progress.labelText = title;
    }
}

-(void)hideProgress {
    progress.taskInProgress = NO;
    [progress hide:YES];
    progress = nil;
}

-(BOOL)isReady {
    for (id key in [ready.keyEnumerator allObjects]) {
        NSNumber *r = ready[key];
        if ([r boolValue] == NO)
            return NO;
    }
    return YES;
}

#pragma mark TextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)dismissKeyboard {
    [inputLogin resignFirstResponder];
    [inputPassword resignFirstResponder];
}

#pragma mark Password reset stuff
-(BOOL)isValidEmail:(NSString *)email
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

-(IBAction)didClickPasswordReset:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request password reset" message:@"Please enter an email associated with your account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * text = [alert textFieldAtIndex:0];
    [text setKeyboardType:UIKeyboardTypeEmailAddress];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField * text = [alertView textFieldAtIndex:0];
        NSLog(@"Reset with email %@", text.text);

        [ParseLog logWithTypeString:@"PasswordReset" title:nil message:nil params:nil error:nil];

        [PFUser requestPasswordResetForEmailInBackground:text.text block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Success");
                [UIAlertView alertViewWithTitle:@"Password reset sent" message:@"Please check your email for password reset instructions."];
            }
            else {
                NSLog(@"Error: %@", error);
                if (error.code == 125) {
                    [UIAlertView alertViewWithTitle:@"Invalid email" message:@"Please enter a valid email to send a reset link"];
                }
                else if (error.code == 205) {
                    [UIAlertView alertViewWithTitle:@"Invalid user" message:@"No user was found with that email. Please contact us directly for help."];
                }
                else {
                    [UIAlertView alertViewWithTitle:@"Error resetting password" message:error.userInfo[@"error"]];
                }
            }
        }];
    }
}

@end
