//
//  PracticeEditViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticeEditViewController.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "UIAlertView+MKBlockAdditions.h"

#import "AttendancesViewController.h"
#import "OnsiteSignupViewController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIPickerView * pickerView = [[UIPickerView alloc] init];
    [pickerView setDelegate:self];
    [pickerView setDataSource:self];
    [pickerView setShowsSelectionIndicator:YES];

    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done") style:UIBarButtonItemStyleBordered target:self action:@selector(selectDate:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSelectDate:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:button2, flex, button1, nil]];

    if (IS_ABOVE_IOS6) {
        [keyboardDoneButtonView setTintColor:[UIColor whiteColor]];
    }
    
    [self setupTextView];
    [self configureForPractice];
    
    currentRow = -1;

    [inputDate setInputView:pickerView];

    inputDate.inputAccessoryView = keyboardDoneButtonView;
    inputDate.text = [self titleForDate:[NSDate date]];

    emailTo = [[NSUserDefaults standardUserDefaults] objectForKey:@"email:to"];
    if (emailTo) {
        inputTo.text = [NSString stringWithFormat:@"To: %@", emailTo];
    }

    /*
    emailFrom = [[NSUserDefaults standardUserDefaults] objectForKey:@"email:from"];
    if (emailFrom) {
        inputFrom.text = [NSString stringWithFormat:@"From: %@", emailFrom];
    }
    else if (_currentUser.email) {
        emailFrom = _currentUser.email;
        inputFrom.text = [NSString stringWithFormat:@"From: %@", emailFrom];
    }
    */

    rater = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RatingViewController"];
    rater.delegate = self;
}


-(void)didCloseRating {
    // don't need
}

-(void)saveWithCompletion:(void(^)(BOOL success))completion {
    NSLog(@"Saving");
    MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeIndeterminate;
    [self.navigationItem.leftBarButtonItem setEnabled:NO];

    if (self.practice) {
        progress.labelText = @"Saving event date";
        if (dateForDateString[inputDate.text]) {
            self.practice.date = dateForDateString[inputDate.text];
            self.practice.title = [Util simpleDateFormat:self.practice.date];
        }
        self.practice.details = inputDetails.text;
        [self.delegate didEditPractice];
        [self.practice saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            if (!succeeded) {
                progress.mode = MBProgressHUDModeText;
                progress.labelText = @"Save error";
                progress.detailsLabelText = @"Could not save event!";
                [progress hide:YES afterDelay:1.5];
                completion(NO);
            }
            else {
                [progress hide:YES];
                completion(YES);
            }
        }];
    }
    else {
        progress.labelText = @"Creating new event";
        if (!dateForDateString[inputDate.text]) {
            // invalid date, or date not selected. shouldn't go here if we disable save
            progress.mode = MBProgressHUDModeText;
            progress.labelText = @"Please enter a date";
            [progress hide:YES afterDelay:1];
            completion(NO);
            return;
        }
        Practice *practice = [[Practice alloc] init];
        practice.organization = [Organization current];
        practice.date = dateForDateString[inputDate.text];
        practice.title = [Util simpleDateFormat:practice.date];
        practice.details = inputDetails.text;
        
        [practice saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            if (!succeeded) {
                progress.mode = MBProgressHUDModeText;
                progress.labelText = @"Save error";
                progress.detailsLabelText = @"Could not save event!";
                [progress hide:YES afterDelay:1.5];
            }
            else {
                self.practice = practice;
                [progress hide:YES];
                [self.delegate didEditPractice];
                completion(YES);
            }
        }];
    }
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ToEditAttendees"]) {
        AttendanceTableViewController *controller = (AttendanceTableViewController *)segue.destinationViewController;
        [controller setPractice:self.practice];
        [controller setIsNewPractice: self.isNewPractice];
    }
    else if ([segue.identifier isEqualToString:@"ToOnsiteSignup"]) {
        OnsiteSignupViewController *controller = (OnsiteSignupViewController *) segue.destinationViewController;
        [controller setPractice:self.practice];
    }
    else if ([segue.identifier isEqualToString:@"ToEventNotes"]) {
        NotesViewController *controller = (NotesViewController *) segue.destinationViewController;
        [controller setPractice:self.practice];
    }
}

