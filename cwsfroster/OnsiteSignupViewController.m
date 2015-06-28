//
//  OnsiteSignupViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/27/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

#import "OnsiteSignupViewController.h"

@interface OnsiteSignupViewController ()

@end

@implementation OnsiteSignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextField:)];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = YES;
    keyboardDoneButtonView.tintColor = [UIColor whiteColor];
    [keyboardDoneButtonView sizeToFit];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [keyboardDoneButtonView setItems:@[flex, done]];
    
    [inputName setInputAccessoryView:keyboardDoneButtonView];
    [inputEmail setInputAccessoryView:keyboardDoneButtonView];
    [inputAbout setInputAccessoryView:keyboardDoneButtonView];
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self.navigationController action:@selector(popViewControllerAnimated:)];
    self.navigationItem.leftBarButtonItem = close;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegate
-(void)nextField:(id)sender {
    [self textFieldShouldEndEditing:currentInput];
}
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    currentInput = textField;
}
-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == inputName) {
        [inputEmail becomeFirstResponder];
    }
    else if (textField == inputEmail) {
        [inputAbout becomeFirstResponder];
    }
    return YES;
}

-(void)didClickSignup:(id)sender {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
