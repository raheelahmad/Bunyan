//
//  SKLAPIResponse.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/25/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIResponse.h"
#import "SKLAPIRequest.h"

@implementation SKLAPIResponse

- (BOOL)cached {
    SKLAPIResponse *response = self;
    BOOL allCached = YES;
    while (response) {
        NSString *statusHeaderString = self.httpResponse.allHeaderFields[@"Status"];
        allCached = [[statusHeaderString lowercaseString] isEqualToString:@"304 not modified"];
        if (!allCached) {
            break;
        }
        response = response.request.previousResponse;
    }
    
    return allCached;
}


- (NSArray *)allResponseObjects {
	NSMutableArray *allResponseObjects = [NSMutableArray array];
	
	[allResponseObjects addObjectsFromArray:self.responseObject];
	
	SKLAPIRequest *request = self.request;
	while (request) {
		SKLAPIResponse *previousResponse = request.previousResponse;
		[allResponseObjects addObjectsFromArray:previousResponse.responseObject];
		request = previousResponse.request;
	}
	
	return allResponseObjects;
}

@end