#pragma mark Picker DataSource/Delegate
-(void)generatePickerDates {
    if (!datesForPicker) {
        datesForPicker = [NSMutableArray array];
        dateForDateString = [NSMutableDictionary dictionary];
        
        int futureDays = FUTURE_DAYS; // allow 2 weeks into the future
        for (int row = 31 + futureDays; row > 0; row--) {
            NSDate * date = [NSDate dateWithTimeIntervalSinceNow:-24*3600*(row-futureDays)];
            NSString *title = [self titleForDate:date];
            if (title) {
                [datesForPicker addObject:title];
                dateForDateString[title] = date;
            }
        }
    }
}

-(NSString *)titleForDate:(NSDate *)date {
    NSString *dayString = [Util weekdayStringFromDate:date localTimeZone:YES]; // use local timezone because date has a timezone on it
    NSString *dateString = [Util simpleDateFormat:date];
    NSString *title = [NSString stringWithFormat:@"%@ %@", dayString, dateString];
    NSLog(@"practice: %@", self.practice);
    /*
    if ([dateString isEqualToString:self.practice.title]) {
        // current practice is allowed to be shown
        return title;
    }
    else {
        NSArray *practices = [[[Organization current] practices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"title", dateString]];
        if ([practices count])
            return nil;
    }
     */
    return title;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (!datesForPicker)
        [self generatePickerDates];
    return datesForPicker.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (!datesForPicker)
        [self generatePickerDates];
    return datesForPicker[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString * title = [self pickerView:pickerView titleForRow:row forComponent:component];
    [inputDate setText:title];
    currentRow = row;
}

-(void)selectDate:(id)sender {
    [inputDate resignFirstResponder];
}

-(void)cancelSelectDate:(id)sender {
    // revert to old date
    inputDate.text = lastInputDate;
    [inputDate resignFirstResponder];
}

#pragma mark emailing
-(IBAction)didClickEmail:(id)sender {
    [inputTo resignFirstResponder];
//    [inputFrom resignFirstResponder];
    
    if (inputTo.text.length == 0) {
        MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.labelText = @"Please enter an email recipient";
        [progress hide:YES afterDelay:1.5];
        return;
    }
    /*
    if (inputFrom.text.length == 0) {
        MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.labelText = @"Please enter your email";
        [progress hide:YES afterDelay:1.5];
        return;
    }
    */

    // save any changes. at least sets new details to practice before sending email
    [self saveWithCompletion:^(BOOL success) {
        [[NSUserDefaults standardUserDefaults] setObject:emailTo forKey:@"email:to"];
        [[NSUserDefaults standardUserDefaults] setObject:emailFrom forKey:@"email:from"];
        
        NSString *title = [NSString stringWithFormat:@"Event %@ attendance", [Util simpleDateFormat:self.practice.date]];
        NSString *message = [NSString stringWithFormat:@"%@ %@<br>%@<br><br>", [Util weekdayStringFromDate:self.practice.date localTimeZone:YES], [Util simpleDateFormat:self.practice.date], self.practice.details?self.practice.details:@""];
        for (Attendance *attendance in self.practice.attendances) {
            if ([attendance.attended boolValue]) {
                message = [NSString stringWithFormat:@"%@\n%@ %@ ", message, attendance.member.name, attendance.member.email];
                
                NSString *paymentStatus = @"<br>";
                /*
                Payment *payment = attendance.payment;
                Member *member = attendance.member;
                if (!payment) {
                    if ([member.status intValue] == MemberStatusBeginner) {
                        paymentStatus = @" (guest)<br>";
                    }
                    else if ([member.status intValue] == MemberStatusInactive) {
                        paymentStatus = @" (inactive status)<br>";
                    }
                    else {
                        paymentStatus = @" (unpaid)<br>";
                    }
                }
                else if (payment.isMonthly)
                    paymentStatus = @" (monthly)<br>";
                else if (payment.isDaily)
                    paymentStatus = [NSString stringWithFormat:@" (daily - %d left)<br>", payment.daysLeft];
                
                message = [message stringByAppendingString:paymentStatus];
                 */
            }
        }
        if ([MFMailComposeViewController canSendMail]){
            MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
            composer.mailComposeDelegate = self;
            [composer setSubject:title];
            [composer setMessageBody:message isHTML:YES];
            [composer setToRecipients:@[emailTo]];
            
            [self.navigationController presentViewController:composer animated:YES completion:nil];
            
            [ParseLog logWithTypeString:@"EmailEventDetails" title:nil message:nil params:nil error:nil];
        }
        else {
            [UIAlertView alertViewWithTitle:@"Currently unable to send email" message:@"Please make sure email is available"];
        }
    }];
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
            [UIAlertView alertViewWithTitle:[NSString stringWithFormat:@"Attendance for %@ sent",[Util simpleDateFormat:self.practice.date]] message:nil cancelButtonTitle:@"OK"];
            break;
        case MFMailComposeResultFailed:
            //feedbackMsg.text = @"Result: Mail sending failed";
            [UIAlertView alertViewWithTitle:@"There was an error sending the attendance list" message:nil];
            break;
        default:
            //feedbackMsg.text = @"Result: Mail not sent";
            break;
    }
    // dismiss the composer
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}


