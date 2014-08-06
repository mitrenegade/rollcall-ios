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

    for (NSString *className in classes) {
        Class class = NSClassFromString(className);

        PFQuery *query = [PFQuery queryWithClassName:className];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            for (PFObject *object in objects) {
                [class fromPFObject:object];
            }
            NSLog(@"Query for %@ returned %lu objects", className, (unsigned long)[objects count]);
            ready[className] = @YES;
            if ([self isReady])
                [self goToPractices];
        }];
    }

    // todo: make sure all objects not in parse data base are deleted from core data
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
    [logo setAlpha:1];
    [self performSegueWithIdentifier:@"IntroToPractices" sender:self];
}
@end
