//
//  SendGridHelper.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/19/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SendGrid/SendGrid.h>
#import <SendGrid/SendGridEmail.h>

@interface SendGridHelper : NSObject

+(void)initialize;
+(void)emailTo:(NSString *)to from:(NSString *)from subject:(NSString *)subject message:(NSString *)message;

@end
