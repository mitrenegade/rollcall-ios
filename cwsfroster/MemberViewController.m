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
        if ([self.member.status intValue] == MemberStatusBeginner) {
            [switchBeginner setOn:YES];
        }
        else if ([self.member.status intValue] == MemberStatusPaid) {
            [switchPaid setOn:YES];
            [switchBeginner setEnabled:NO];
            [switchPass setEnabled:NO];
            [switchInactive setEnabled:NO];
        }
        else if ([self.member.status intValue] == MemberStatusDaily) {
            [switchPass setOn:YES];
            [switchBeginner setEnabled:NO];
            [switchInactive setEnabled:NO];
            [labelCredits setHidden:NO];
            [labelCreditsTitle setHidden:NO];

            [labelCredits setText:[NSString stringWithFormat:@"%d days", [self.member creditsLeftForDailyMember]]];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    }
}

#pragma mark PaymentViewDelegate
-(void)didAddPayment {
    // member.payment now exists
    NSLog(@"Update member status, credits, and toggle switches here");
}
@end
