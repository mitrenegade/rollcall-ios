//
//  Payment.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Attendance, Member;

@interface Payment : ParseBase

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * days;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) Member *member;
@property (nonatomic, retain) Attendance *attendances;

@end
