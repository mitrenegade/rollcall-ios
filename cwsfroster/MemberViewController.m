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

        // beginner or inactive are set by user
        if ([self.member.status intValue] == MemberStatusBeginner) {
            [switchBeginner setOn:YES];
            [switchMonthly setOn:NO];
            [switchDaily setOn:NO];
            [switchInactive setOn:NO];
        }
        else if ([self.member.status intValue] == MemberStatusInactive) {
            NSLog(@"Inactive");
            [switchBeginner setOn:NO];
            [switchMonthly setOn:NO];
            [switchDaily setOn:NO];
            [switchInactive setOn:YES];
        }
        else {
            [switchBeginner setOn:NO];
            [switchInactive setOn:NO];

            // determine status using payments
            if ([self.member currentMonthlyPayment]) {
                self.member.status = @(MemberStatusPaid);
            }
            else if ([self.member daysLeftForDailyMember] > 0) {
                self.member.status = @(MemberStatusDaily);
            }
            else {
                self.member.status = @(MemberStatusUnpaid);
            }

            if ([self.member.status intValue] == MemberStatusPaid) {
                [switchMonthly setOn:YES];
            }
            else if ([self.member.status intValue] == MemberStatusDaily) {
                [switchDaily setOn:YES];
            }
        }

        inputName.text = self.member.name;

        self.title = @"Edit";

        if ([switchMonthly isOn] || [switchDaily isOn]) {
            [labelCreditsTitle setAlpha:1];
            [labelCredits setAlpha:1];

            if ([switchMonthly isOn]) {
                labelCreditsTitle.text = @"Active month";
                labelCredits.text = [self.member currentPaidMonth];
            }
            else if ([switchDaily isOn]) {
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

        [labelInactive setHidden:YES];
        [switchInactive setHidden:YES];
    }
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
    [self.delegate cancel];
}

- (IBAction)didClickSave:(id)sender {
    MemberStatus status = MemberStatusUnpaid;

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
        self.member.status = @(MemberStatusUnpaid);
    }

    [self refresh];
}

#pragma mark PaymentViewDelegate
-(void)didAddPayment {
    // member.payment now exists
    NSLog(@"Update member status, credits, and toggle switches here");
    [self refresh];
}
@end
