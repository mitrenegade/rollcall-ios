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

    PFRelation *relation = [self.member.pfObject relationForKey:@"payments"];
    [[relation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] == 0) {
            NSLog(@"None!");
            [self createPaymentOfType:PaymentTypeMonthly completion:^(Payment *payment) {
                NSLog(@"Created a payment!");
                [self.delegate didAddPayment];
            }];
        }
        else {
            NSLog(@"Objects: %lu", (unsigned long)[objects count]);
            // todo: find payments ahead of time and display on the table
        }
    }];
}

-(void)createPaymentOfType:(PaymentType)type completion:(void(^)(Payment *payment))completion {
    Payment *newObj = (Payment *)[Payment createEntityInContext:_appDelegate.managedObjectContext];
    newObj.member = self.member;
    NSDate *startDate = [NSDate date];
    [newObj updateEntityWithParams:@{@"startDate":startDate, @"endDate":[startDate dateByAddingTimeInterval:31*24*3600], @"days":@0, @"amount":@([self.inputAmount.text intValue]), @"type":@(PaymentTypeMonthly)}];
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
