//
//  PracticesTableViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PracticesTableViewController : UITableViewController
{
    NSArray *practices;
}

-(IBAction)didClickNew:(id)sender;
@end