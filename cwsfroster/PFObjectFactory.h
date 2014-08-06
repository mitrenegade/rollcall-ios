//
//  PFObjectFactory.h
//  NightPulse
//
//  Created by Sachin Nene on 9/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

static char const * const PFObjectTagKey = "PFObjectTagKey";

@protocol PFObjectFactory

+(id)fromPFObject:(PFObject *)object;
-(void)updateFromParseWithCompletion:(void(^)(BOOL success))completion;
-(void)saveOrUpdateToParseWithCompletion:(void(^)(BOOL success))completion;

@property (nonatomic, retain) NSString * className;
@property (nonatomic, retain) PFObject *pfObject;

@end
