//
//  RosterViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 10/1/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Member.h"

typedef void (^AddMemberCallback)(BOOL, Member*);

@class RosterViewController;

@protocol RosterViewDelegate <NSObject>

-(void)rosterView:(RosterViewController*)rosterView getRosterWithBlock:(void(^)(NSArray *, NSError *))gotCurrentRoster;
-(void)rosterView:(RosterViewController*)rosterView addMemberWithBlock:(AddMemberCallback)didAddMember;
-(void)rosterView:(RosterViewController*)rosterView didSelectMember:(Member*)member;
-(void)closeRosterView:(RosterViewController*)rosterView;

-(void)didAddMultipleMembers:(NSMutableArray*)selectedMembers;
@end

@interface RosterViewController : UITableViewController <UINavigationControllerDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSMutableArray * rosterArray;
@property (nonatomic, assign) BOOL bCanAddNewMember;

-(void) refresh;

@end
