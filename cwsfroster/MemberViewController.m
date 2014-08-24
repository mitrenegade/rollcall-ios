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
#import "PaymentViewController.h"
#import "Attendance+Parse.h"
#import "Attendance+Info.h"

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

    // load stuff needed to calculate payment status

    // todo: make a call for member that returns both attendances and payments

    originalStatus = self.member.status;

    PFQuery *query = [PFQuery queryWithClassName:@"Attendance"];
    NSDictionary *scope = @{};
    if (self.member.pfObject) {
        [query whereKey:@"member" equalTo:self.member.pfObject];
        scope = @{@"member.parseID":self.member.parseID};
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [ParseBase synchronizeClass:@"Attendance" fromObjects:objects replaceExisting:YES scope:scope completion:^{
            [self refresh];
        }];
    }];

    PFQuery *query2 = [PFQuery queryWithClassName:@"Payment"];
    NSDictionary *scope2 = @{};
    if (self.member.pfObject) {
        [query2 whereKey:@"member" equalTo:self.member.pfObject];
        scope2 = @{@"member.parseID":self.member.parseID};
    }
    [query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [ParseBase synchronizeClass:@"Payment" fromObjects:objects replaceExisting:YES scope:scope completion:^{
            [self refresh];
        }];
    }];

    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh {
    // calculate state from payments and attendances
    if (self.member) {
        BOOL unpaid = NO;
        BOOL monthly = NO;

        // beginner or inactive are set by user
        [iconMonthly setAlpha:.5];
        [iconDaily setAlpha:.5];
        [labelPaymentWarning setHidden:YES];

        if ([self.member.status intValue] == MemberStatusBeginner) {
            [switchBeginner setOn:YES];
            [switchInactive setOn:NO];

            [iconMonthly setImage:[UIImage imageNamed:@"employer_unchecked"]];
            [iconDaily setImage:[UIImage imageNamed:@"employer_unchecked"]];
        }
        else if ([self.member.status intValue] == MemberStatusInactive) {
            NSLog(@"Inactive");
            [switchBeginner setOn:NO];
            [switchInactive setOn:YES];

            [iconMonthly setImage:[UIImage imageNamed:@"employer_unchecked"]];
            [iconDaily setImage:[UIImage imageNamed:@"employer_unchecked"]];
        }
        else {
            [switchBeginner setOn:NO];
            [switchInactive setOn:NO];
            [iconMonthly setAlpha:1];
            [iconDaily setAlpha:1];

            // determine status using payments
            if ([self.member currentMonthlyPayment]) {
                monthly = YES;
                unpaid = NO;
            }
            else if ([self.member daysLeftForDailyMember] > 0) {
                monthly = NO;
                unpaid = NO;
            }
            else {
                monthly = NO;
                unpaid = YES;
            }

            if (monthly) {
                [iconMonthly setImage:[UIImage imageNamed:@"employer_check"]];
                [iconDaily setImage:[UIImage imageNamed:@"employer_unchecked"]];
            }
            else if (!unpaid) {
                [iconMonthly setImage:[UIImage imageNamed:@"employer_unchecked"]];
                [iconDaily setImage:[UIImage imageNamed:@"employer_check"]];
            }
            else {
                // not beginner or inactive, but no payment
                [iconMonthly setImage:[UIImage imageNamed:@"employer_unchecked"]];
                [iconDaily setImage:[UIImage imageNamed:@"employer_unchecked"]];
                [labelPaymentWarning setHidden:NO];
            }
        }

        inputName.text = self.member.name;

        self.title = @"Edit";

        if (!unpaid) {
            [labelCreditsTitle setAlpha:1];
            [labelCredits setAlpha:1];

            if (monthly) {
                labelCreditsTitle.text = @"Active month";
                labelCredits.text = [self.member currentPaidMonth];
            }
            else {
                labelCreditsTitle.text = @"Day credits";
                labelCredits.text = [NSString stringWithFormat:@"%d", [self.member daysLeftForDailyMember]];
            }
        }
        else {
            [labelCredits setAlpha:.25];
            [labelCreditsTitle setAlpha:.25];
        }
    }
    else {
        self.title = @"Add member";
    }

    if (changed)
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    else
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    PaymentViewController *controller = (PaymentViewController *)[segue destinationViewController];
    [controller setMember:self.member];
    [controller setDelegate:self];
}

- (IBAction)didClickBack:(id)sender {
    if (changed) {
        [UIAlertView alertViewWithTitle:@"Save changed?" message:@"You've edited the user. Do you want to save the changes?" cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Don't Save"] onDismiss:^(int buttonIndex) {
            self.member.status = @(originalStatus);
            [self.delegate cancel];
        } onCancel:nil];
    }
    else {
        [self.delegate cancel];
    }
}

- (IBAction)didClickSave:(id)sender {
    MemberStatus status = MemberStatusActive;

    if ([switchBeginner isOn])
        status = MemberStatusBeginner;

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
    changed = YES;

    BOOL selected = [(UISwitch *)sender isOn];
    if (selected) {
        [switchBeginner setOn:!selected];
        [switchInactive setOn:!selected];

        [(UISwitch *)sender setOn:selected];

        if (sender == switchBeginner) {
            self.member.status = @(MemberStatusBeginner);
        }
        else if (sender == switchInactive) {
            self.member.status = @(MemberStatusInactive);
        }
    }
    else {
        // member is no longer a beginner or inactive...let refresh select status
        self.member.status = @(MemberStatusActive);
    }

    [self refresh];
}

#pragma mark PaymentViewDelegate
-(void)didAddPayment {
    // member.payment now exists
    NSLog(@"Update member status, credits, and toggle switches here");
    [self.navigationController popViewControllerAnimated:YES];
    [self refresh];
}
@end
