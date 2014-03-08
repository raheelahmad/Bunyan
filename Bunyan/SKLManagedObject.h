//
//  SKLManagedObject.h
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <CoreData/CoreData.h>

@class SKLRemoteRequestInfo, SKLAPIClient;

@interface SKLManagedObject : NSManagedObject

+ (instancetype)insertInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allInContext:(NSManagedObjectContext *)context predicate:(NSPredicate *)predicate;
+ (instancetype)anyInContext:(NSManagedObjectContext *)context;
+ (instancetype)oneWith:(id)value for:(NSString *)key inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *)controllerInContext:(NSManagedObjectContext *)context;

+ (NSManagedObjectContext *)mainContext;
+ (NSManagedObjectContext *)importContext;

// Remote fetches
+ (void)fetch;
+ (SKLAPIClient *)apiClient;
+ (void)updateWithRemoteFetchResponse:(NSArray *)response;
- (id)localValueForKey:(NSString *)localKey RemoteValue:(id)remoteValue;

+ (SKLRemoteRequestInfo *)remoteFetchInfo;
+ (NSDictionary *)localToRemoteKeyMapping;
+ (id)uniquingKey;
+ (NSArray *)sortDescriptors;

@end
