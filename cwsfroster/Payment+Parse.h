//
//  Payment+Parse.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/15/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Payment.h"
#import "ParseBase+Parse.h"

typedef enum PaymentTypeEnum {
    PaymentTypeUnpaid = 0,
    PaymentTypeMonthly,
    PaymentTypeDaily
} PaymentType;

@interface Payment (Parse) <PFObjectFactory>

@end
