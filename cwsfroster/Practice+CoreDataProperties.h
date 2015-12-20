//
//  Practice+CoreDataProperties.h
//  cwsfroster
//
//  Created by Bobby Ren on 12/19/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Practice.h"

NS_ASSUME_NONNULL_BEGIN

@interface Practice (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *notes;
@property (nullable, nonatomic, retain) NSSet<Attendance *> *attendances;
@property (nullable, nonatomic, retain) Organization *organization;

@end

@interface Practice (CoreDataGeneratedAccessors)

- (void)addAttendancesObject:(Attendance *)value;
- (void)removeAttendancesObject:(Attendance *)value;
- (void)addAttendances:(NSSet<Attendance *> *)values;
- (void)removeAttendances:(NSSet<Attendance *> *)values;

@end

NS_ASSUME_NONNULL_END
