//
//  MembersTableViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MemberDelegate <NSObject>

-(void)didUpdateMember:(id)member;

@end


@interface MembersTableViewController : UITableViewController <MemberDelegate>
{
}

-(void)reloadMembers;
@end
