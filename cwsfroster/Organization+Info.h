//
//  Organization+Info.h
//  cwsfroster
//
//  Created by Bobby Ren on 8/29/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "Organization.h"

@interface Organization (Info)

+(Organization *)currentOrganization;
+(void)reset;
+(void)createOrganizationWithCompletion:(void(^)(Organization *organization))completion;

@end
