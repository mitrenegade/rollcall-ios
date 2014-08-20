//
//  PaymentViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Payment+Info.h"

@protocol PaymentViewDelegate <NSObject>

-(void)didAddPayment;

@end

static NSMutableDictionary *dateForDateString;
static NSMutableArray *datesForPicker; // at most 14, but not before the user's creation date

@class Member;
@interface PaymentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
{
    PaymentType paymentType;
    PaymentSource paymentSource;

    NSFetchedResultsController *paymentsFetcher;

    NSDate *selectedDate;
    NSString *lastDateString;
}

@property (nonatomic) Member *member;
@property (nonatomic, weak) id delegate;

@property (weak, nonatomic) IBOutlet UITextField *inputAmount;
@property (weak, nonatomic) IBOutlet UIButton *buttonVenmo;
@property (weak, nonatomic) IBOutlet UIButton *buttonCash;
@property (weak, nonatomic) IBOutlet UIButton *buttonMonthly;
@property (weak, nonatomic) IBOutlet UIButton *buttonDaily;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UITextField *inputDate;

- (IBAction)didClickButton:(id)sender;

@end
