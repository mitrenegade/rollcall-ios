//
//  Practice+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Practice+Parse.h"
#import "ParseBase+Parse.h"

@implementation Practice (Parse)

+(Practice *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Practice where:@{@"id":parseID}] all];
    Practice *obj;
    if ([objectArray count]) {
        obj = [objectArray firstObject];
    }
    else {
        obj = (Practice *)[Practice createEntityInContext:_appDelegate.managedObjectContext];
    }
    obj.pfObject = object;
    [obj updateFromParseWithCompletion:nil];
    return obj;
}

-(void)updateFromParse {
    [super updateFromParseWithCompletion:^(BOOL success) {
        self.date = [self.pfObject objectForKey:@"date"];
        self.title = [self.pfObject objectForKey:@"title"];
//        self.attendances = [self.pfObject objectForKey:@"attendances"];

        self.parseID = self.pfObject.objectId;
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    if (!self.pfObject)
        self.pfObject = [PFObject objectWithClassName:self.className];

    if (self.date)
        self.pfObject[@"date"] = self.date;
    if (self.title)
        self.pfObject[@"title"] = self.title;
//    if (self.attendances)
//        self.pfObject[@"attendances"] = self.attendances;

    [self.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
            self.parseID = self.pfObject.objectId;
        if (completion)
            completion(succeeded);
    }];
}
@end
