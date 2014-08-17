//
//  MemberViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "MemberViewController.h"
#import "Member+Info.h"
#import "Member+Parse.h"
#import "Payment+Parse.h"

@interface MemberViewController ()

@end

@implementation MemberViewController

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
    if (self.member) {
        if ([self.member.status intValue] == MemberStatusPaid) {
            [switchPaid setOn:YES];
        }
        else if ([self.member.status intValue] == MemberStatusDaily) {
            [switchPass setOn:YES];
        }
        else if ([self.member.status intValue] == MemberStatusBeginner) {
            [switchBeginner setOn:YES];
        }

        inputName.text = self.member.name;

        [labelInactive setHidden:NO];
        [switchInactive setHidden:NO];

        self.title = @"Edit";
    }
    else {
        self.title = @"Add member";

        [labelInactive setHidden:YES];
        [switchInactive setHidden:YES];
    }

    [viewPayments setHidden:!([self.member.status intValue] == MemberStatusDaily)];
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

- (IBAction)didClickBack:(id)sender {
    [self.delegate cancel];
}

- (IBAction)didClickSave:(id)sender {
    MemberStatus status = MemberStatusUnpaid;

    if ([switchBeginner isOn])
        status = MemberStatusBeginner;
    else if ([switchPass isOn])
        status = MemberStatusDaily;
    else if ([switchPaid isOn])
        status = MemberStatusPaid;

    if (self.member) {
        if ([switchInactive isOn])
            status = MemberStatusInactive;

        self.member.name = inputName.text;
        self.member.status = @(status);
        [self.delegate updateMember:self.member];
    }
    else {
        if ([inputName.text length] > 0)
            [self.delegate saveNewMember:inputName.text status:status];
    }
}

-(IBAction)didClickSwitch:(id)sender {
    BOOL selected = [(UISwitch *)sender isOn];
    if (selected) {
        [switchBeginner setOn:!selected];
        [switchPaid setOn:!selected];
        [switchPass setOn:!selected];
        [switchInactive setOn:!selected];

        [(UISwitch *)sender setOn:selected];

        if (sender == switchInactive) {
            [switchBeginner setEnabled:NO];
            [switchPaid setEnabled:NO];
            [switchPass setEnabled:NO];
        }
    }
    else {
        if (sender == switchInactive) {
            [switchBeginner setEnabled:YES];
            [switchPaid setEnabled:YES];
            [switchPass setEnabled:YES];
        }
    }

    if (sender == switchPass) {
        [viewPayments setHidden:!selected];
    }
}

- (IBAction)didClickAddPayment:(id)sender {
    if ([inputPayment.text length] == 0) {
        return;
    }

    PFRelation *relation = [self.member.pfObject relationForKey:@"payments"];
    [[relation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] == 0) {
            NSLog(@"None!");
            [self createPaymentOfType:PaymentTypeMonthly completion:^(Payment *payment) {
                NSLog(@"Created a payment!");
            }];
        }
        else {
            NSLog(@"Objects: %lu", [objects count]);
        }
    }];
}

- (IBAction)didClickVenmo:(id)sender {
    [buttonVenmo setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
    [buttonCash setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
    paymentMode = PaymentModeVenmo;
}

- (IBAction)didClickCash:(id)sender {
    [buttonVenmo setImage:[UIImage imageNamed:@"employer_unchecked"] forState:UIControlStateNormal];
    [buttonCash setImage:[UIImage imageNamed:@"employer_check"] forState:UIControlStateNormal];
    paymentMode = PaymentModeCash;
}

-(void)createPaymentOfType:(PaymentType)type completion:(void(^)(Payment *payment))completion {
    Payment *newObj = (Payment *)[Payment createEntityInContext:_appDelegate.managedObjectContext];
    newObj.member = self.member;
    NSDate *startDate = [NSDate date];
    [newObj updateEntityWithParams:@{@"startDate":startDate, @"endDate":[startDate dateByAddingTimeInterval:31*24*3600], @"days":@0, @"amount":@60, @"type":@(PaymentTypeMonthly)}];
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
@end
