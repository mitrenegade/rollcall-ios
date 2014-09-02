//
//  Member+Info.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Member.h"

typedef  enum MemberStatus {
    MemberStatusInactive = 0,
    MemberStatusBeginner, // member can be a beginner and all their attendances will be marked as freebie.
    MemberStatusActive
} MemberStatus;

@class Payment;
@interface Member (Info)

-(Payment *)latestMonthlyPayment;
-(Payment *)currentMonthlyPayment;
-(Payment *)currentDailyPayment;
-(Payment *)paymentForMonth:(NSDate *)date;

-(int)daysLeftForDailyMember;
-(NSString *)currentPaidMonth;

-(BOOL)isBeginner;
-(BOOL)isInactive;

-(UIColor *)colorForStatusForMonth:(NSDate *)date;
-(NSString *)textForStatusForMonth:(NSDate *)date;

@end
