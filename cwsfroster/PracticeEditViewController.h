//
//  PracticeEditViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

#define FUTURE_DAYS 14

@protocol PracticeEditDelegate <NSObject>

-(void)didCreatePractice;
-(void)didEditPractice;

@end

@class FirebaseEvent;
@interface PracticeEditViewController : UIViewController
{
}


@end
