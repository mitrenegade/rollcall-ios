//
//  Organization+Parse.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/28/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Organization+Parse.h"

@implementation Organization (Parse)

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    [super updateFromParseWithCompletion:^(BOOL success) {
        if (success) {
            self.name = [self.pfObject objectForKey:@"name"];
            PFFile *logoFile = [self.pfObject objectForKey:@"logoData"];
            self.logoData = [logoFile getData];

        }
        if (completion)
            completion(success);
    }];
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    [super saveOrUpdateToParseWithCompletion:^(BOOL success) {

        if (self.name)
            self.pfObject[@"name"] = self.name;
        if (self.logoData)
            self.pfObject[@"logoData"] = [PFFile fileWithData:self.logoData];

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

