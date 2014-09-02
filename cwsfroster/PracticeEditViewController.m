//
//  PracticeEditViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticeEditViewController.h"
#import "Practice+Parse.h"
#import "SendGridHelper.h"
#import "Attendance+Info.h"

#import "Member+Info.h"
#import "Payment+Info.h"
#import "MBProgressHUD.h"

#define DEFAULT_TO @"cwsf_instructors@googlegroups.com"

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

    [inputDate setInputView:pickerView];
    if (self.practice) {
        [inputDate setText:[self titleForDate:self.practice.date]];
    }
    else {
        self.title = @"New event date";
        [viewEmail setHidden:YES];
        [viewDrawing setHidden:YES];
    }
    [inputDetails setText:self.practice.details];
    originalDescription = inputDetails.text;

    inputDate.inputAccessoryView = keyboardDoneButtonView;

    NSString *previousEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"email:to"];
    if (!previousEmail) {
        inputEmail.text = DEFAULT_TO;
    }
    else {
        inputEmail.text = previousEmail;
    }

    [self.navigationItem.rightBarButtonItem setEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didClickCancel:(id)sender {
    if (self.navigationController.viewControllers[0] == self)
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)didClickSave:(id)sender {
    NSLog(@"Saving");
    MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeIndeterminate;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    [self.navigationItem.leftBarButtonItem setEnabled:NO];

    if (self.practice) {
        progress.labelText = @"Saving new event date";
        if (dateForDateString[inputDate.text]) {
            self.practice.date = dateForDateString[inputDate.text];
            self.practice.title = [Util simpleDateFormat:self.practice.date];
        }
        self.practice.details = inputDetails.text;
        [self.delegate didEditPractice];
        [self.navigationController popViewControllerAnimated:YES];
        [self.practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            if (!success) {
                progress.mode = MBProgressHUDModeText;
                progress.labelText = @"Save error";
                progress.detailsLabelText = @"Could not save event!";
                [progress hide:YES afterDelay:1.5];
            }
        }];
    }
    else {
        progress.labelText = @"Creating new event";
        if (!dateForDateString[inputDate.text]) {
            // invalid date, or date not selected. shouldn't go here if we disable save
            return;
        }
        Practice *practice = (Practice *)[Practice createEntityInContext:_appDelegate.managedObjectContext];
        practice.organization = [Organization currentOrganization];
        practice.date = dateForDateString[inputDate.text];
        practice.title = [Util simpleDateFormat:practice.date];
        practice.details = inputDetails.text;
        [self.delegate didEditPractice];
        [self.navigationController popViewControllerAnimated:YES];

        [practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            if (!success) {
                progress.mode = MBProgressHUDModeText;
                progress.labelText = @"Save error";
                progress.detailsLabelText = @"Could not save event!";
                [progress hide:YES afterDelay:1.5];

                [_appDelegate.managedObjectContext deleteObject:practice];
            }
            else {
                [_appDelegate.managedObjectContext save:nil];
                [progress hide:YES];
                [self didClickCancel:nil];
            }
        }];
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark Picker DataSource/Delegate
-(void)generatePickerDates {
    if (!datesForPicker) {
        datesForPicker = [NSMutableArray array];
        dateForDateString = [NSMutableDictionary dictionary];
        
        for (int row = 0; row < 31; row++) {
            NSDate * date = [NSDate dateWithTimeIntervalSinceNow:-24*3600*row];
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
    if ([dateString isEqualToString:self.practice.title]) {
        // current practice is allowed to be shown
        return title;
    }
    else {
        NSArray *practices = [[Practice where:@{@"title":dateString}] all];
        if ([practices count])
            return nil;
    }
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
}

-(void)selectDate:(id)sender {
    [inputDate resignFirstResponder];
}

-(void)cancelSelectDate:(id)sender {
    // revert to old date
    inputDate.text = lastInputDate;
    [inputDate resignFirstResponder];
}

#pragma mark TextFieldDelegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == inputDate) {
        lastInputDate = textField.text;

        [self pickerView:(UIPickerView *)textField.inputView didSelectRow:0 inComponent:0];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == inputEmail) {
        if (inputEmail.text.length == 0) {
            [buttonEmail setEnabled:NO];
            [buttonEmail setAlpha:.5];
        }
        else {
            [buttonEmail setEnabled:YES];
            [buttonEmail setAlpha:1];
        }
    }
    else if (textField == inputDate) {
        if (textField.text.length == 0) {
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
        else {
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
    }
    else if (textField == inputDetails) {
        if ([textField.text isEqualToString:originalDescription])
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        else
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    [textField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark emailing
-(IBAction)didClickEmail:(id)sender {
    if (inputEmail.text.length == 0) {
        MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.labelText = @"Please enter a To: email";
        [progress hide:YES afterDelay:1.5];
        return;
    }

    // save any changes. at least sets new details to practice before sending email
    [self didClickSave:nil];

    [[NSUserDefaults standardUserDefaults] setObject:inputEmail.text forKey:@"email:to"];

    NSString *to = inputEmail.text;
    NSString *title = [NSString stringWithFormat:@"Event %@ attendance", [Util simpleDateFormat:self.practice.date]];
    NSString *message = [NSString stringWithFormat:@"%@ %@<br>%@<br><br>", [Util weekdayStringFromDate:self.practice.date localTimeZone:YES], [Util simpleDateFormat:self.practice.date], self.practice.details?self.practice.details:@""];
    for (Attendance *attendance in self.practice.attendances) {
        if ([attendance.attended boolValue]) {
            message = [message stringByAppendingString:attendance.member.name];

            NSString *paymentStatus = @"<br>";
            Payment *payment = attendance.payment;
            Member *member = attendance.member;
            if (!payment) {
                if ([member.status intValue] == MemberStatusBeginner) {
                    paymentStatus = @" (guest))<br>";
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
        }
    }
    [SendGridHelper emailTo:to subject:title message:message];
}

#pragma mark Drawing

-(void)didClickDrawing:(id)sender {
    [UIAlertView alertViewWithTitle:@"Drawing" message:nil];
}
@end
