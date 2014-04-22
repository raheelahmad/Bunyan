//
//  SKLModelFetcher.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLModelFetcher.h"
#import "SKLManagedObject.h"
#import "SKLPersistenceStack.h"
#import "SKLAPIClient.h"
#import "SKLAPIRequest.h"
#import "SKLAPIResponse.h"

NSString *const SKLFetcherRequiresSubclassImplementation = @"SKLFetcherRequiresSubclassImplementation";

@interface SKLModelFetcher ()

@property (nonatomic, readonly) SKLAPIClient *apiClient;

@end

@implementation SKLModelFetcher

#pragma mark Fetch

- (void)fetchFromRemote {
    [self fetchFromRemoteWithCompletion:nil];
}

- (void)fetchFromRemoteWithCompletion:(SKLFetchResponseBlock)completion {
	[self fetchFromRemoteWithInfo:[self remoteFetchInfo]
					   completion:completion];
}

- (void)fetchFromRemoteWithInfo:(SKLAPIRequest *)request completion:(SKLFetchResponseBlock)completion {
	SKLAPIClient *apiClient = [self apiClient];
    request.responseParsing = SKLJSONResponseParsing;
	if (!request.completionBlock) {
		request.completionBlock = ^(NSError *error, SKLAPIResponse *apiResponse) {
			if (error) {
				NSLog(@"Error fetching %@: %@", NSStringFromClass([self managedObjectClass]), error);
			} else {
				[self updateWithRemoteFetchResponse:apiResponse];
			}
			if (completion) {
				completion(error);
			}
		};
	}
	[apiClient makeRequest:request];
}

#pragma mark Refresh

- (void)refreshObjectFromRemote:(SKLManagedObject *)object {
	SKLAPIRequest *info = [self remoteRefreshInfoForObject:object];
	[self refreshObjectFromRemote:object withInfo:info];
}

- (void)refreshObjectFromRemote:(SKLManagedObject *)object withInfo:(SKLAPIRequest *)request {
	[self refreshObjectFromRemote:object
						 withInfo:request
					   completion:nil];
}

- (void)refreshObjectFromRemote:(SKLManagedObject *)object withInfo:(SKLAPIRequest *)request completion:(SKLFetchResponseBlock)completion {
	SKLAPIClient *apiClient = [self apiClient];
	if (!request) {
		return;
	}
	
	// only set completion for refreshing local object, if no completion has been set yet
	if (!request.completionBlock) {
		request.completionBlock = ^(NSError *error, SKLAPIResponse *apiResponse) {
			if (error) {
				NSLog(@"Error refreshing %@: %@", self, error);
			} else {
				[self refreshObject:object withRemoteResponse:apiResponse.responseObject];
			}
			if (completion) {
				completion(error);
			}
		};
	}
	
	[apiClient makeRequest:request];
}

- (void)refreshObject:(SKLManagedObject *)object withRemoteResponse:(NSDictionary *)responseObject {
	// We should update in the background
	NSManagedObjectID *objectId = object.objectID;
	NSManagedObjectContext *context = [self importContext];
	[context performBlockAndWait:^{
		SKLManagedObject *importCtxObject = (SKLManagedObject *)[context objectWithID:objectId];
		[self updateLocalObject:importCtxObject withRemoteObject:responseObject];
		if ([context hasChanges]) {
			NSError *error;
			BOOL saved = [context save:&error];
			if (!saved) {
				NSLog(@"Error saving: %@", error);
			}
		}
	}];
}

#pragma mark Update with remote response

- (void)updateWithRemoteFetchResponse:(SKLAPIResponse *)response {
    Class managedObjectClass = [self managedObjectClass];
    NSParameterAssert(managedObjectClass != nil);
	NSArray *remoteObjects = response.responseObject;
	if (!remoteObjects) {
		return;
	}
	NSManagedObjectContext *context = [self importContext];
	[context performBlockAndWait:^{
		NSMutableArray *all = [[managedObjectClass allInContext:context] mutableCopy];
		for (NSDictionary *remoteObject in remoteObjects) {
			id localObject = [self localObjectForRemoteObject:remoteObject inContext:context];
			if (!localObject) {
				localObject = [managedObjectClass insertInContext:context];
			}
            [self updateLocalObject:localObject
                   withRemoteObject:remoteObject];
			[all removeObject:localObject];
		}
		
		if ([self shouldDeleteStaleLocalObjects]) {
			for (SKLManagedObject *object in all) {
				[context deleteObject:object];
			}
		}
		
        NSError *error;
        BOOL saved = [context save:&error];
        if (!saved) {
            NSLog(@"Error saving: %@", error);
        }
	}];
}

- (void)updateLocalObject:(SKLManagedObject *)localObject withRemoteObject:(NSDictionary *)remoteObject {
	NSDictionary *mapping = [self localToRemoteKeyMapping];
	[mapping enumerateKeysAndObjectsUsingBlock:^(id localKey, id remoteKey, BOOL *stop) {
		id remoteValue = [remoteObject valueForKeyPath:remoteKey];
		if (remoteValue && remoteValue != [NSNull null]) {
            [self updateValueForObject:localObject localKey:localKey remoteValue:remoteValue];
		}
	}];
}

