//
//  ParseBase.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ParseBase : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * parseID;
@property (nonatomic, retain) NSString * pfUserID;
@property (nonatomic, retain) NSDate * updatedAt;

@end
