//
//  SKLManagedObject.h
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void (^ SKLFetchResponseBlock)(NSError *error);

@class SKLAPIRequest, SKLAPIResponse, SKLAPIClient;

@interface SKLManagedObject : NSManagedObject

+ (instancetype)insertInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allInContext:(NSManagedObjectContext *)context predicate:(NSPredicate *)predicate;
+ (instancetype)anyInContext:(NSManagedObjectContext *)context;
+ (instancetype)oneWith:(id)value for:(NSString *)key inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *)controllerInContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *)controllerWithPredicate:(NSPredicate *)predicate
												context:(NSManagedObjectContext *)context;

+ (NSManagedObjectContext *)mainContext;
+ (NSManagedObjectContext *)importContext;
+ (void)saveMainContext;

// -- Remote fetch

+ (void)fetchFromRemote;
+ (void)fetchFromRemoteWithInfo:(SKLAPIRequest *)request completion:(SKLFetchResponseBlock)completion;
+ (void)fetchFromRemoteWithCompletion:(SKLFetchResponseBlock)completion;
+ (SKLAPIClient *)apiClient;
+ (void)updateWithRemoteFetchResponse:(SKLAPIResponse *)response;
- (void)updateWithRemoteObject:(NSDictionary *)remoteObject;
+ (BOOL)shouldDeleteStaleLocalObjects;
- (BOOL)shouldReplaceWhenUpdatingToManyRelationship:(NSString *)relationship;
- (id)localValueForKey:(NSString *)localKey RemoteValue:(id)remoteValue;

- (void)updateValueForLocalKey:(NSString *)localKey remoteValue:(id)remoteValue;

+ (SKLAPIRequest *)remoteFetchInfo;
+ (NSDictionary *)localToRemoteKeyMapping;
+ (id)uniquingKey;
+ (instancetype)localObjectForRemoteObject:(NSDictionary *)remoteObject inContext:(NSManagedObjectContext *)context;
+ (NSArray *)sortDescriptors;
+ (NSString *)defaultSectionKeyPath;

// -- Remote refresh

- (void)refreshFromRemote;
- (void)refreshFromRemoteWithInfo:(SKLAPIRequest *)request;
- (void)refreshWithRemoteResponse:(NSDictionary *)response;

- (SKLAPIRequest *)remoteRefreshInfo;

@end
