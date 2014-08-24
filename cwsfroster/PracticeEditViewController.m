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

    /*
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = nil;
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done") style:UIBarButtonItemStyleBordered target:self action:@selector(selectDate:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSelectDate:)];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:button2, flex, button1, nil]];
     */

    [inputDate setInputView:pickerView];
    if (self.practice) {
        [inputDate setText:self.practice.title];
    }
    else {
        self.title = @"New practice";
        [inputEmail setHidden:YES];
        [buttonEmail setHidden:YES];
    }
    [inputDetails setText:self.practice.details];
    //inputDate.inputAccessoryView = keyboardDoneButtonView;

    NSString *previousEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"email:to"];
    if (!previousEmail) {
        inputEmail.text = DEFAULT_TO;
    }
    else {
        inputEmail.text = previousEmail;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didClickCancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)didClickSave:(id)sender {
    NSLog(@"Saving");
    if (self.practice) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        if (dateForDateString[inputDate.text]) {
            self.practice.date = dateForDateString[inputDate.text];
            self.practice.title = [Util simpleDateFormat:self.practice.date];
        }
        self.practice.details = inputDetails.text;
        [self.delegate didEditPractice];
        [self.navigationController popViewControllerAnimated:YES];
        [self.practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
            if (!success) {
                [UIAlertView alertViewWithTitle:@"Save error" message:@"Could not save practice!"];
            }
        }];
    }
    else {
        Practice *practice = (Practice *)[Practice createEntityInContext:_appDelegate.managedObjectContext];
        practice.date = dateForDateString[inputDate.text];
        practice.title = [Util simpleDateFormat:practice.date];
        [self.delegate didEditPractice];
        [self.navigationController popViewControllerAnimated:YES];

        [practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
            if (!success) {
                [UIAlertView alertViewWithTitle:@"Save error" message:@"Could not save practice!"];
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        datesForPicker = [NSMutableArray array];
        dateForDateString = [NSMutableDictionary dictionary];
    });

    for (int row = 0; row < 31; row++) {
        NSString * dayString;
        NSString * dateString;

        NSDate * date = [NSDate dateWithTimeIntervalSinceNow:-24*3600*row];

        dayString = [Util weekdayStringFromDate:date localTimeZone:YES]; // use local timezone because date has a timezone on it
        dateString = [Util simpleDateFormat:date];
        NSString *title = [NSString stringWithFormat:@"%@ %@", dayString, dateString];
        [datesForPicker addObject:title];
        dateForDateString[title] = date;
    }
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

#pragma mark TextFieldDelegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == inputEmail) {
        if (inputEmail.text.length > 0) {
            [buttonEmail setEnabled:NO];
        }
        else {
            [buttonEmail setEnabled:YES];
        }
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == inputEmail) {
        if (inputEmail.text.length > 0) {
            [buttonEmail setEnabled:NO];
        }
        else {
            [buttonEmail setEnabled:YES];
        }
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

    [[NSUserDefaults standardUserDefaults] setObject:inputEmail.text forKey:@"email:to"];

    NSString *to = inputEmail.text;
    NSString *title = [NSString stringWithFormat:@"Practice %@ attendance", [Util simpleDateFormat:self.practice.date]];
    NSString *message = [NSString stringWithFormat:@"%@ %@\n%@\n\n", [Util weekdayStringFromDate:self.practice.date localTimeZone:YES], [Util simpleDateFormat:self.practice.date], self.practice.details?self.practice.details:@""];
    for (Attendance *attendance in self.practice.attendances) {
        if ([attendance.attended boolValue]) {
            message = [message stringByAppendingString:attendance.member.name];

            NSString *paymentStatus = @"\n";
            Payment *payment = attendance.payment;
            Member *member = attendance.member;
            if (!payment) {
                if ([member.status intValue] == MemberStatusBeginner) {
                    paymentStatus = @" (beginner))\n";
                }
                else if ([member.status intValue] == MemberStatusInactive) {
                    paymentStatus = @" (inactive status)\n";
                }
                else {
                    paymentStatus = @" (unpaid)\n";
                }
            }
            else if (payment.isMonthly)
                paymentStatus = @" (monthly)\n";
            else if (payment.isDaily)
                paymentStatus = [NSString stringWithFormat:@" (daily - %d left)\n", payment.daysLeft];

            message = [message stringByAppendingString:paymentStatus];
        }
    }
    [SendGridHelper emailTo:to subject:title message:message];
}

@end
