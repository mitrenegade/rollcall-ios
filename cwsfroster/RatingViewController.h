//
//  RatingViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/28/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

#define RATING_DEBUG 1
#define EVENTS_UNTIL_PROMPT 3
#define DAYS_AFTER_OPEN 0
#define DAYS_BEFORE_REPROMPT 14

static NSString *const kRatingLastDate = @"kRatingLastDate";
static NSString *const kRatingFirstOpenDate = @"kRatingFirstOpenDate";
static NSString *const kRatingCurrentVersion = @"kRatingCurrentVersion";
static NSString *const kRatingNeverRate = @"kRatingNeverRate";

static NSString *const kRatingEventCount = @"kRatingEventCount";

static NSString *templateReviewURLiOS7 = @"itms-apps://itunes.apple.com/app/idAPP_ID";
static NSString *templateReviewURLiOS8 = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=APP_ID&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software";

@protocol RatingDelegate <NSObject>

-(void)goToFeedback;
-(void)didCloseRating;

@end

@interface RatingViewController : UIViewController
{
    IBOutlet UIButton *button1;
    IBOutlet UIButton *button2;
    IBOutlet UIButton *button3;
    IBOutlet UIButton *button4;
    IBOutlet UIButton *button5;
    IBOutlet UIImageView *star1;
    IBOutlet UIImageView *star2;
    IBOutlet UIImageView *star3;
    IBOutlet UIImageView *star4;
    IBOutlet UIImageView *star5;
    IBOutlet UIButton *buttonClose;
}

@property (weak, nonatomic) id delegate;

-(BOOL)showRatingsIfConditionsMetFromView:(UIView *)view forced:(BOOL)forced;
-(BOOL)canShow;
@end
