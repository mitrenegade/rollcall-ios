//
//  Attendance+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Attendance+Parse.h"
#import "ParseBase+Parse.h"

@implementation Attendance (Parse)

+(Attendance *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Attendance where:@{@"id":parseID}] all];
    Attendance *obj;
    if ([objectArray count]) {
        obj = [objectArray firstObject];
    }
    else {
        obj = (Attendance *)[Attendance createEntityInContext:_appDelegate.managedObjectContext];
    }
    obj.pfObject = object;
    [obj updateFromParse];
    return obj;
}

-(void)updateFromParse {
    [super updateFromParse];

    self.date = [self.pfObject objectForKey:@"date"];
    self.member = [self.pfObject objectForKey:@"member"];
    self.practice = [self.pfObject objectForKey:@"practice"];

    self.parseID = self.pfObject.objectId;
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    if (!self.pfObject)
        self.pfObject = [PFObject objectWithClassName:self.className];

    if (self.date)
        self.pfObject[@"date"] = self.date;
    if (self.member)
        self.pfObject[@"member"] = self.member;
    if (self.practice)
        self.pfObject[@"practice"] = self.practice;

    [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
            self.parseID = self.pfObject.objectId;
        if (completion)
            completion(succeeded);
    }];
}
@end
