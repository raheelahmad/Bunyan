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

// Remote fetches
+ (void)fetch;
+ (SKLRemoteRequestInfo *)remoteFetchInfo;
+ (SKLAPIClient *)apiClient;

@end
