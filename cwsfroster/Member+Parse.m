//
//  Member+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Member+Parse.h"
#import "Organization+Parse.h"

@implementation Member (Parse)

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.name= [self.pfObject objectForKey:@"name"];
            self.email = [self.pfObject objectForKey:@"email"];
            self.status = [self.pfObject objectForKey:@"status"];
            self.monthPaid = [self.pfObject objectForKey:@"monthPaid"];

            // relationships
            PFObject *object = [self.pfObject objectForKey:@"organization"];
            if (object.objectId)
                self.organization = [[[Organization where:@{@"parseID":object.objectId}] all] firstObject];
        }
        if (completion)
            completion(success);
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (self.name)
            self.pfObject[@"name"] = self.name;
        if (self.email)
            self.pfObject[@"email"] = self.email;
        if (self.status)
            self.pfObject[@"status"] = self.status;
        if (self.monthPaid)
            self.pfObject[@"monthPaid"] = self.monthPaid;

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
