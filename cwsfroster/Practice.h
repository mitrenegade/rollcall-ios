//
//  Practice.h
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Attendance;

@interface Practice : ParseBase

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *attendences;
@end

@interface Practice (CoreDataGeneratedAccessors)

- (void)addAttendencesObject:(Attendance *)value;
- (void)removeAttendencesObject:(Attendance *)value;
- (void)addAttendences:(NSSet *)values;
- (void)removeAttendences:(NSSet *)values;

@end
