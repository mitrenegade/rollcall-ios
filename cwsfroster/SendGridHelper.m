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
        sendgrid = [SendGrid apiUser:@"rollCallApp" apiKey:@"JvRjPb66QrcvaU"];
    });
}

+(void)emailTo:(NSString *)to from:(NSString *)from subject:(NSString *)subject message:(NSString *)message {
    SendGridEmail *email = [[SendGridEmail alloc] init];
    email.from = from;
    email.to = to;
    email.subject = subject;
    NSString *byline = [NSString stringWithFormat:@"This email was sent on behalf of %@ by Roll Call and Random Drawing for Your Awesome Application app. Download the app here: http://bit.ly/1tnuetG", [Organization currentOrganization].name];
    email.text = message?([NSString stringWithFormat:@"%@<br><br>%@", message, byline]):byline;

    [sendgrid sendWithWeb:email];
}
@end
