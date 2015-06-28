//
//  RatingViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/28/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import "RatingViewController.h"

@interface RatingViewController ()

@end

@implementation RatingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setStarCount:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)showRatingsIfConditionsMetFromView:(UIView *)view forced:(BOOL)forced {
    
    if (!forced) {
        // increment event
        int eventCount = [_defaults integerForKey:kRatingEventCount] + 1;
        if (eventCount > EVENTS_UNTIL_PROMPT)
            eventCount = 0;
        [_defaults setInteger:eventCount forKey:kRatingEventCount];
        
        if (![self canShow]) {
            [self.delegate didCloseRating];
            return NO;
        }
    }
    self.view.frame = CGRectMake(0, 0, view.frame.size.width, 40);
    self.view.layer.borderWidth = 1;
    self.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.view.alpha = 0;
    [view addSubview:self.view];
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 1;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(close) withObject:nil afterDelay:10];
    }];
    return YES;
}


-(IBAction)didClickStar:(UIButton *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(close) object:nil];
    [self didRateWithStars:sender.tag];
}

-(IBAction)didClickClose:(id)sender {
    [self close];
}

-(void)didRateWithStars:(NSInteger)stars {
    NSLog(@"Stars %d", (int)stars);
    [self setStarCount:(int)stars];
    if (stars > 3) {
        [UIAlertView alertViewWithTitle:@"Rate us in the app store?" message:@"Would you like to go to the app store to rate us? It would help a lot!" cancelButtonTitle:@"Never rate" otherButtonTitles:@[@"Rate us", @"Remind me later"] onDismiss:^(int buttonIndex) {
            if (buttonIndex == 0) {
                [_defaults setObject:VERSION forKey:kRatingCurrentVersion];
                NSString *reviewURL = nil;
                // iOS 7 needs a different templateReviewURL @see https://github.com/arashpayan/appirater/issues/131
                if (IS_ABOVE_IOS7) {
                    // iOS 8 needs a different templateReviewURL also @see https://github.com/arashpayan/appirater/issues/182
                    reviewURL = [templateReviewURLiOS8 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", APP_ID]];
                }
                else if (IS_ABOVE_IOS6) {
                    reviewURL = [templateReviewURLiOS7 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", APP_ID]];
                }
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
            }
            else {
                [_defaults setObject:@NO forKey:kRatingNeverRate]; // cancels never rate
            }
            [self close];
        } onCancel:^{
            [_defaults setObject:@YES forKey:kRatingNeverRate];
            [self close];
        }];
    }
    else {
        [UIAlertView alertViewWithTitle:@"Sorry to hear that" message:@"Would you like to send us some direct feedback? It would help a lot!" cancelButtonTitle:@"No thanks" otherButtonTitles:@[@"Email us"] onDismiss:^(int buttonIndex) {
            [self close];
            [self.delegate goToFeedback];
        } onCancel:^{
            // do nothing
            [self close];
        }];
    }
    [_defaults setObject:[NSDate date] forKey:kRatingLastDate];
}

-(void)close {
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self.delegate didCloseRating];
    }];
}

-(void)setStarCount:(int)count {
    NSArray *views = @[star1, star2, star3, star4, star5];
    UIImage *starEmpty = [[UIImage imageNamed:@"star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    for (int i=0; i<count; i++) {
        UIImageView *star = views[i];
        star.tintColor = [UIColor greenColor];
        star.image = starEmpty;
    }
    for (int i=count; i<views.count; i++) {
        UIImageView *star = views[i];
        star.tintColor = [UIColor lightGrayColor];
        star.image = starEmpty;
    }
}

#pragma mark handle appirater-like stuff

-(BOOL)canShow {
    // already rated this version
#if RATING_DEBUG
    return YES;
#endif
    
    if ([[_defaults objectForKey:kRatingCurrentVersion] isEqualToString:VERSION]) {
        NSLog(@"GPRater: has already rated %@", VERSION);
        return NO;
    }
    
    if ([_defaults integerForKey:kRatingEventCount] < EVENTS_UNTIL_PROMPT) {
        NSLog(@"GPRater: event count %ld", (long)[_defaults integerForKey:kRatingEventCount]);
        return NO;
    }
    
    // not enough time has passed since first time using app
    if ([_defaults objectForKey:kRatingFirstOpenDate]) {
        float secondsPassed = [[NSDate date] timeIntervalSinceDate:[_defaults objectForKey:kRatingFirstOpenDate]];
        if (secondsPassed < DAYS_AFTER_OPEN*24*3600) {
            NSLog(@"GPRater: days passed since first time: %f", secondsPassed / 3600.0 / 24);
            return NO;
        }
    }
    
    // not enough time has passed since last rating request
    if ([_defaults objectForKey:kRatingLastDate]) {
        float secondsPassed = [[NSDate date] timeIntervalSinceDate:[_defaults objectForKey:kRatingLastDate]];
        if (secondsPassed < DAYS_BEFORE_REPROMPT*24*3600) {
            NSLog(@"GPRater: days passed: %f", secondsPassed / 3600.0 / 24);
            return NO;
        }
    }
    
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
