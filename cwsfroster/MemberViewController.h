//
//  MemberViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Member+Info.h"
#import "PaymentViewController.h"

@protocol MemberDelegate <NSObject>

-(void)cancel;
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status;
-(void)updateMember:(Member *)member;

@end

@interface MemberViewController : UIViewController <PaymentViewDelegate>
{
    IBOutlet UITextField *inputName;

    IBOutlet UILabel *labelBeginner;
    IBOutlet UILabel *labelInactive;

    IBOutlet UISwitch *switchBeginner;
    IBOutlet UISwitch *switchInactive;

    IBOutlet UIImageView *iconMonthly;
    IBOutlet UIImageView *iconDaily;

    IBOutlet UILabel *labelPaymentWarning;

    __weak IBOutlet UILabel *labelCreditsTitle;
    __weak IBOutlet UILabel *labelCredits;
    __weak IBOutlet UIButton *buttonAddPayment;

    NSArray *payments;
    NSArray *attendances;
}

@property (nonatomic, assign) Member *member;
@property (nonatomic, weak) id delegate;

- (IBAction)didClickBack:(id)sender;
- (IBAction)didClickSave:(id)sender;
- (IBAction)didClickSwitch:(id)sender;
- (IBAction)didClickAddPayment:(id)sender;
@end
