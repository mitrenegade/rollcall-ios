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

@end
