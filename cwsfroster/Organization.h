//
//  Organization.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Member, Practice;

@interface Organization : ParseBase

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * logoData;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) Practice *practices;
@end

@interface Organization (CoreDataGeneratedAccessors)

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

@end
