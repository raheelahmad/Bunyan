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
