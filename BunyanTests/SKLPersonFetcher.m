//
//  SKLPersonFetcher.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLPersonFetcher.h"
#import "SKLFakePerson.h"
#import "SKLAPIRequest.h"
#import "SKLOpusFetcher.h"

@interface SKLModelFetcher ()

- (SKLTestableAPIClient *)apiClient;
- (NSManagedObjectContext *)importContext;

@end

@implementation SKLPersonFetcher

#pragma mark Mocking

- (SKLTestableAPIClient *)apiClient {
    return self.mockApiClient ? : [super apiClient];
}

- (NSManagedObjectContext *)importContext {
    return self.mockImportContext ? : [super importContext];
}

#pragma mark Refresh info

- (SKLAPIRequest *)remoteRefreshInfoForObject:(SKLFakePerson *)object {
    NSString *endpoint = [NSString stringWithFormat:@"/get/persons/%@", object.remoteId];
	return [SKLAPIRequest with:endpoint method:@"GET" params:nil body:nil];
}

#pragma mark Fetch info

- (Class)managedObjectClass {
	return [SKLFakePerson class];
}

- (SKLAPIRequest *)remoteFetchInfo {
    return [SKLAPIRequest with:@"/get/persons" method:@"GET" params:nil body:nil];
}

- (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"remoteId" : @"id",
			 @"name" : @"name",
			 @"location" : @"location",
			 @"birthdate" : @"date",
			 @"magnumOpus" : @"magnum",
			 @"opuses" : @"otherOpuses",
			 @"favoriteOpuses" : @"favorites",
			 };
}

- (SKLModelFetcher *)fetcherForRelationship:(NSString *)relationKey {
    for (NSString *opusKey in @[ @"magnumOpus", @"opuses", @"favoriteOpuses" ]) {
        if ([relationKey isEqualToString:opusKey]) {
            return [[SKLOpusFetcher alloc] init];
        }
    }
    return nil;
}

- (id)localValueForKey:(NSString *)localKey remoteValue:(id)remoteValue {
	id localValue = remoteValue;
	if ([localKey isEqualToString:@"birthdate"]) {
		// 2010-02-06T11:36:49Z
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		localValue = [df dateFromString:remoteValue];
	}
	return localValue;
}

- (BOOL)shouldReplaceWhenUpdatingToManyRelationship:(NSString *)relationship {
	if ([relationship isEqualToString:@"favoriteOpuses"]) {
		return NO; // i.e., keep existing to-many destination objects when setting
	} else {
		return YES;
	}
}


- (NSString *)uniquingKey {
    return @"remoteId";
}

@end
