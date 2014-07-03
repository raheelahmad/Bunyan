//
//  SKLPersistenceStack.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/2/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKLPersistenceStack : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;
@property (nonatomic, readonly) NSManagedObjectContext *importContext;
- (NSManagedObjectContext *)freshEditingContext;

+ (SKLPersistenceStack *)defaultStack;
+ (void)resetDefaultStack;
- (BOOL)setupStack:(NSError **)error;

@end
