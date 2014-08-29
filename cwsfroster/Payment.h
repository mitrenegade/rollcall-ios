//
//  Payment.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Attendance, Member, Organization;

@interface Payment : ParseBase

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSNumber * days;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * receiptDate;
@property (nonatomic, retain) NSNumber * source;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *attendances;
@property (nonatomic, retain) Member *member;
@property (nonatomic, retain) Organization *organization;
@end

@interface Payment (CoreDataGeneratedAccessors)

- (void)addAttendancesObject:(Attendance *)value;
- (void)removeAttendancesObject:(Attendance *)value;
- (void)addAttendances:(NSSet *)values;
- (void)removeAttendances:(NSSet *)values;

@end
