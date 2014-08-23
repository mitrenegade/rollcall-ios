//
//  SendGridHelper.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/19/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "SendGridHelper.h"

@implementation SendGridHelper

static SendGrid *sendgrid;

+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sendgrid = [SendGrid apiUser:@"bobbyren" apiKey:@"pCqDvguLe2A6xo"];
    });
}

+(void)emailTo:(NSString *)to subject:(NSString *)subject message:(NSString *)message {
    SendGridEmail *email = [[SendGridEmail alloc] init];
    email.from = @"cwsf_instructors@googlegroups.com";

    email.to = to?to:@"cwsf_instructors@googlegroups.com";
    email.subject = subject?subject:@"Attendance";
    email.text = message?message:@"Test email through SendGrid";

    [sendgrid sendWithWeb:email];
}
@end
