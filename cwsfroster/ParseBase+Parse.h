//
//  ParseBase+Parse.h
//  snailGram
//
//  Created by Bobby Ren on 3/22/14.
//  Copyright (c) 2014 SnailGram. All rights reserved.
//

#import "ParseBase.h"
#import <objc/runtime.h>
#import "PFObjectFactory.h"
#import "NSManagedObject+Entity.h"
#import "NSManagedObject+Query.h"

@interface ParseBase (Parse) <PFObjectFactory>

+(id)fromPFObject:(PFObject *)object;

+(void)synchronizeClass:(NSString *)className fromObjects:(NSArray *)objects replaceExisting:(BOOL)replace completion:(void(^)())completion;
+(void)synchronizeClass:(NSString *)className fromObjects:(NSArray *)objects replaceExisting:(BOOL)replace scope:(NSDictionary *)scope completion:(void(^)())completion;

-(void)updateAttributesFromPFObject;
@end
