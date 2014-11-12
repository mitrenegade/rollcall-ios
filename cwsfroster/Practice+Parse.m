//
//  Practice+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Practice+Parse.h"
#import "Organization+Parse.h"

@implementation Practice (Parse)

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
    self.date = [self.pfObject objectForKey:@"date"];
    self.title = [self.pfObject objectForKey:@"title"];
    self.details = [self.pfObject objectForKey:@"details"];

    // relationships
    self.parseID = self.pfObject.objectId;
    PFObject *object = [self.pfObject objectForKey:@"organization"];
    if (object.objectId)
        self.organization = [[[Organization where:@{@"parseID":object.objectId}] all] firstObject];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {

        if (self.date)
            self.pfObject[@"date"] = self.date;
        if (self.title)
            self.pfObject[@"title"] = self.title;
        if (self.details)
            self.pfObject[@"details"] = self.details;

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
