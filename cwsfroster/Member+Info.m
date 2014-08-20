//
//  Member+Info.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/6/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Member+Info.h"
#import "Payment+Info.h"
#import "Attendance+Info.h"

@implementation Member (Info)

-(int)daysLeftForDailyMember {
    return [[self currentDailyPayment] daysLeft];
}

-(NSString *)currentPaidMonth {
    return [Util shortMonthForDate:[[self latestMonthlyPayment] startDate]];
}

-(Payment *)latestMonthlyPayment {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@", @(PaymentTypeMonthly)];
    NSArray *monthlyPayments = [[[self.payments allObjects] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[descriptor]];
    if ([monthlyPayments count])
        return monthlyPayments[0];
    return nil;
}

-(Payment *)currentMonthlyPayment {
    Payment *p = [self latestMonthlyPayment];
    if ([p.startDate timeIntervalSinceNow] && [[Util shortMonthForDate:p.startDate] isEqualToString:[Util shortMonthForDate:[NSDate date]]]) {
        return p;
    }
    return nil;
}

-(Payment *)currentDailyPayment {
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@", @(PaymentTypeDaily)];
    NSArray *dailyPayments = [[[self.payments allObjects] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[descriptor]];
    for (int i=0; i<dailyPayments.count; i++) {
        Payment *p = dailyPayments[i];
        if ([p daysLeft] > 0)
            return p;
    }
    return nil;
}
@end