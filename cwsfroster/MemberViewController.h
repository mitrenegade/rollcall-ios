//
//  MemberViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Member+Info.h"

@protocol MemberDelegate <NSObject>

-(void)cancel;
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status;
-(void)updateMember:(Member *)member;

@end

typedef enum PaymentMode {
    PaymentModeNone,
    PaymentModeVenmo,
    PaymentModeCash
} PaymentMode;
@interface MemberViewController : UIViewController
{
    IBOutlet UITextField *inputName;

    IBOutlet UILabel *labelBeginner;
    IBOutlet UILabel *labelPaid;
    IBOutlet UILabel *labelPass;
    IBOutlet UILabel *labelInactive;

    IBOutlet UISwitch *switchBeginner;
    IBOutlet UISwitch *switchPaid;
    IBOutlet UISwitch *switchPass;
    IBOutlet UISwitch *switchInactive;

    __weak IBOutlet UIView *viewPayments;
    __weak IBOutlet UILabel *labelCredits;
    __weak IBOutlet UITextField *inputPayment;
    __weak IBOutlet UIButton *buttonAddPayment;
    __weak IBOutlet UIButton *buttonVenmo;
    __weak IBOutlet UIButton *buttonCash;

    int paymentMode;
}

@property (nonatomic, assign) Member *member;
@property (nonatomic, weak) id delegate;

- (IBAction)didClickBack:(id)sender;
- (IBAction)didClickSave:(id)sender;
- (IBAction)didClickSwitch:(id)sender;
- (IBAction)didClickAddPayment:(id)sender;
- (IBAction)didClickVenmo:(id)sender;
- (IBAction)didClickCash:(id)sender;
@end
