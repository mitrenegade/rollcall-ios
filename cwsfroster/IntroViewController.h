//
//  IntroViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

@interface IntroViewController : UIViewController
{
    IBOutlet UIImageView *logo;
    NSMutableDictionary *ready;

    MBProgressHUD *progress;
    BOOL isFailed;
}
@end