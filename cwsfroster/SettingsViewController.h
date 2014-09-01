//
//  SettingsViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@class MBProgressHUD;
@interface SettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImagePickerController *_picker;
    MBProgressHUD *progress;
}
-(IBAction)didClickClose:(id)sender;

@end
