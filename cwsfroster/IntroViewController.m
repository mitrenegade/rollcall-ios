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

@implementation IntroViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    ready = NO;
    logo.alpha = 0;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self synchronizeWithParse];

    [UIView animateWithDuration:1 animations:^{
        logo.alpha = 1;
    } completion:^(BOOL finished) {
        if (ready) {
            [self goToPractices];
        }
        ready = YES;
    }];
}

-(void)synchronizeWithParse {
    // make sure all parse objects are in core data
    NSArray *classes = @[@"Member", @"Practice", @"Attendance"];
    for (NSString *className in classes) {
        Class class = NSClassFromString(className);

        PFQuery *query = [PFQuery queryWithClassName:className];
        NSArray *objects = [query findObjects]; // do this in foreground
        NSLog(@"Query for %@ returned %lu objects", className, (unsigned long)[objects count]);
        for (PFObject *object in objects) {
            [class fromPFObject:object];
        }
    }

    // todo: make sure all objects not in parse data base are deleted from core data

    if (ready)
        [self goToPractices];
    ready = YES;
}

-(void)goToPractices {
    [logo setAlpha:1];
    [self performSegueWithIdentifier:@"IntroToPractices" sender:self];
}
@end
