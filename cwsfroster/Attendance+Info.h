//
//  Attendance+Info.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Attendance.h"

typedef enum AttendedStatusEnum {
    DidNotAttend = 0,
    DidAttend = 1,
    DidAttendFreebie = 2
} AttendedStatus;

@interface Attendance (Info)

-(BOOL)isFreebie;
@end
