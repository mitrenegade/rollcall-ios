//
//  Attendance+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Attendance+Parse.h"
#import "Member+Parse.h"
#import "Practice+Parse.h"
#import "Payment+Parse.h"
#import "Organization+Parse.h"

@implementation Attendance (Parse)

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    // refreshes object from parse
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.date = [self.pfObject objectForKey:@"date"];
            self.attended = [self.pfObject objectForKey:@"attended"];

            // relationships
            PFObject *object = [self.pfObject objectForKey:@"member"];
            if (object.objectId)
                self.member = [[[Member where:@{@"parseID":object.objectId}] all] firstObject];
            object = [self.pfObject objectForKey:@"practice"];
            if (object.objectId)
                self.practice = [[[Practice where:@{@"parseID":object.objectId}] all] firstObject];
            object = [self.pfObject objectForKey:@"payment"];
            if (object.objectId) {
                self.payment = [[[Payment where:@{@"parseID":object.objectId}] all] firstObject];
            }
            object = [self.pfObject objectForKey:@"organization"];
            if (object.objectId)
                self.organization = [[[Organization where:@{@"parseID":object.objectId}] all] firstObject];
        }
        if (completion)
            completion(success);
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    // updates attributes to parse. should use existing pfObject if it exists
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {
        // if not updated, this is a new object
        if (self.date)
            self.pfObject[@"date"] = self.date;
        if (self.attended)
            self.pfObject[@"attended"] = self.attended;

        // relationships
        if (self.member.pfObject)
            self.pfObject[@"member"] = self.member.pfObject;
        if (self.practice.pfObject)
            self.pfObject[@"practice"] = self.practice.pfObject;
        if (self.payment.pfObject)
            self.pfObject[@"payment"] = self.payment.pfObject;
        if (self.organization.pfObject)
            self.pfObject[@"organization"] = self.organization.pfObject;

        [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // always update from parse in case web made changes on beforeSave or afterSave
                // doesn't make an extra web request
                self.parseID = self.pfObject.objectId;
                [self updateFromParseWithCompletion:^(BOOL success) {
                    if (completion)
                        completion(succeeded);
                }];
            }
            else {
                if (completion)
                    completion(succeeded);
            }
        }];
    }];
}
@end
