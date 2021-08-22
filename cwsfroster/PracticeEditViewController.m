//
//  PracticeEditViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticeEditViewController.h"
#import "Util.h"
#import "UIAlertView+MKBlockAdditions.h"

@interface PracticeEditViewController ()

@end

@implementation PracticeEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setupViews {

    NSString *defaultTitle = self.practice.title ? : [self titleForDate:[NSDate date]];
    for (int i=0; i<[self.datesForPicker count]; i++) {
        if ([defaultTitle isEqualToString:self.datesForPicker[i]]) {
            self.currentRow = i;
            break;
        }
        NSDate *selectedDate = [self dateOnly:self.dateForDateString[self.datesForPicker[i]]];
        NSDate *practiceDate = [self.practice dateOnly];
        //NSLog(@"Date: %@ %@", selectedDate, practiceDate);

        if (selectedDate == practiceDate) {
            self.currentRow = i;
            break;
        }
    }


    self.emailTo = [[NSUserDefaults standardUserDefaults] objectForKey:@"email:to"];

    if (self.practice == nil) {
        self.createPracticeInfo = [[NSDictionary alloc] init];
    }
}

@end
