//
//  SKLManagedObject.m
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObject.h"
#import "SKLAPIClient.h"
#import "SKLRemoteRequestInfo.h"

@implementation SKLManagedObject

#pragma mark Remote Fetch

+ (void)fetch {
	SKLRemoteRequestInfo *info = [self remoteFetchInfo];
	SKLAPIClient *apiClient = [self apiClient];
	NSURLRequest *request = [apiClient requestWithMethod:@"GET" endPoint:info.path];
	[apiClient makeRequest:request completion:^(NSError *error, id responseObject) {
		NSLog(@"Fetched for %@: %@", NSStringFromClass([self class]), responseObject);
	}];
}

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	return nil;
}

+ (SKLAPIClient *)apiClient {
	return [SKLAPIClient defaultClient];
}

#pragma mark Core Data helpers

+ (instancetype)insertInContext:(NSManagedObjectContext *)context {
    id item =  [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class])
                                             inManagedObjectContext:context];
    return item;
}

+ (NSArray *)allInContext:(NSManagedObjectContext *)context {
    return [self allInContext:context predicate:nil];
}

+ (NSArray *)allInContext:(NSManagedObjectContext *)context predicate:(NSPredicate *)predicate {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    request.predicate = predicate;
    NSError *error;
    NSArray *result = [context executeFetchRequest:request
                                             error:&error];
    if (!result) {
        NSLog(@"Error when fetching %@: %@", NSStringFromClass(self), error);
    }

    return result;
    
}

+ (instancetype)anyInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    request.fetchLimit = 1;
    NSError *error;
    NSArray *result = [context executeFetchRequest:request
                                             error:&error];
    if (!result) {
        NSLog(@"Error fetching %@: %@", NSStringFromClass(self), error);
    }
    
    return [result firstObject];
}

@end
