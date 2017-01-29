//
//  IntroViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "IntroViewController.h"
#import <Parse/Parse.h>
#import "ParseBase+Parse.h"
#import "MBProgressHUD.h"
#import "Member+Info.h"
#import "Organization+Parse.h"
#import "AsyncImageView.h"
#import "Payment+Parse.h"
#import "TutorialScrollView.h"
#import "UIAlertView+MKBlockAdditions.h"

@implementation IntroViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    if ([PFUser currentUser]) {
        [self loggedIn];
    }
    else {
        [self enableButtons:YES];
        [self reset:YES];
    }
}

-(void)reset:(BOOL)showLogin {
    [inputConfirmation.superview setHidden:YES];
    inputPassword.text = nil;
    inputConfirmation.text = nil;
    inputLogin.superview.layer.borderWidth = 1;
    inputLogin.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    inputPassword.superview.layer.borderWidth = 1;
    inputPassword.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    inputConfirmation.superview.layer.borderWidth = 1;
    inputConfirmation.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    [UIView animateWithDuration:.25 animations:^{
        if (showLogin)
            [logo setAlpha:showLogin?0:1];
        [inputLogin.superview setAlpha:showLogin?1:0];
        [inputPassword.superview setAlpha:showLogin?1:0];
        [buttonLogin setAlpha:showLogin?1:0];
        [buttonSignup setAlpha:showLogin?1:0];
        [tutorialView setAlpha:showLogin?1:0];
        [buttonReset setAlpha:showLogin?1:0];
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

-(void)loggedIn {
    ready = [NSMutableDictionary dictionary];
    NSArray *classes = @[@"Member", @"Practice", @"Attendance"];
    for (NSString *className in classes) {
        ready[className] = @NO;
    }
    isFailed = NO;

    [self reset:NO];
    PFObject *organizationObject = _currentUser[@"organization"];
    NSLog(@"Fetching organization %@ for user %@", organizationObject, _currentUser);
    if (!organizationObject) {
        // todo
        NSLog(@"Handle this!");
    }
    [organizationObject fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            // organization doesn't exist
            [PFUser logOut];
            [Organization reset];
            progress.mode = MBProgressHUDModeText;
            progress.labelText = @"Invalid organization";
            progress.detailsLabelText = @"Please sign up with a valid organization";
            [progress hide:YES afterDelay:1.5];
            [self enableButtons:YES];
            [self reset:YES];
        }
        else {
            [ParseBase synchronizeClass:@"Organization" fromObjects:@[object] replaceExisting:YES completion:nil];

            if ([organizationObject objectForKey:@"logoData"]) {
                PFFile *imageFile = organizationObject[@"logoData"];
                [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    logo.alpha = 0;
                    UIImage *image = [UIImage imageWithData:data];
                    [logo setImage:image];
                    [UIView animateWithDuration:1 animations:^{
                        logo.alpha = 1;
                    } completion:^(BOOL finished) {
                    }];
                }];
            }
            else {
                [logo setImage:nil];
            }

            [self synchronizeWithParse];
        }
    }];
}

-(void)enableButtons:(BOOL)enabled {
    [buttonLogin setAlpha:enabled?1:.5];
    [buttonSignup setAlpha:enabled?1:.5];
    [buttonLogin setEnabled:enabled];
    [buttonSignup setEnabled:enabled];
}

#pragma login
-(IBAction)didClickLogin:(id)sender {
    inputConfirmation.superview.alpha = 0;
    inputConfirmation.superview.hidden = YES;

    if (inputLogin.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter a login name" message:nil];
        return;
    }
    if (inputPassword.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter your password" message:nil];
        return;
    }

    [self enableButtons:NO];
    progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeIndeterminate;
    progress.taskInProgress = YES;
    [PFUser logInWithUsernameInBackground:inputLogin.text password:inputPassword.text block:^(PFUser *user, NSError *error) {
        if (user) {
            [self loggedIn];
        }
        else {
            NSString *message = nil;
            if (error.code == 100) {
                message = @"Please make sure you are connected to the internet.";
            }
            if (error.code == 101) {
                message = @"Invalid username or password";
            }
            progress.mode = MBProgressHUDModeText;
            progress.labelText = @"Login failed";
            progress.detailsLabelText = message;
            [progress hide:YES afterDelay:1.5];
            [self enableButtons:YES];
        }
    }];
}

