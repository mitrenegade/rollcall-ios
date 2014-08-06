//
//  Attendance+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Attendance+Parse.h"
#import "ParseBase+Parse.h"
#import "Member+Parse.h"
#import "Practice+Parse.h"

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
    [super updateFromParseWithCompletion:^(BOOL success) {
        self.date = [self.pfObject objectForKey:@"date"];
        self.member = [self.pfObject objectForKey:@"member"];
        self.practice = [self.pfObject objectForKey:@"practice"];
        self.attended = [self.pfObject objectForKey:@"attended"];

        self.parseID = self.pfObject.objectId;
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    if (!self.pfObject)
        self.pfObject = [PFObject objectWithClassName:self.className];

    if (self.date)
        self.pfObject[@"date"] = self.date;
    if (self.member)
        self.pfObject[@"member"] = self.member.pfObject;
    if (self.practice)
        self.pfObject[@"practice"] = self.practice.pfObject;
    if (self.attended)
        self.pfObject[@"attended"] = self.attended;

    [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
            self.parseID = self.pfObject.objectId;
        if (completion)
            completion(succeeded);
    }];
}
@end
