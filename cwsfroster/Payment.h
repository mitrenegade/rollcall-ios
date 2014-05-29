//
//  Payment.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Member;

@interface Payment : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) Member *member;

@end
