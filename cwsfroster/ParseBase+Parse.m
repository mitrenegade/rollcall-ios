//
//  ParseBase+Parse.m
//  snailGram
//
//  Created by Bobby Ren on 3/22/14.
//  Copyright (c) 2014 SnailGram. All rights reserved.
//

#import "ParseBase+Parse.h"

@implementation ParseBase (Parse)

static NSMutableDictionary *pfObjectCache; // a cache to store pfObjects so that they can be associated through core data 

+(ParseBase *)fromPFObject:(PFObject *)object {
    id parseID = object.objectId;
    NSArray *objectArray = [[[self class] where:@{@"parseID":parseID}] all];
    id newObject;
    if ([objectArray count]) {
        newObject = [objectArray firstObject];
    }
    else {
        newObject = [[self class] createEntityInContext:_appDelegate.managedObjectContext];
    }
    ((ParseBase *)newObject).parseID = object.objectId;
    ((ParseBase *)newObject).pfObject = object;
    [newObject updateFromParseWithCompletion:nil];
    return newObject;
}

-(NSString *)className {
    return NSStringFromClass(self.class);
}

-(void)updatePFObjectFromParseWithCompletion:(void(^)(BOOL success))completion {
    // only updates pfObject from parse
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

-(void)updateFromParseWithCompletion:(void (^)(BOOL))completion {
    // update pfObject, and all attributes
    [self updatePFObjectFromParseWithCompletion:completion];
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
    [self updatePFObjectFromParseWithCompletion:^(BOOL success) {
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
    PFObject *object = objc_getAssociatedObject(self, PFObjectTagKey);
    if (!object) {
        if (pfObjectCache[self.parseID]) {
            object = pfObjectCache[self.parseID];
            [self setPfObject:object];
        }
    }
    return object;
}

-(void)setPfObject:(PFObject *)pfObject {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pfObjectCache = [NSMutableDictionary dictionary];
    });
    if (!self.parseID) {
        NSLog(@"No id - must be a new allocation of pfObject");
    }
    else {
        pfObjectCache[self.parseID] = pfObject; // forces this to stay in memory
    }

    objc_setAssociatedObject(self, PFObjectTagKey, pfObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+(void)synchronizeClass:(NSString *)className fromObjects:(NSArray *)objects replaceExisting:(BOOL)replace completion:(void(^)())completion {
    [self synchronizeClass:className fromObjects:objects replaceExisting:replace scope:@{} completion:completion];
}

+(void)synchronizeClass:(NSString *)className fromObjects:(NSArray *)objects replaceExisting:(BOOL)replace scope:(NSDictionary *)scope completion:(void(^)())completion {
    // todo: perform this in background thread and use managed object context threading
    Class class = NSClassFromString(className);

    NSMutableArray *all = [[[class where:scope] all] mutableCopy];
    NSLog(@"All existing %@ before sync: %lu", className, (unsigned long)all.count);
    for (PFObject *object in objects) {
        NSManagedObject *classObject = [class fromPFObject:object];
        [all removeObject:classObject];
    }

    NSLog(@"Query for %@ returned %lu objects", className, (unsigned long)[objects count]);
    NSLog(@"No longer in core data %@ after sync: %lu", className, (unsigned long)all.count);

    if (replace) {
        for (id object in all) {
            [_appDelegate.managedObjectContext deleteObject:object];
        }
    }

    NSError *error;
    [_appDelegate.managedObjectContext save:&error];

    if (completion)
        completion();
}
@end
