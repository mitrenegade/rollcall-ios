//
//  PracticeEditViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/12/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PracticeEditViewController.h"
#import "Practice+Parse.h"

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
    [inputDate setText:self.practice.title];

    [inputDetails setText:self.practice.details];
    //inputDate.inputAccessoryView = keyboardDoneButtonView;

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
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    [self.navigationItem.leftBarButtonItem setEnabled:NO];
    if (dateForDateString[inputDate.text]) {
        self.practice.date = dateForDateString[inputDate.text];
        self.practice.title = [Util simpleDateFormat:self.practice.date];
    }
    self.practice.details = inputDetails.text;
    [self.practice saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            [self.delegate didEditPractice];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [UIAlertView alertViewWithTitle:@"Save error" message:@"Could not save practice!"];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
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

@end
