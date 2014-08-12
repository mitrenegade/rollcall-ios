//
//  Member+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 5/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Member+Parse.h"
#import "ParseBase+Parse.h"

@implementation Member (Parse)

+(Member *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Member where:@{@"parseID":parseID}] all];
    Member *member;
    if ([objectArray count]) {
        member = [objectArray firstObject];
    }
    else {
        member = (Member *)[Member createEntityInContext:_appDelegate.managedObjectContext];
    }
    member.pfObject = object;
    [member updateFromParseWithCompletion:nil];
    return member;
}

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.name= [self.pfObject objectForKey:@"name"];
            self.email = [self.pfObject objectForKey:@"email"];
            self.status = [self.pfObject objectForKey:@"status"];
            self.monthPaid = [self.pfObject objectForKey:@"monthPaid"];
            self.parseID = self.pfObject.objectId;
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

        [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
                self.parseID = self.pfObject.objectId;
            if (completion)
                completion(succeeded);
        }];
    }];
}

@end
