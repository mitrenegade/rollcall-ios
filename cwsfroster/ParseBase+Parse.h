//
//  ParseBase+Parse.h
//  snailGram
//
//  Created by Bobby Ren on 3/22/14.
//  Copyright (c) 2014 SnailGram. All rights reserved.
//

#import "ParseBase.h"
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import "PFObjectFactory.h"
#import "NSManagedObject+Entity.h"
#import "NSManagedObject+Query.h"

@interface ParseBase (Parse) <PFObjectFactory>

+(id)fromPFObject:(PFObject *)object;

@end
