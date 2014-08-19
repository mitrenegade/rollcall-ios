//
//  Payment+Info.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Payment+Info.h"

@implementation Payment (Info)

-(BOOL)isMonthly {
    return [self.type intValue] == PaymentTypeMonthly;
}

-(BOOL)isDaily {
    return [self.type intValue] == PaymentTypeDaily;
}

-(BOOL)isCash {
    return [self.source integerValue] == PaymentSourceCash;
}

-(BOOL)isVenmo {
    return [self.source integerValue] == PaymentSourceVenmo;
}

-(int)daysLeft {
    return [self.days intValue] - (int)[self.attendances count];
    // todo: associate days with payments. if a monthly payment is created, associate all monthly attendances for that month to that payment. assign individual attendances for a non-monthly month with any days? 
}
@end
