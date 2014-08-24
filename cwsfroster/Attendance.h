//
//  Attendance.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/24/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Member, Payment, Practice;

@interface Attendance : ParseBase

@property (nonatomic, retain) NSNumber * attended;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Member *member;
@property (nonatomic, retain) Payment *payment;
@property (nonatomic, retain) Practice *practice;

@end
