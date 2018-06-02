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
@class CameraHelper;
@interface SettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    MBProgressHUD *progress;
    CameraHelper *cameraHelper;
}
-(IBAction)didClickClose:(id)sender;

@property (nonatomic) CameraHelper *cameraHelper;

-(void)showProgress: (NSString *)title;
-(void)updateProgress:(float)percent;
-(void)hideProgress;

@end
