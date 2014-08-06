//
//  AddMemberViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Member+Info.h"

@protocol AddMemberDelegate <NSObject>

-(void)cancel;
-(void)saveNewMember:(NSString *)name status:(MemberStatus)status;

@end
@interface AddMemberViewController : UIViewController
{
    IBOutlet UILabel *labelBeginner;
    IBOutlet UILabel *labelPaid;
    IBOutlet UILabel *labelPass;

    IBOutlet UISwitch *switchBeginner;
    IBOutlet UISwitch *switchPaid;
    IBOutlet UISwitch *switchPass;
}
@property (weak, nonatomic) IBOutlet UITextField *inputName;
@property (nonatomic, weak) id delegate;

- (IBAction)didClickBack:(id)sender;
- (IBAction)didClickSave:(id)sender;
- (IBAction)didClickSwitch:(id)sender;
@end
