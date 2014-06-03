//
//  MembersTableViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddMemberViewController.h"

@interface MembersTableViewController : UITableViewController <AddMemberDelegate>
{
    NSArray *members;
}
@end
