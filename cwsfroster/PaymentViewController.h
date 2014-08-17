//
//  PaymentViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Payment+Parse.h"

@protocol PaymentViewDelegate <NSObject>

-(void)didAddPayment;

@end


@class Member;
@interface PaymentViewController : UIViewController
{
    PaymentType paymentType;
    PaymentSource paymentSource;
}

@property (nonatomic) Member *member;
@property (nonatomic, weak) id delegate;

@property (weak, nonatomic) IBOutlet UITextField *inputAmount;
@property (weak, nonatomic) IBOutlet UIButton *buttonVenmo;
@property (weak, nonatomic) IBOutlet UIButton *buttonCash;
@property (weak, nonatomic) IBOutlet UIButton *buttonMonthly;
@property (weak, nonatomic) IBOutlet UIButton *buttonDaily;
- (IBAction)didClickButton:(id)sender;

@end