#pragma mark Drawing

-(void)didClickDrawing:(id)sender {
    NSString *title = @"Random drawing";
    NSString *message = @"Click to select one attendee at random";
    NSMutableArray *attendees = [[[[Organization current] attendances] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K != 0", @"attended"]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"practice = %@", self.practice.objectId]]; //[[Practice where:@{@"title":dateString}] all];
    for (Attendance *a in attendees) {
        NSLog(@"Attendance %@, attended %@", a, a.attended);
    }

    [self doDrawingFromAttendees:attendees title:title message:message];
}

-(void)doDrawingFromAttendees:(NSMutableArray *)attendees title:(NSString *)title message:(NSString *)message {
    NSArray *buttons = nil;
    if ([attendees count] > 0) {
        buttons = @[@"Pick a name and replace it", @"Pick a name without replacing it"];
    }
    else {
        message = @"No more attendees left to select from.";
    }
    [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Close" otherButtonTitles:buttons onDismiss:^(int buttonIndex) {
        NSLog(@"Index %d", buttonIndex);
        int index = arc4random() % [attendees count];
        Attendance *attendance = (Attendance *)(attendees[index]);
        NSString *title = attendance.member.name;
        NSString *newMessage = message;
        if (buttonIndex == 0) {
            [self doDrawingFromAttendees:attendees title:title message:newMessage];
        }
        else if (buttonIndex == 1) {
            [attendees removeObject:attendance];
            if ([attendees count] == 0) {
                newMessage = @"No more attendees left to select from.";
            }
            [self doDrawingFromAttendees:attendees title:title message:newMessage];
        }

    } onCancel:nil];
}

#pragma mark attendees
-(IBAction)didClickAttendees:(id)sender {
    if (self.practice) {
        [self performSegueWithIdentifier:@"ToEditAttendees" sender:nil];
    }
    else {
        NSLog(@"No practice exists, creating one");
        [self saveWithCompletion:^(BOOL success) {
            if (success) {
                self.navigationItem.leftBarButtonItem.title = @"Close";
                [self performSegueWithIdentifier:@"ToEditAttendees" sender:nil];
            }
        }];
    }
}

#pragma mark Onsite signup
-(IBAction)didClickOnsiteSignup:(id)sender {
    if (self.practice) {
        [self performSegueWithIdentifier:@"ToOnsiteSignup" sender:nil];
    }
    else {
        NSLog(@"No practice exists, creating one");
        [self saveWithCompletion:^(BOOL success) {
            if (success) {
                self.navigationItem.leftBarButtonItem.title = @"Close";
                [self performSegueWithIdentifier:@"ToOnsiteSignup" sender:nil];
            }
        }];
    }
}

#pragma mark Event info
-(IBAction)didClickEventNotes:(id)sender {
    if (self.practice) {
        [self performSegueWithIdentifier:@"ToEventNotes" sender:nil];
    }
    else {
        NSLog(@"No practice exists, creating one");
        [self saveWithCompletion:^(BOOL success) {
            if (success) {
                self.navigationItem.leftBarButtonItem.title = @"Close";
                [self performSegueWithIdentifier:@"ToEventNotes" sender:nil];
            }
        }];
    }
}
@end
