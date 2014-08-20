//
//  Payment+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/15/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Payment+Parse.h"
#import "Member+Parse.h"

@implementation Payment (Parse)

+(Payment *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Payment where:@{@"parseID":parseID}] all];
    Payment *payment;
    if ([objectArray count]) {
        payment = [objectArray firstObject];
    }
    else {
        payment = (Payment *)[Payment createEntityInContext:_appDelegate.managedObjectContext];
    }
    payment.pfObject = object;
    [payment updateFromParseWithCompletion:nil];
    return payment;
}

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.amount= [self.pfObject objectForKey:@"amount"];
            self.startDate = [self.pfObject objectForKey:@"startDate"];
            self.endDate = [self.pfObject objectForKey:@"endDate"];
            self.days = [self.pfObject objectForKey:@"days"];
            self.source = [self.pfObject objectForKey:@"source"];
            self.type = [self.pfObject objectForKey:@"type"];
            self.parseID = self.pfObject.objectId;

            // relationships
            PFObject *object = [self.pfObject objectForKey:@"member"];
            if (object.objectId)
                self.member = [[[Member where:@{@"parseID":object.objectId}] all] firstObject];
        }
        if (completion)
            completion(success);
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {
        if (self.amount)
            self.pfObject[@"amount"] = self.amount;
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
        if (self.member)
            self.pfObject[@"member"] = self.member.pfObject;


        [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
                self.parseID = self.pfObject.objectId;
            if (completion)
                completion(succeeded);
        }];
    }];
}


@end
