//
//  SKLOpusFetcher.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/21/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLOpusFetcher.h"
#import "SKLFakeOpus.h"

@implementation SKLOpusFetcher


#pragma mark Fetch info

- (Class)managedObjectClass {
	return [SKLFakeOpus class];
}


- (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"name" : @"name",
			 @"remoteId" : @"id",
			 @"pageCount" : @"pages"
			 };
}

- (id)uniquingKey { return @"remoteId"; }

@end
