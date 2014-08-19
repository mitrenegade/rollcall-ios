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

@implementation IntroViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    ready = [NSMutableDictionary dictionary];
    ready[@"animation"] = @NO;
    NSArray *classes = @[@"Member", @"Practice", @"Attendance"];
    for (NSString *className in classes) {
        ready[className] = @NO;
    }

    logo.alpha = 0;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isFailed = NO;

    [UIView animateWithDuration:1 animations:^{
        logo.alpha = 1;
    } completion:^(BOOL finished) {
        ready[@"animation"] = @YES;
        if ([self isReady]) {
            [self goToPractices];
        }
    }];

    [self synchronizeWithParse];
}

-(void)synchronizeWithParse {
    // make sure all parse objects are in core data
    NSArray *classes = @[@"Member", @"Practice", @"Attendance"];
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

    // todo: make sure all objects not in parse data base are deleted from core data
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

@end
