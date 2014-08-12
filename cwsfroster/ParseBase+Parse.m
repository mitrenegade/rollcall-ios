//
//  ParseBase+Parse.m
//  snailGram
//
//  Created by Bobby Ren on 3/22/14.
//  Copyright (c) 2014 SnailGram. All rights reserved.
//

#import "ParseBase+Parse.h"

@implementation ParseBase (Parse)

+(id)fromPFObject:(PFObject *)object {
    NSLog(@"%s must be implemented by child class", __func__);
    return nil;
}

-(NSString *)className {
    return NSStringFromClass(self.class);
}

-(void)updateFromParseWithCompletion:(void(^)(BOOL success))completion {
    if (!self.pfObject) {
        if (self.parseID) {
            PFQuery *query = [PFQuery queryWithClassName:self.className];
            [query whereKey:@"objectId" equalTo:self.parseID];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if ([objects count]) {
                    self.pfObject = objects[0];
                    if (completion)
                        completion(YES);
                }
                else {
                    if (completion)
                        completion(NO);
                }
            }];
        }
        else {
            if (completion)
                completion(NO);
        }
    }
    else {
        if (completion)
            completion(YES);
    }
}

-(void)updateFromParse {
    self.createdAt = self.pfObject[@"createdAt"];
    self.updatedAt = self.pfObject[@"updatedAt"];
    self.parseID = self.pfObject[@"objectId"];
    PFUser *user = self.pfObject[@"user"];
    self.pfUserID = user.objectId;
}

-(void)saveOrUpdateToParseWithCompletion:(void (^)(BOOL))completion {
    // first, make sure parse object exists, or create it
    [self updateFromParseWithCompletion:^(BOOL success) {
        if (!success)
            self.pfObject = [PFObject objectWithClassName:self.className];

        if (completion)
            completion(YES);
    }];
}

#pragma mark Instance variable for category
// http://oleb.net/blog/2011/05/faking-ivars-in-objc-categories-with-associative-references/
// use associative reference in order to add a new instance variable in a category

-(PFObject *)pfObject {
    return objc_getAssociatedObject(self, PFObjectTagKey);
}

-(void)setPfObject:(PFObject *)pfObject {
    objc_setAssociatedObject(self, PFObjectTagKey, pfObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
