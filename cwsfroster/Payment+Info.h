//
//  Payment+Info.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/17/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Payment.h"

typedef enum PaymentTypeEnum {
    PaymentTypeUnpaid = 0,
    PaymentTypeMonthly,
    PaymentTypeDaily
} PaymentType;

typedef enum PaymentSourceEnum {
    PaymentSourceNone,
    PaymentSourceVenmo,
    PaymentSourceCash
} PaymentSource;

@interface Payment (Info)

-(BOOL)isMonthly;
-(BOOL)isDaily;
-(BOOL)isCash;
-(BOOL)isVenmo;
@end
