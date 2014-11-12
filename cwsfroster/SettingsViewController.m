//
//  SettingsViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import "ParseBase+Parse.h"
#import "MBProgressHUD.h"
#import "UIImage+Resize.h"

#define SECTION_TITLES @[@"About", @"My organization", @"My account", @"Feedback", @"Logout"]
@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
        NSString *message = [NSString stringWithFormat:@"Version %@\nCopyright Bobby Ren 2014\n", VERSION];
        [UIAlertView alertViewWithTitle:@"About RollCall" message:message];
    }
    else if (row == 1) {
        // my company
        NSString *title = [Organization currentOrganization].name;
        NSString *message = @"Please select from the following options";
        [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Change name", @"Change logo"] onDismiss:^(int buttonIndex) {
            if (buttonIndex == 0) {
                [self goToUpdateName];
            }
            else if (buttonIndex == 1) {
                NSLog(@"Change logo");
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
        [PFUser logOut];
        [Organization reset];
        [_appDelegate goToIntro];
    }
}

-(void)goToFeedback {
    if ([MFMailComposeViewController canSendMail]){
        NSString *title = @"RollCall feedback";
        NSString *message = [NSString stringWithFormat:@"\n\nOrganization: %@\nVersion %@", [Organization currentOrganization].name, VERSION];
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        [composer setSubject:title];
        [composer setToRecipients:@[@"bobbyren+rollcall@gmail.com"]];
        [composer setMessageBody:message isHTML:NO];

        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        [UIAlertView alertViewWithTitle:@"Currently unable to send email" message:@"Please make sure email is available"];
    }
}

-(void)goToUpdateName {
    NSLog(@"Change name");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please enter your organization name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 1;
    [alert show];
}

-(void)goToUpdateUsername {
    NSLog(@"Change name");
    NSString *message = _currentUser.username?[NSString stringWithFormat:@"Your current login is %@", _currentUser.username]:nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please update your login name" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 2;
    [alert show];
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
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"index 0 - cancel");
    }
    else {
        NSLog(@"else");
        UITextField * text = [alertView textFieldAtIndex:0];
        if (alertView.tag == 1) {
            Organization *organization = [Organization currentOrganization];
            organization.name = text.text;
            [organization saveOrUpdateToParseWithCompletion:^(BOOL success) {
                if (success) {
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

#pragma mark Camera
-(void)goToUpdateLogo {
    _picker = [[UIImagePickerController alloc] init];
    _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    _picker.toolbarHidden = YES; // hide toolbar of app, if there is one.
    _picker.allowsEditing = YES;
    _picker.wantsFullScreenLayout = YES;
    _picker.delegate = self;

    [self presentViewController:_picker animated:YES completion:nil];
}

#pragma mark ImagePickerController delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image.size.width > 320 || image.size.height > 320) {
        image = [image resizedImage:CGSizeMake(320, 320/image.size.width*image.size.height) interpolationQuality:kCGInterpolationDefault];
    }
    NSData *data = UIImageJPEGRepresentation(image, .8);
    PFFile *imageFile = [PFFile fileWithData:data];

    progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeDeterminateHorizontalBar;
    progress.labelText = @"Saving new logo";
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hide old HUD, show completed HUD (see example for code)
            [progress hide:YES];

            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *organization = [Organization currentOrganization].pfObject;
            [organization setObject:imageFile forKey:@"logoData"];
            [organization saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            progress.labelText = @"Upload failed";
            progress.mode = MBProgressHUDModeText;
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        progress.progress = percentDone/100.0;
    }];

    [self dismissViewControllerAnimated:YES completion:nil];
}

//Tells the delegate that the user cancelled the pick operation.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
