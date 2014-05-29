//
//  Attendance.h
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ParseBase.h"

@class Member;

@interface Attendance : ParseBase

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Member *member;

@end
