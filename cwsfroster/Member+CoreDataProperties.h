//
//  Member+CoreDataProperties.h
//  cwsfroster
//
//  Created by Bobby Ren on 12/20/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Member.h"

NS_ASSUME_NONNULL_BEGIN

@interface Member (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSNumber *monthPaid;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *notes;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSData *photo;
@property (nullable, nonatomic, retain) NSSet<Attendance *> *attendances;
@property (nullable, nonatomic, retain) Organization *organization;
@property (nullable, nonatomic, retain) NSSet<Payment *> *payments;

@end

@interface Member (CoreDataGeneratedAccessors)

- (void)addAttendancesObject:(Attendance *)value;
- (void)removeAttendancesObject:(Attendance *)value;
- (void)addAttendances:(NSSet<Attendance *> *)values;
- (void)removeAttendances:(NSSet<Attendance *> *)values;

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet<Payment *> *)values;
- (void)removePayments:(NSSet<Payment *> *)values;

@end

NS_ASSUME_NONNULL_END
