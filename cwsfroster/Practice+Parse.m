//
//  Practice+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 6/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Practice+Parse.h"

@implementation Practice (Parse)

+(Practice *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[Practice where:@{@"parseID":parseID}] all];
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

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.date = [self.pfObject objectForKey:@"date"];
            self.title = [self.pfObject objectForKey:@"title"];
            self.details = [self.pfObject objectForKey:@"details"];

            self.parseID = self.pfObject.objectId;
        }
        if (completion)
            completion(success);
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {

        if (self.date)
            self.pfObject[@"date"] = self.date;
        if (self.title)
            self.pfObject[@"title"] = self.title;
        if (self.details)
            self.pfObject[@"details"] = self.details;

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
