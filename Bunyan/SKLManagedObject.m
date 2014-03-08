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
		if (error) {
			NSLog(@"Error fetching %@: %@", NSStringFromClass(self), error);
		} else {
			[self updateWithRemoteFetchResponse:responseObject];
		}
	}];
}

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	return nil;
}

+ (SKLAPIClient *)apiClient {
	return [SKLAPIClient defaultClient];
}

#pragma mark Remote Refresh

- (void)refresh {
	SKLRemoteRequestInfo *info = [self remoteRefreshInfo];
	SKLAPIClient *apiClient = [[self class] apiClient];
	NSURLRequest *request = [apiClient requestWithMethod:@"GET" endPoint:info.path];
	[apiClient makeRequest:request
				completion:^(NSError *error, id responseObject) {
					if (error) {
						NSLog(@"Error refreshing %@: %@", self, error);
					} else {
						[self refreshWithRemoteResponse:responseObject];
					}
				}];
}

- (SKLRemoteRequestInfo *)remoteRefreshInfo {
	return nil;
}

- (void)refreshWithRemoteResponse:(NSDictionary *)response {
	NSManagedObjectContext *context = self.managedObjectContext;
	[context performBlock:^{
		[self updateWithRemoteObject:response];
	}];
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
		
        NSError *error;
        BOOL saved = [context save:&error];
        if (!saved) {
            NSLog(@"Error saving: %@", error);
        }
	}];
}

- (void)updateWithRemoteObject:(NSDictionary *)remoteObject {
	NSDictionary *mapping = [[self class] localToRemoteKeyMapping];
	[mapping enumerateKeysAndObjectsUsingBlock:^(id localKey, id remoteKey, BOOL *stop) {
		id remoteValue = remoteObject[remoteKey];
		if (remoteValue) {
			[self updateValueForLocalKey:localKey remoteValue:remoteValue];
		}
	}];
}

- (void)updateValueForLocalKey:(NSString *)localKey remoteValue:(id)remoteValue {
	id localValue = [self valueForKey:localKey];
	id formattedRemoteValue = [self localValueForKey:localKey RemoteValue:remoteValue];
	
	NSAttributeDescription *attribute = [self.entity attributesByName][localKey];
	NSRelationshipDescription *relationship = [self.entity relationshipsByName][localKey];
	NSAssert(attribute || relationship, @"%@ is neither an attribute nor a relationship for %@'s entity", localKey, NSStringFromClass(self.class));
	
	if (attribute) {
		BOOL remoteValuePresent = formattedRemoteValue != nil;
		BOOL localNotSameAsRemote = ![localValue isEqual:formattedRemoteValue];
		if (remoteValuePresent && localNotSameAsRemote) {
			[self setValue:formattedRemoteValue
					forKey:localKey];
		}
	} else if (relationship) {
		Class destinationClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);
		// common block to insert/update a destination class object
		SKLManagedObject *(^DestinationObjectForRemote)(NSDictionary *) = ^(NSDictionary *remoteObject) {
			SKLManagedObject *destinationObject = [destinationClass localObjectForRemoteObject:remoteObject];
			if (!destinationObject) {
				destinationObject = [destinationClass insertInContext:self.managedObjectContext];
			}
			[destinationObject updateWithRemoteObject:remoteObject];
			return destinationObject;
		};
		
		if (relationship.isToMany) {
			NSAssert([formattedRemoteValue isKindOfClass:[NSArray class]], @"Relationship %@ in %@ is to-many and should be remote updated with an array", localKey, NSStringFromClass(self.class));
			
			NSMutableSet *destinationLocalObjects = [NSMutableSet set];
			for (NSDictionary *remoteObject in formattedRemoteValue) {
				[destinationLocalObjects addObject:DestinationObjectForRemote(remoteObject)];
			}
			[self setValue:destinationLocalObjects
					forKey:localKey];
		} else {
			NSAssert([formattedRemoteValue isKindOfClass:[NSDictionary class]], @"Relationship %@ in %@ is to-one and should be remote updated with a dictionary", localKey, NSStringFromClass(self.class));
			
			[self setValue:DestinationObjectForRemote(formattedRemoteValue)
					forKey:localKey];
		}
	}
	
}

- (id)localValueForKey:(NSString *)localKey RemoteValue:(id)remoteValue {
	return remoteValue;
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

+ (instancetype)oneWith:(id)value for:(NSString *)key inContext:(NSManagedObjectContext *)context {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
	return [[self allInContext:context predicate:predicate] firstObject];
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
