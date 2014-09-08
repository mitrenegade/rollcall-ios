    //
//  Organization+Info.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Organization+Info.h"
#import "ParseBase+Parse.h"
#import <Parse/Parse.h>

static Organization *currentOrganization;

@implementation Organization (Info)

+(Organization *)currentOrganization {
    if (currentOrganization) {
        return currentOrganization;
    }

    PFObject *object = _currentUser[@"organization"];
    currentOrganization = [[[Organization where:@{@"parseID":object.objectId}] all] firstObject];
    return currentOrganization;
}

+(void)reset {
    currentOrganization = nil;
}
@end
