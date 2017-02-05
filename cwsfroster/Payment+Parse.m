//
//  Payment+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/15/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Payment+Parse.h"
#import "Organization+Parse.h"

@implementation Payment (Parse)

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            [self updateAttributesFromPFObject];
        }
        if (completion)
            completion(success);
    }];
}

-(void)updateAttributesFromPFObject {
    self.amount= [self.pfObject objectForKey:@"amount"];
    self.startDate = [self.pfObject objectForKey:@"startDate"];
    self.endDate = [self.pfObject objectForKey:@"endDate"];
    self.days = [self.pfObject objectForKey:@"days"];
    self.source = [self.pfObject objectForKey:@"source"];
    self.type = [self.pfObject objectForKey:@"type"];

    // relationships
    PFObject *object = [self.pfObject objectForKey:@"member"];
    if (object.objectId) {
//        self.member = [[[Member where:@{@"parseID":object.objectId}] all] firstObject];
    }
    PFObject *organization = [self.pfObject objectForKey:@"organization"];
    if (organization.objectId)
        self.organization = [[[Organization where:@{@"parseID":object.objectId}] all] firstObject];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (self.amount)
            self.pfObject[@"amount"] = self.amount;
        if (self.receiptDate)
            self.pfObject[@"receiptDate"] = self.receiptDate;
        if (self.startDate)
            self.pfObject[@"startDate"] = self.startDate;
        if (self.endDate)
            self.pfObject[@"endDate"] = self.endDate;
        if (self.days)
            self.pfObject[@"days"] = self.days;
        if (self.source)
            self.pfObject[@"source"] = self.source;
        if (self.type)
            self.pfObject[@"type"] = self.type;

        // relationships
//        if (self.member)
//            self.pfObject[@"member"] = self.member.pfObject;
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
