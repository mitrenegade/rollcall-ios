//
//  OnsiteSignupViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import "OnsiteSignupViewController.h"
#import "Member+Info.h"
#import "Member+Parse.h"
#import "Practice.h"
#import "Attendance+Parse.h"
#import "Attendance+Info.h"
#import "RatingViewController.h"

@interface OnsiteSignupViewController ()

@end

@implementation OnsiteSignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextField:)];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = [UIColor whiteColor];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [keyboardDoneButtonView setItems:@[flex, done]];
    
    [inputName setInputAccessoryView:keyboardDoneButtonView];
    [inputEmail setInputAccessoryView:keyboardDoneButtonView];
    [inputAbout setInputAccessoryView:keyboardDoneButtonView];
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = close;
    
    if (self.practice.details.length) {
        self.title = self.practice.details;
    }
    labelWelcome.alpha = 0;
    
    rater = [_storyboard instantiateViewControllerWithIdentifier:@"RatingViewController"];
    rater.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)close {
    if (!didShowRater) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        if (![rater showRatingsIfConditionsMetFromView:self.view forced:NO]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        didShowRater = YES;
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)didCloseRating {
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

#pragma mark UITextFieldDelegate
-(void)nextField:(id)sender {
    [self textFieldShouldEndEditing:currentInput];
}
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    currentInput = textField;
    if (currentInput == inputEmail) {
        constraintTopOffset.constant = -40;
    }
    else if (currentInput == inputAbout) {
        constraintTopOffset.constant = -80;
    }
    else {
        constraintTopOffset.constant = 0;
    }
}
-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == inputName) {
        [inputEmail becomeFirstResponder];
    }
    else if (textField == inputEmail) {
        [inputAbout becomeFirstResponder];
    }
    else if (textField == inputAbout) {
        constraintTopOffset.constant = 0;
    }
    return YES;
}

-(void)didClickSignup:(id)sender {
    if ([inputName.text length] == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter a name" message:nil];
        return;
    }
    if ([inputEmail.text length] == 0) {
        [UIAlertView alertViewWithTitle:@"Please enter an email" message:nil];
        return;
    }
    
    Member *member = (Member *)[Member createEntityInContext:_appDelegate.managedObjectContext];
    member.organization = [Organization currentOrganization];
    [member updateEntityWithParams:@{@"name":inputName.text, @"status":@(MemberStatusBeginner), @"email":inputEmail.text}];
    [self notify:@"member:updated"];
    
    [member saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            [_appDelegate.managedObjectContext save:nil];
            [self reset];
            [self saveNewAttendanceForMember:member completion:^(BOOL success, Attendance *attendance) {
                if (!success) {
                    [UIAlertView alertViewWithTitle:@"Could not add to event" message:[NSString stringWithFormat:@"There was an error adding %@ to this event. Please add them manually by editing event attendees.", member.name]];
                }
                else {
                    if (newAttendees == nil) {
                        newAttendees = [NSMutableArray array];
                    }
                    [newAttendees addObject:member];
                    labelAttendanceCount.text = [NSString stringWithFormat:@"New attendees: %d", newAttendees.count];
                    
                    labelWelcome.alpha = 1;
                    labelWelcome.text = [NSString stringWithFormat:@"Welcome, %@", member.name];
                    [UIView animateWithDuration:0.25 delay:2 options:UIViewAnimationOptionCurveLinear animations:^{
                        labelWelcome.alpha = 0;
                    } completion:nil];
                }
            }];
        }
        else {
            NSLog(@"Could not save member!");
            [UIAlertView alertViewWithTitle:@"Save error" message:@"Could not save new member, please try again."];
        }
    }];

}

-(void)saveNewAttendanceForMember:(Member *)member completion:(void(^)(BOOL success, Attendance *attendance))completion{
    NSLog(@"Need to create an attendance for member %@", member.name);
    Attendance *newAttendance = (Attendance *)[Attendance createEntityInContext:_appDelegate.managedObjectContext];
    newAttendance.organization = [Organization currentOrganization];
    newAttendance.practice = self.practice;
    newAttendance.member = member;
    NSNumber *status = @(DidAttend); // attended by default
    if ([member isBeginner]) {
        status = @(DidAttendFreebie);
    }
    [newAttendance updateEntityWithParams:@{@"date":self.practice.date, @"attended":status}];
    [newAttendance saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            [_appDelegate.managedObjectContext save:nil];
            if (completion)
                completion(YES, newAttendance);
        }
        else {
            NSLog(@"Could not save member!");
            if (completion)
                completion(NO, nil);
        }
    }];
}

-(void)reset {
    [self.view endEditing:YES];
    inputEmail.text = nil;
    inputName.text = nil;
    inputAbout.text = nil;
    constraintTopOffset.constant = 0;
}

-(void)goToFeedback {
    if ([MFMailComposeViewController canSendMail]){
        NSString *title = @"RollCall feedback";
        NSString *message = [NSString stringWithFormat:@"\n\nOrganization: %@\nVersion %@", [Organization currentOrganization].name, VERSION];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
