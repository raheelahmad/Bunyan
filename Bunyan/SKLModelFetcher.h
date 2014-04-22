//
//  SKLModelFetcher.h
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

@class SKLAPIClient, SKLAPIRequest, SKLManagedObject;

typedef void (^ SKLFetchResponseBlock)(NSError *error);

@interface SKLModelFetcher : NSObject

#pragma mark Prerequisites

/// The class that will be fetched
- (Class)managedObjectClass;
/// The mapping between the local managed object keys are remote object dictionary
- (NSDictionary *)localToRemoteKeyMapping;
/// The uniquing key for local managed objects
- (NSString *)uniquingKey;

/// 
- (void)updateLocalObject:(SKLManagedObject *)localObject withRemoteObject:(NSDictionary *)remoteObject;

/// Returns a matching local object for a remote object
- (SKLManagedObject *)localObjectForRemoteObject:(NSDictionary *)remoteObject inContext:(NSManagedObjectContext *)context;

/// Allows formatting when setting a local value with a remote value
- (id)localValueForKey:(NSString *)localKey remoteValue:(id)remoteValue;

/// 
- (SKLModelFetcher *)fetcherForRelationship:(NSString *)relationKey;

/// The workhorse method that finally updates the local object, given its local key, with a corresponding remote value
- (void)updateValueForObject:(SKLManagedObject *)object localKey:(NSString *)localKey remoteValue:(id)remoteValue;

- (BOOL)shouldReplaceWhenUpdatingToManyRelationship:(NSString *)relationship;

#pragma mark Fetch

- (void)fetchFromRemote;
- (void)fetchFromRemoteWithCompletion:(SKLFetchResponseBlock)completion;
- (void)fetchFromRemoteWithInfo:(SKLAPIRequest *)request completion:(SKLFetchResponseBlock)completion;

- (SKLAPIRequest *)remoteFetchInfo;
- (BOOL)shouldDeleteStaleLocalObjects;

#pragma mark Refresh

- (void)refreshObjectFromRemote:(SKLManagedObject *)object;
- (void)refreshObjectFromRemote:(SKLManagedObject *)object withInfo:(SKLAPIRequest *)request;
- (void)refreshObjectFromRemote:(SKLManagedObject *)object withInfo:(SKLAPIRequest *)request completion:(SKLFetchResponseBlock)completion;

- (SKLAPIRequest *)remoteRefreshInfoForObject:(SKLManagedObject *)object;

@end
