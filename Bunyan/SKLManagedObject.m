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
#import "SKLPersistenceStack.h"
#import "NSManagedObjectContext+Additions.h"

@implementation SKLManagedObject

#pragma mark Remote Fetch

+ (void)fetch {
	SKLRemoteRequestInfo *info = [self remoteFetchInfo];
	SKLAPIClient *apiClient = [self apiClient];
	NSURLRequest *request = [apiClient requestWithMethod:@"GET" endPoint:info.path];
	[apiClient makeRequest:request completion:^(NSError *error, id responseObject) {
		[self updateWithRemoteFetchResponse:responseObject];
	}];
}

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	return nil;
}

+ (SKLAPIClient *)apiClient {
	return [SKLAPIClient defaultClient];
}

#pragma mark Fetch Response Update

+ (void)updateWithRemoteFetchResponse:(NSArray *)response {
	if (!response) {
		return;
	}
	NSManagedObjectContext *context = [self importContext];
	[context performBlock:^{
		for (NSDictionary *remoteObject in response) {
			id localObject = [self localObjectForRemoteObject:remoteObject];
			if (!localObject) {
				localObject = [self insertInContext:context];
			}
			[localObject updateWithRemoteObject:remoteObject];
		}
		
		[context save];
	}];
}

- (void)updateWithRemoteObject:(NSDictionary *)remoteObject {
	NSDictionary *mapping = [[self class] localToRemoteKeyMapping];
	[mapping enumerateKeysAndObjectsUsingBlock:^(id localKey, id remoteKey, BOOL *stop) {
		id remoteValue = remoteObject[remoteKey];
		id localValue = [self valueForKey:localKey];
		BOOL remoteValuePresent = remoteValue != nil;
		BOOL localNotSameAsRemote = ![localValue isEqual:remoteValue];
		if (remoteValuePresent && localNotSameAsRemote) {
			[self setValue:remoteValue
					forKey:localKey];
		}
	}];
}

#pragma mark Fetch Helpers

+ (NSDictionary *)localToRemoteKeyMapping {
	return nil;
}

+ (instancetype)localObjectForRemoteObject:(NSDictionary *)remoteObject {
	NSString *uniquingKey = [self uniquingKey];
	if (!uniquingKey) {
		[NSException raise:@"UniquingKeyAbsent" format:@"Uniquing key must be set for %@", NSStringFromClass(self)];
	}
	NSString *remoteUniquingKey = [self localToRemoteKeyMapping][uniquingKey];
	NSString *remoteUniqueValue = remoteObject[remoteUniquingKey];
	NSPredicate *uniquingPredicate = [NSPredicate predicateWithFormat:@"%K == %@", uniquingKey, remoteUniqueValue];
	NSArray *matches = [self allInContext:[self importContext] predicate:uniquingPredicate];
	
	return [matches firstObject];
}

+ (id)uniquingKey {
	return nil;
}

+ (NSArray *)sortDescriptors {
    return nil;
}

#pragma mark Core Data helpers

+ (NSManagedObjectContext *)mainContext {
	return [[SKLPersistenceStack defaultStack] mainContext];
}

+ (NSManagedObjectContext *)importContext {
	return [[SKLPersistenceStack defaultStack] importContext];
}

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

+ (NSFetchedResultsController *)controllerInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    request.sortDescriptors = [self sortDescriptors];
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
																				 managedObjectContext:context
																				   sectionNameKeyPath:nil
																							cacheName:nil];
	return controller;
}

@end
