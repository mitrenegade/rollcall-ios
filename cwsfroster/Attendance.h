//
//  Attendance.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Member, Practice;

@interface Attendance : ParseBase

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * attended;
@property (nonatomic, retain) Member *member;
@property (nonatomic, retain) Practice *practice;

@end
