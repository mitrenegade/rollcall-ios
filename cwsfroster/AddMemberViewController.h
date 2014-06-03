//
//  AddMemberViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddMemberDelegate <NSObject>

-(void)cancel;
-(void)saveNewMember:(NSString *)name;

@end
@interface AddMemberViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *inputName;
@property (nonatomic, weak) id delegate;

- (IBAction)didClickBack:(id)sender;
- (IBAction)didClickSave:(id)sender;

@end