- (void)updateValueForObject:(SKLManagedObject *)object localKey:(NSString *)localKey remoteValue:(id)remoteValue {
	id localValue = [object valueForKey:localKey];
	id formattedRemoteValue = [self localValueForKey:localKey remoteValue:remoteValue];
	
	NSAttributeDescription *attribute = [object.entity attributesByName][localKey];
	NSRelationshipDescription *relationship = [object.entity relationshipsByName][localKey];
	NSAssert(attribute || relationship, @"%@ is neither an attribute nor a relationship for %@'s entity", localKey, NSStringFromClass(self.class));
	
	if (!formattedRemoteValue || formattedRemoteValue == [NSNull null]) {
		return;
	}
	
	if (attribute) {
		BOOL remoteValuePresent = formattedRemoteValue != nil && formattedRemoteValue != [NSNull null];
		if ([remoteValue respondsToSelector:@selector(length)]) {
			remoteValuePresent = [remoteValue length] > 0;
		}
		BOOL localNotSameAsRemote = ![localValue isEqual:formattedRemoteValue];
		if (remoteValuePresent && localNotSameAsRemote) {
			[object setValue:formattedRemoteValue
                      forKey:localKey];
		}
	} else if (relationship) {
		Class destinationClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);
        SKLModelFetcher *destinationFetcher = [self fetcherForRelationship:localKey];
        
		// common block to insert/update a destination class object
		SKLManagedObject *(^DestinationObjectForRemote)(NSDictionary *) = ^(NSDictionary *remoteObject) {
			SKLManagedObject *destinationObject = [destinationFetcher localObjectForRemoteObject:remoteObject
                                                                                       inContext:object.managedObjectContext];
			if (!destinationObject) {
				destinationObject = [destinationClass insertInContext:object.managedObjectContext];
			}
            [destinationFetcher updateLocalObject:destinationObject withRemoteObject:remoteObject];
			return destinationObject;
		};
		
		if (relationship.isToMany) {
			NSAssert([formattedRemoteValue isKindOfClass:[NSArray class]], @"Relationship %@ in %@ is to-many and should be remote updated with an array", localKey, NSStringFromClass(self.class));
			
			NSMutableSet *destinationLocalObjects;
			if ([self shouldReplaceWhenUpdatingToManyRelationship:localKey]) {
				destinationLocalObjects = [NSMutableSet set];
			} else {
				// include the current local objects for this to-many relationship
				destinationLocalObjects = [NSMutableSet setWithSet:[object valueForKeyPath:localKey]];
			}
			
			for (NSDictionary *remoteObject in formattedRemoteValue) {
				[destinationLocalObjects addObject:DestinationObjectForRemote(remoteObject)];
			}
			[object setValue:destinationLocalObjects
					forKey:localKey];
		} else {
			NSAssert([formattedRemoteValue isKindOfClass:[NSDictionary class]], @"Relationship %@ in %@ is to-one and should be remote updated with a dictionary", localKey, NSStringFromClass(self.class));
			
			id localObject = [object valueForKey:localKey];
			if (localObject) {
                [destinationFetcher updateLocalObject:localObject withRemoteObject:formattedRemoteValue];
			} else {
				localObject = DestinationObjectForRemote(formattedRemoteValue);
			}
			
			[object setValue:localObject
					forKey:localKey];
		}
	}
}

- (instancetype)fetcherForRelationship:(NSString *)relationKey {
    return nil;
}

/// Allows formatting when setting a local value with a remote value
- (id)localValueForKey:(NSString *)localKey remoteValue:(id)remoteValue {
	return remoteValue;
}

- (BOOL)shouldReplaceWhenUpdatingToManyRelationship:(NSString *)relationship {
	return YES;
}

#pragma mark Core Data helpers

- (NSManagedObjectContext *)importContext {
	return [[SKLPersistenceStack defaultStack] importContext];
}

#pragma mark Refresh information

- (SKLAPIRequest *)remoteRefreshInfoForObject:(SKLManagedObject *)object {
	return nil;
}


#pragma mark Fetch information

- (SKLAPIRequest *)remoteFetchInfo {
    return nil;
}

- (BOOL)shouldDeleteStaleLocalObjects {
    return YES;
}

- (Class)managedObjectClass {
    return nil;
}

- (SKLAPIClient *)apiClient {
	return [SKLAPIClient defaultClient];
}


#pragma mark Mapping

- (instancetype)localObjectForRemoteObject:(NSDictionary *)remoteObject inContext:(NSManagedObjectContext *)context {
	NSString *uniquingKey = [self uniquingKey];
	if (!uniquingKey) {
		[NSException raise:@"UniquingKeyAbsent"
					format:@"Uniquing key must be set for %@", NSStringFromClass([self class])];
	}
	NSString *remoteUniquingKey = [self localToRemoteKeyMapping][uniquingKey];
	NSString *remoteUniqueValue = remoteObject[remoteUniquingKey];
	NSPredicate *uniquingPredicate = [NSPredicate predicateWithFormat:@"%K == %@", uniquingKey, remoteUniqueValue];
	NSArray *matches = [self.managedObjectClass allInContext:context predicate:uniquingPredicate];
	
	return [matches firstObject];
}

#pragma mark Mapping information

- (NSDictionary *)localToRemoteKeyMapping {
	[NSException raise:SKLFetcherRequiresSubclassImplementation
				format:@"%@ should implement localToRemoteKeyMapping", NSStringFromClass([self class])];
	return nil;
}

- (NSString *)uniquingKey {
	[NSException raise:SKLFetcherRequiresSubclassImplementation
				format:@"%@ should implement localToRemoteKeyMapping", NSStringFromClass([self class])];
	return nil;
}

#pragma mark Initialization

@end
