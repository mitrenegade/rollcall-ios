//
//  Member.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"


@interface Member : ParseBase

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * monthPaid;
@property (nonatomic, retain) NSSet *attendances;
@property (nonatomic, retain) NSSet *payments;
@end

@interface Member (CoreDataGeneratedAccessors)

- (void)addAttendancesObject:(NSManagedObject *)value;
- (void)removeAttendancesObject:(NSManagedObject *)value;
- (void)addAttendances:(NSSet *)values;
- (void)removeAttendances:(NSSet *)values;

- (void)addPaymentsObject:(NSManagedObject *)value;
- (void)removePaymentsObject:(NSManagedObject *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

@end
