//
//  SettingsViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import "MBProgressHUD.h"
#import "UIImage+Resize.h"
#import "Parse/Parse.h"

#define SECTION_TITLES @[@"About", @"My organization", @"My account", @"Feedback", @"Logout"]
@interface SettingsViewController ()

@end

@implementation SettingsViewController

-(void)didClickClose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return SECTION_TITLES.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = SECTION_TITLES[indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int row = indexPath.row;
    if (row == 0) {
        // about
        NSString *message = [NSString stringWithFormat:@"Version %@\nCopyright RenderApps, LLC 2017\n", VERSION];
        [UIAlertView alertViewWithTitle:@"About RollCall" message:message];
    }
    else if (row == 1) {
        // my company
        NSString *title = [Organization current].name;
        NSString *message = @"Please select from the following options";
        [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Change name", @"Change logo"] onDismiss:^(int buttonIndex) {
            if (buttonIndex == 0) {
                [self goToUpdateName];
            }
            else if (buttonIndex == 1) {
                NSLog(@"Change logo");
                [self setupCameraHelper];
                [self goToUpdateLogo];
            }
        } onCancel:nil];
    }
    else if (row == 2) {
        // my account
        NSString *title = nil;
        NSString *message = @"Please select from the following options";
        [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Change login", @"Change email"] onDismiss:^(int buttonIndex) {
            if (buttonIndex == 0) {
                [self goToUpdateUsername];
            }
            else if (buttonIndex == 1) {
                NSLog(@"Change logo");
                [self goToUpdateUserEmail];
            }
        } onCancel:nil];    }
    else if (row == 3) {
        // feedback
        [self goToFeedback];
    }
    else if (row == 4) {
        // logout
        [AuthService logout];
        [self notifyForLogoutInSuccess];
    }
}

-(void)goToFeedback {
    if ([MFMailComposeViewController canSendMail]){
        NSString *title = @"RollCall feedback";
        NSString *message = [NSString stringWithFormat:@"\n\nOrganization: %@\nVersion %@", [Organization current].name, VERSION];
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        [composer setSubject:title];
        [composer setToRecipients:@[@"bobby+rollcall@renderapps.io"]];
        [composer setMessageBody:message isHTML:NO];

        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        [UIAlertView alertViewWithTitle:@"Currently unable to send email" message:@"Please make sure email is available"];
    }
}

-(void)goToUpdateName {
    NSLog(@"Change name");
    NSString *title = [NSString stringWithFormat:@"Organization: %@.", [[Organization current] name]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:@"Please enter new organization name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 1;
    [alert show];

    [ParseLog logWithTypeString:@"UpdateOrganizationName" title:[[Organization current] objectId] message:nil params:nil error:nil];
}

-(void)goToUpdateUsername {
    NSLog(@"Change name");
    NSString *message = _currentUser.username?[NSString stringWithFormat:@"Your current login is %@", _currentUser.username]:nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please update your login name" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 2;
    [alert show];

    [ParseLog logWithTypeString:@"UpdateOrganizationLogin" title:[[Organization current] objectId] message:nil params:nil error:nil];
}

-(void)goToUpdateUserEmail {
    NSLog(@"Change email");
    NSString *message = _currentUser.email?[NSString stringWithFormat:@"Your current email is %@", _currentUser.email]:nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter your email" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *text = [alert textFieldAtIndex:0];
    text.keyboardType = UIKeyboardTypeEmailAddress;
    alert.tag = 3;
    [alert show];

    [ParseLog logWithTypeString:@"UpdateOrganizationEmail" title:[[Organization current] objectId] message:nil params:nil error:nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"index 0 - cancel");
    }
    else {
        NSLog(@"else");
        UITextField * text = [alertView textFieldAtIndex:0];
        if (alertView.tag == 1) {
            Organization *organization = [Organization current];
            organization.name = text.text;
            [organization saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    NSLog(@"Saved");
                    [UIAlertView alertViewWithTitle:@"Name saved" message:[NSString stringWithFormat:@"Your organization is now called %@", organization.name]];
                    [self notify:@"organization:name:changed"];
                }
                else {
                    [UIAlertView alertViewWithTitle:@"Error updating name" message:nil];
                }
            }];
        }
        else if (alertView.tag == 2) {
            // username
            _currentUser.username = text.text;
            [_currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Saved");
                    [UIAlertView alertViewWithTitle:@"Username saved" message:[NSString stringWithFormat:@"Your login is now %@", _currentUser.username]];
                }
                else {
                    [UIAlertView alertViewWithTitle:@"Error updating name" message:nil];
                }
            }];
        }
        else if (alertView.tag == 3) {
            // username
            _currentUser.email = text.text;
            [_currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Saved");
                    [UIAlertView alertViewWithTitle:@"Email saved" message:[NSString stringWithFormat:@"Your email is now %@", _currentUser.email]];
                }
                else {
                    [UIAlertView alertViewWithTitle:@"Error updating email" message:error.userInfo[@"error"]];
                }
            }];
        }
    }
}

#pragma mark MessageController delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {

    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //feedbackMsg.text = @"Result: Mail sending canceled";
            break;
        case MFMailComposeResultSaved:
            //feedbackMsg.text = @"Result: Mail saved";
            break;
        case MFMailComposeResultSent:
            //feedbackMsg.text = @"Result: Mail sent";
            [UIAlertView alertViewWithTitle:@"Thanks for your feedback" message:nil];
            break;
        case MFMailComposeResultFailed:
            //feedbackMsg.text = @"Result: Mail sending failed";
            [UIAlertView alertViewWithTitle:@"There was an error sending feedback" message:nil];
            break;
        default:
            //feedbackMsg.text = @"Result: Mail not sent";
            break;
    }
    // dismiss the composer
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

-(void)showProgress: (NSString *)title {
    if (!progress || !progress.taskInProgress) {
        progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    progress.taskInProgress = YES;
    progress.mode = MBProgressHUDModeDeterminateHorizontalBar;
    if (title == nil) {
        progress.labelText = @"Uploading photo";
    } else {
        progress.labelText = title;
    }
}

-(void)updateProgress:(float)percent {
    progress.progress = percent;
}

-(void)hideProgress {
    progress.taskInProgress = NO;
    [progress hide:YES];
    progress = nil;
}

@end
