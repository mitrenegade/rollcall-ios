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

@implementation Attendance (Parse)

+(Attendance *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Attendance where:@{@"parseID":parseID}] all];
    Attendance *obj;
    if ([objectArray count]) {
        obj = [objectArray firstObject];
    }
    else {
        obj = (Attendance *)[Attendance createEntityInContext:_appDelegate.managedObjectContext];
    }
    obj.pfObject = object;
    [obj updateFromParseWithCompletion:nil];
    return obj;
}

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    // refreshes object from parse
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.date = [self.pfObject objectForKey:@"date"];
            self.attended = [self.pfObject objectForKey:@"attended"];
            self.parseID = self.pfObject.objectId;

            // relationships
            PFObject *object = [self.pfObject objectForKey:@"member"];
            self.member = [[[Member where:@{@"parseID":object.objectId}] all] firstObject];
            object = [self.pfObject objectForKey:@"practice"];
            self.practice = [[[Practice where:@{@"parseID":object.objectId}] all] firstObject];
            object = [self.pfObject objectForKey:@"payment"];
            self.payment = [[[Payment where:@{@"parseID":object.objectId}] all] firstObject];
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
        if (self.member)
            self.pfObject[@"member"] = self.member.pfObject;
        if (self.practice)
            self.pfObject[@"practice"] = self.practice.pfObject;
        if (self.payment)
            self.pfObject[@"payment"] = self.payment.pfObject;

        [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
                self.parseID = self.pfObject.objectId;
            if (completion)
                completion(succeeded);
        }];
    }];
}
@end
