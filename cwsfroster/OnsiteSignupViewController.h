//
//  OnsiteSignupViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnsiteSignupViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *inputName;
    IBOutlet UITextField *inputEmail;
    IBOutlet UITextField *inputAbout;
    
    UITextField *currentInput;
}

-(IBAction)didClickSignup:(id)sender;

@end
