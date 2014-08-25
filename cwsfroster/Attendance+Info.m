//
//  Attendance+Info.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Attendance+Info.h"

@implementation Attendance (Info)

-(BOOL)isFreebie {
    return [self.attended intValue] == DidAttendFreebie;
}
@end
