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
        sendgrid = [SendGrid apiUser:@"username" apiKey:@"password"];
    });
}

+(void)email {
    SendGridEmail *email = [[SendGridEmail alloc] init];
    email.to = @"cwsf_instructors@googlegroups.com";
    email.from = @"cwsf_instructors@googlegroups.com";
    email.subject = @"Attendance";
    email.text = @"Test email through SendGrid";

    [sendgrid sendWithWeb:email];
}
@end