-(IBAction)didClickSignup:(id)sender {
    if (inputConfirmation.superview.hidden) {
        inputConfirmation.superview.alpha = 1;
        [inputConfirmation.superview setHidden:NO];
        inputConfirmation.alpha = 1;
        return;
    }

    if (inputLogin.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter a login name" message:nil];
        return;
    }
    if (inputPassword.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter your password" message:nil];
        return;
    }
    if (inputConfirmation.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter your password confirmation" message:nil];
        return;
    }
    if (![inputConfirmation.text isEqualToString:inputConfirmation.text]) {
        [UIAlertView alertViewWithTitle:@"Invalid password" message:@"Password and confirmation do not match"];
        return;
    }

    [self enableButtons:NO];

    PFUser *user = [PFUser user];
    user.username = inputLogin.text;
    user.password = inputPassword.text;
    if ([self isValidEmail:inputLogin.text]) {
        user.email = inputLogin.text;
    }

    progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeIndeterminate;
    progress.taskInProgress = YES;

    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self createOrganizationWithCompletion:^(Organization *organization) {
                [self loggedIn];
            }];
        }
        else {
            NSString *message = nil;
            if (error.code == 100) {
                message = @"Please make sure you are connected to the internet.";
            }
            if (error.code == 202) {
                message = @"Username already taken";
            }
            [self enableButtons:YES];
            progress.mode = MBProgressHUDModeText;
            progress.labelText = @"Signup failed";
            progress.detailsLabelText = message;
            [progress hide:YES afterDelay:1.5];
        }
    }];
}

-(void)synchronizeWithParse {
    // make sure all parse objects are in core data
    NSArray *classes = @[@"Member", @"Practice", @"Attendance", @"Payment"];
    [self performSelector:@selector(showProgress) withObject:progress afterDelay:3];

    for (NSString *className in classes) {
        PFQuery *query = [PFQuery queryWithClassName:className];
        PFUser *user = _currentUser;
        [user fetchIfNeeded];
        [query whereKey:@"organization" equalTo:_currentUser[@"organization"]];
        NSLog(@"Querying for %@ for organization %@", className, _currentUser[@"organization"]);
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
                if (!isFailed) {
                    if (!progress || ![progress taskInProgress]) {
                        progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    }
                    progress.mode = MBProgressHUDModeText;
                    progress.labelText = @"Synchronization error";
                    if (error.code == 1000) {
                        progress.detailsLabelText = @"Request timeout. Make sure you are connected to the Internet";
                    }
                    else {
                        progress.detailsLabelText = [NSString stringWithFormat:@"Parse error code %ld", (long)error.code];
                    }
                    isFailed = YES;
                    [self performSelector:@selector(hideProgress) withObject:nil afterDelay:3];

                    // still proceed and allow offline usave
                    [self performSelector:@selector(goToPractices) withObject:nil afterDelay:3];
                }
            }
            else {
                [progress hide:YES];
                if ([className isEqualToString:@"Practice"]) {
                    NSLog(@"Here");
                }
                NSLog(@"Synchronizing class %@", className);
                [ParseBase synchronizeClass:className fromObjects:objects replaceExisting:YES completion:^{
                    ready[className] = @YES;
                    if ([self isReady])
                        [self goToPractices];
                }];
            }
        }];
    }
}

-(void)showProgress {
    if (!progress || !progress.taskInProgress) {
        progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    progress.taskInProgress = YES;
    progress.mode = MBProgressHUDModeIndeterminate;
    progress.labelText = @"Synchronizing data";
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

-(void)goToPractices {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showProgress) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideProgress) object:nil];
    [logo setAlpha:1];
    [self performSegueWithIdentifier:@"IntroToPractices" sender:self];
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

#pragma mark core data
-(void)createOrganizationWithCompletion:(void(^)(Organization *organization))completion {
    Organization *object = (Organization *)[Organization createEntityInContext:_appDelegate.managedObjectContext];
    [object updateEntityWithParams:@{@"name":[[PFUser currentUser] username]}];
    [object saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            _currentUser[@"organization"] = object.pfObject;

            NSError *error;
            if ([_appDelegate.managedObjectContext save:&error]) {
                [_currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        if (completion)
                            completion(object);
                        else
                            completion(nil);
                    }
                }];
            }
        }
        else {
            NSLog(@"Could not save organization!");
            [UIAlertView alertViewWithTitle:@"Save error" message:@"There was an error creating an organization. Please contact us to update your organization."];
            completion(nil);
        }
    }];
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

        [PFAnalytics trackEvent:@"password reset"];

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
