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

@implementation IntroViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    if ([PFUser currentUser]) {
        [self loggedIn];
    }
    else {
        inputLogin.superview.layer.borderWidth = 1;
        inputLogin.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        inputPassword.superview.layer.borderWidth = 1;
        inputPassword.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        inputConfirmation.superview.layer.borderWidth = 1;
        inputConfirmation.superview.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        [inputLogin.superview setHidden:NO];
        [inputPassword.superview setHidden:NO];
        [inputConfirmation.superview setHidden:YES];
        [buttonLogin setHidden:NO];
        [buttonSignup setHidden:NO];
    }
}

-(void)loggedIn {
    ready = [NSMutableDictionary dictionary];
    NSArray *classes = @[@"Member", @"Practice", @"Attendance"];
    for (NSString *className in classes) {
        ready[className] = @NO;
    }
    isFailed = NO;

    /*
    logo.alpha = 0;
    ready[@"animation"] = @NO;
    [UIView animateWithDuration:1 animations:^{
        logo.alpha = 1;
    } completion:^(BOOL finished) {
        ready[@"animation"] = @YES;
        if ([self isReady]) {
            [self goToPractices];
        }
    }];
     */

    [self synchronizeWithParse];
}

-(void)enableButtons:(BOOL)enabled {
    [buttonLogin setEnabled:enabled];
    [buttonSignup setEnabled:enabled];
}

#pragma login
-(IBAction)didClickLogin:(id)sender {
    if (inputLogin.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter a login name" message:nil];
        return;
    }
    if (inputPassword.text.length == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter your password" message:nil];
        return;
    }

    [self enableButtons:NO];
    [PFUser logInWithUsernameInBackground:inputLogin.text password:inputPassword.text block:^(PFUser *user, NSError *error) {
        if (user) {
            [self loggedIn];
        }
        else {
            NSString *message = nil;
            if (error.code == 101) {
                message = @"Invalid username or password";
            }
            [UIAlertView alertViewWithTitle:@"Login failed" message:message];
            [self enableButtons:YES];
        }
    }];
}

-(IBAction)didClickSignup:(id)sender {
    if ([inputConfirmation.superview isHidden]) {
        [inputConfirmation.superview setHidden:NO];
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

    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self createOrganization];
            [self loggedIn];
        }
        else {
            NSString *message = nil;
            if (error.code == 202) {
                message = @"Username already taken";
            }
            [UIAlertView alertViewWithTitle:@"Signup failed" message:message];
            [self enableButtons:YES];
        }
    }];
}

-(void)synchronizeWithParse {
    // make sure all parse objects are in core data
    NSArray *classes = @[@"Member", @"Practice", @"Attendance", @"Payment"];
    [self performSelector:@selector(showProgress) withObject:progress afterDelay:3];

    for (NSString *className in classes) {
        PFQuery *query = [PFQuery queryWithClassName:className];
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
                if ([className isEqualToString:@"Payment"]) {
                    NSLog(@"Here");
                }
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
-(void)createOrganization {
    Organization *object = (Organization *)[Organization createEntityInContext:_appDelegate.managedObjectContext];
    [object updateEntityWithParams:@{@"name":[[PFUser currentUser] username]}];
    [object saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            NSError *error;
            if ([_appDelegate.managedObjectContext save:&error]) {
                [PFUser currentUser][@"organization"] = object;
                [[PFUser currentUser] saveInBackground];
            }
        }
        else {
            NSLog(@"Could not save organization!");
            [UIAlertView alertViewWithTitle:@"Save error" message:@"There was an error creating an organization. Please contact us to update your organization."];
        }
    }];
}


@end
