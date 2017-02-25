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
    self.inputDate.inputView = pickerView;
    self.inputDate.inputAccessoryView = keyboardDoneButtonView;
    
    [self setupTextView];
    [self configureForPractice];
    
    self.currentRow = -1;
    [self generatePickerDates];
    
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

    self.rater = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RatingViewController"];
    self.rater.delegate = self;
}


-(void)didCloseRating {
    // don't need
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
        controller.delegate = self.delegate;
    }
    else if ([segue.identifier isEqualToString:@"ToOnsiteSignup"]) {
        OnsiteSignupViewController *controller = (OnsiteSignupViewController *) segue.destinationViewController;
        [controller setPractice:self.practice];
    }
    else if ([segue.identifier isEqualToString:@"ToEventNotes"]) {
        NotesViewController *controller = (NotesViewController *) segue.destinationViewController;
        [controller setPractice:self.practice];
    }
    else if ([segue.identifier isEqualToString:@"ToRandomDrawing"]) {
        RandomDrawingViewController *controller = (RandomDrawingViewController *) segue.destinationViewController;
        [controller setPractice:self.practice];
    }
}

#pragma mark Picker DataSource/Delegate
-(void)generatePickerDates {
    if (!self.datesForPicker) {
        self.datesForPicker = [NSMutableArray array];
        self.dateForDateString = [NSMutableDictionary dictionary];
        
        int futureDays = FUTURE_DAYS; // allow 2 weeks into the future
        for (int row = 31 + futureDays; row > 0; row--) {
            NSDate * date = [NSDate dateWithTimeIntervalSinceNow:-24*3600*(row-futureDays)];
            NSString *title = [self titleForDate:date];
            if (title) {
                [self.datesForPicker addObject:title];
                self.dateForDateString[title] = date;
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
    if (!self.datesForPicker)
        [self generatePickerDates];
    return self.datesForPicker.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (!self.datesForPicker)
        [self generatePickerDates];
    return self.datesForPicker[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString * title = [self pickerView:pickerView titleForRow:row forComponent:component];
    [self.inputDate setText:title];
    self.currentRow = row;
}

-(void)selectDate:(id)sender {
    [self.inputDate resignFirstResponder];
}

-(void)cancelSelectDate:(id)sender {
    // revert to old date
    self.inputDate.text = self.lastInputDate;
    [self.inputDate resignFirstResponder];
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

#pragma mark attendees
-(IBAction)didClickAttendees:(id)sender {
    if (self.practice) {
        [self performSegueWithIdentifier:@"ToEditAttendees" sender:nil];
    }
}

#pragma mark Onsite signup
-(IBAction)didClickOnsiteSignup:(id)sender {
    if (self.practice) {
        [self performSegueWithIdentifier:@"ToOnsiteSignup" sender:nil];
    }
    else {
        NSLog(@"No practice exists, creating one");
        /*
        [self saveWithCompletion:^(BOOL success) {
            if (success) {
                self.navigationItem.leftBarButtonItem.title = @"Close";
                [self performSegueWithIdentifier:@"ToOnsiteSignup" sender:nil];
            }
        }];
         */
    }
}

#pragma mark date utils
-(NSDate*)dateOnly:(NSDate *)date {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    
    comps.hour = 0;
    comps.minute = 0;
    comps.second = 0;
    
    NSDate *newDate = [cal dateFromComponents:comps ];
    return newDate;
}
@end
