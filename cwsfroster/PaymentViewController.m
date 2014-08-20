//
//  PaymentViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "PaymentViewController.h"
#import "Member+Info.h"
#import "Member+Parse.h"
#import "Payment+Parse.h"
#import "Payment+Info.h"
#import "ParseBase+Parse.h"

@interface PaymentViewController ()

@end

@implementation PaymentViewController

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
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(didClickAddPayment:)];
    self.navigationItem.rightBarButtonItem = right;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

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

    [self generatePickerDates];

    [self.inputDate setInputView:pickerView];
    [self.inputDate setText:[self pickerView:pickerView titleForRow:0 forComponent:0]];
    selectedDate = dateForDateString[self.inputDate.text];

    self.inputDate.inputAccessoryView = keyboardDoneButtonView;

    if ([[self.paymentsFetcher fetchedObjects] count] == 0) {
        // make a update just in case
        PFQuery *query = [PFQuery queryWithClassName:@"Payment"];
        if (self.member.pfObject)
            [query whereKey:@"member" equalTo:self.member.pfObject]; // sometimes member has not synced with the database? prevent crash
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [ParseBase synchronizeClass:@"Payment" fromObjects:objects replaceExisting:NO completion:^{
                [self refresh];
            }];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void) refresh {
    NSError *error;
    [self.paymentsFetcher performFetch:&error];
    [self.tableView reloadData];
}

- (IBAction)didClickButton:(id)sender {
    // payment source
    if (sender == self.buttonVenmo) {
        [self.buttonVenmo setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
        [self.buttonCash setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
        paymentSource = PaymentSourceVenmo;
    }
    else if (sender == self.buttonCash) {
        [self.buttonVenmo setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
        [self.buttonCash setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
        paymentSource = PaymentSourceCash;
    }

    // payment type
    if (sender == self.buttonMonthly) {
        [self.buttonDaily setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
        [self.buttonMonthly setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
        paymentType = PaymentTypeMonthly;
    }
    else if (sender == self.buttonDaily) {
        [self.buttonMonthly setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
        [self.buttonDaily setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
        paymentType = PaymentTypeDaily;
    }
}

- (IBAction)didClickAddPayment:(id)sender {
    if ([self.inputAmount.text length] == 0) {
        return;
    }
    if (paymentType == PaymentTypeUnpaid) {
        [UIAlertView alertViewWithTitle:@"Please select a payment type" message:nil];
        return;
    }
    if (paymentSource == PaymentSourceNone) {
        [UIAlertView alertViewWithTitle:@"Please select a payment source" message:nil];
        return;
    }

    PFRelation *relation = [self.member.pfObject relationForKey:@"payments"];
    [[relation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] == 0) {
            NSLog(@"None!");
            [self createPaymentOfType:paymentType completion:^(Payment *payment) {
                NSLog(@"Created a payment!");
                [self.delegate didAddPayment];
                [self refresh];
            }];
        }
        else {
            NSLog(@"Objects: %lu", (unsigned long)[objects count]);
            // todo: prevent multiple payments for a month
        }

        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.inputDate resignFirstResponder];
        [self.inputAmount resignFirstResponder];
    }];
}

-(void)createPaymentOfType:(PaymentType)type completion:(void(^)(Payment *payment))completion {
    Payment *newObj = (Payment *)[Payment createEntityInContext:_appDelegate.managedObjectContext];
    newObj.member = self.member;
    NSDate *startDate = dateForDateString[self.inputDate.text];
    if (!startDate) {
        [UIAlertView alertViewWithTitle:@"Invalid date!" message:[NSString stringWithFormat:@"Error: selected date %@ had no valid date", self.inputDate.text]];
        return;
    }
    if (type == PaymentTypeMonthly) {
        [newObj updateEntityWithParams:@{@"startDate":startDate, @"endDate":[Util endOfMonthForDate:startDate localTimeZone:YES], @"days":@0, @"amount":@([self.inputAmount.text intValue]), @"type":@(PaymentTypeMonthly)}];
    }
    else if (type == PaymentTypeDaily) {
        [newObj updateEntityWithParams:@{@"startDate":startDate, @"days":@5, @"amount":@([self.inputAmount.text intValue]), @"type":@(PaymentTypeDaily)}];
    }
    [newObj saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (success) {
            NSError *error;
            [_appDelegate.managedObjectContext save:&error];
            if (completion)
                completion(newObj);
        }
        else {
            NSLog(@"Could not save member!");
            if (completion)
                completion(nil);
        }
    }];
}

#pragma mark TableViewDatasource
-(NSFetchedResultsController *)paymentsFetcher {
    if (paymentsFetcher) {
        return paymentsFetcher;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Payment"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"member.parseID = %@", self.member.parseID]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"type" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor, sortDescriptor2]];
    paymentsFetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_appDelegate.managedObjectContext sectionNameKeyPath:@"type" cacheName:nil];
    NSError *error;
    [paymentsFetcher performFetch:&error];

    return paymentsFetcher;

}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // possibly return 2
    return [[self.paymentsFetcher sections] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSNumber *sectionTitle = self.paymentsFetcher.sectionIndexTitles[section];
    if ([sectionTitle intValue] == PaymentTypeDaily)
        return @"Day to day pass";
    else if ([sectionTitle intValue] == PaymentTypeMonthly)
        return @"Monthly payment";
    return @"";
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.paymentsFetcher.sections objectAtIndex:section];
    NSString *title = [sectionInfo indexTitle];
    NSString *name = [sectionInfo name];
    NSArray *objects = [sectionInfo objects];
    NSLog(@"Section title %@ name %@ count %lu", title, name, (unsigned long)[objects count]);
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PaymentCell" forIndexPath:indexPath];

    // Configure the cell...
    Payment *payment = (Payment*)[self.paymentsFetcher objectAtIndexPath:indexPath];
    UILabel *labelTitle = (UILabel *)[cell viewWithTag:1];
    UILabel *labelAmount = (UILabel *)[cell viewWithTag:2];
    UILabel *labelInfo = (UILabel *)[cell viewWithTag:3];
    NSString *title, *info, *source = @"";
    title = [NSString stringWithFormat:@"%@", [Util simpleDateFormat:payment.startDate]];
    if ([payment isMonthly]) {
        info = [Util shortMonthForDate:payment.startDate];
        labelInfo.textColor = [UIColor greenColor];
    }
    else if ([payment isDaily]) {
        info = [NSString stringWithFormat:@"%dd left", [payment daysLeft]]; // todo: calculate based on attendances instead
        labelInfo.textColor = [UIColor blueColor];
    }

    if ([payment.source intValue] == PaymentSourceCash) {
        source = @"(cash)";
    }
    else if ([payment.source intValue] == PaymentSourceVenmo) {
        source = @"(venmo)";
    }
    labelTitle.text = title;
    labelAmount.text = [NSString stringWithFormat:@"$%3.2f %@", [payment.amount floatValue], source];
    labelInfo.text = info;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

#pragma mark textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.inputAmount)
        lastDateString = self.inputDate.text;

    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}
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
    [self.inputDate setText:title];
}

-(void)selectDate:(id)sender {
    selectedDate = dateForDateString[self.inputDate.text];
    [self.inputDate resignFirstResponder];
}

-(void)cancelSelectDate:(id)sender {
    self.inputDate.text = lastDateString;
    [self.inputDate resignFirstResponder];
}
@end