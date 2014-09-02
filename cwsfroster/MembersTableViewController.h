//
//  MembersTableViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MemberViewController.h"

@interface MembersTableViewController : UITableViewController <MemberDelegate>
{
    NSFetchedResultsController *memberFetcher;
}

- (IBAction)didTapAccessory:(id)sender event:(id)event;

@end
