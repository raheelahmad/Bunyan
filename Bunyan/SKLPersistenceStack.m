//
//  SKLPersistenceStack.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/2/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLPersistenceStack.h"

@interface SKLPersistenceStack ()

@property (nonatomic, readwrite) NSManagedObjectContext *mainContext;
@property (nonatomic, readwrite) NSManagedObjectContext *importContext;

@property (nonatomic) NSURL *storeURL;
@property (nonatomic) NSURL *modelURL;

@end

@implementation SKLPersistenceStack

+ (SKLPersistenceStack *)defaultStack {
    static SKLPersistenceStack *_defaultStack;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultStack = [[SKLPersistenceStack alloc] init];
    });
    return _defaultStack;
}

+ (void)resetDefaultStack {
    SKLPersistenceStack *stack = [self defaultStack];
    NSError *error;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:stack.storeURL.path error:&error];
    if (!deleted) {
        NSLog(@"Error! Could not delete Core Data file when resetting stack: %@", error);
    }
    stack.mainContext = nil;
    stack.importContext = nil;
    BOOL setup = [stack setupStack:&error];
    if (!setup) {
        NSLog(@"Error setting up stack: %@", error);
    }
}

- (BOOL)setupStack:(NSError **)error {
	NSURL* documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ? : @"Bunyan";
	NSString *dbName = [NSString stringWithFormat:@"%@.sqlite", appName];
	self.storeURL = [documentsDirectory URLByAppendingPathComponent:dbName];
	self.modelURL = [[NSBundle mainBundle] URLForResource:appName withExtension:@"momd"];
	*error = [self setupManagedObjectContexts];
	return error != nil;
}

- (void)resetStack {
    NSError *error;
    BOOL removedStoreFile = [[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:&error];
    if (!removedStoreFile) {
        NSLog(@"Error removing store");
    }
    self.importContext = nil;
    self.mainContext = nil;
    [self setupManagedObjectContexts];
}

- (NSManagedObjectContext *)freshEditingContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    context.parentContext = [self mainContext];
    return context;
}

- (void)mainContextDidSave:(NSNotification *)notification {
	[self.importContext performBlock:^{
		[self.importContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

- (void)importContextDidSave:(NSNotification *)notification {
	[self.mainContext performBlock:^{
		[self.mainContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

- (NSError *)setupManagedObjectContexts {
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    NSPersistentStoreCoordinator *storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSError *error;
    id store = [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:self.storeURL
                                                    options:nil
                                                      error:&error];
    BOOL staleDB = !store;
    if (staleDB) {
        NSLog(@"Error setting up the store: %@", error);
        NSLog(@"!!!!!!!!! Deleting Store");
        BOOL removed = [[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:&error];
        store = [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                         URL:self.storeURL options:nil error:&error];
        if (!removed || !store) {
            NSLog(@"!!!! Error recovering from stale DB!!!: %@", error);
            return error;
        }
    }
	
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainContext.persistentStoreCoordinator = storeCoordinator;
    
    self.importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.importContext.persistentStoreCoordinator = storeCoordinator;
	self.importContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mainContextDidSave:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:self.mainContext];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(importContextDidSave:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:self.importContext];
    
	return error;
}

@end
