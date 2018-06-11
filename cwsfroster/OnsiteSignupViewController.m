//
//  OnsiteSignupViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import "OnsiteSignupViewController.h"
#import "RatingViewController.h"

@interface OnsiteSignupViewController ()

@end

@implementation OnsiteSignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = close;
    
    if (self.practice.details.length) {
        self.title = self.practice.details;
    }
    self.labelWelcome.alpha = 0;
    
    self.rater = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RatingViewController"];
    self.rater.delegate = self;
    
    self.addedAttendees = [NSMutableArray array];
    
    [self setupKeyboardDoneButtonView];
}

-(void)close {
    if (!self.didShowRater) {
        if (![self.rater showRatingsIfConditionsMetFromView:self.view forced:NO]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        self.didShowRater = YES;
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)didCloseRating {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

#pragma mark UITextFieldDelegate
-(void)goToFeedback {
    if ([MFMailComposeViewController canSendMail]){
        NSString *title = @"RollCall feedback";
        NSString *message = [NSString stringWithFormat:@"\n\nOrganization: %@\nVersion %@", [Organization current].name, VERSION];
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        [composer setSubject:title];
        [composer setToRecipients:@[@"bobbyren+rollcall@gmail.com"]];
        [composer setMessageBody:message isHTML:NO];
        
        [self presentViewController:composer animated:YES completion:nil];
    }
    else {
        [UIAlertView alertViewWithTitle:@"Currently unable to send email" message:@"Please make sure email is available"];
    }

    [ParseLog logWithTypeString:@"FeedbackEntered" title:nil message:nil params:nil error:nil];
}

#pragma mark MessageController delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //feedbackMsg.text = @"Result: Mail sending canceled";
            break;
        case MFMailComposeResultSaved:
            //feedbackMsg.text = @"Result: Mail saved";
            break;
        case MFMailComposeResultSent:
            //feedbackMsg.text = @"Result: Mail sent";
            [UIAlertView alertViewWithTitle:@"Thanks for your feedback" message:nil];
            break;
        case MFMailComposeResultFailed:
            //feedbackMsg.text = @"Result: Mail sending failed";
            [UIAlertView alertViewWithTitle:@"There was an error sending feedback" message:nil];
            break;
        default:
            //feedbackMsg.text = @"Result: Mail not sent";
            break;
    }
    // dismiss the composer
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
