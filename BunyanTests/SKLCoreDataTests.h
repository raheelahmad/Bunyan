//
//  INManagedObjectTests.h
//  Ingredient1
//
//  Created by Raheel Ahmad on 11/1/13.
//  Copyright (c) 2013 Ingredient1. All rights reserved.
//

#import <XCTest/XCTest.h>

extern NSString *const SKLModelNameKey;
extern NSString *const SKLAttrNameKey;
extern NSString *const SKLAttrTypeKey;

@interface SKLCoreDataTests : XCTestCase

@property (nonatomic) NSManagedObjectContext *context;

/**
 * Default implementation loads the project model.
 * Override to provide a custom model with custom entities.
 */
- (NSManagedObjectModel *)loadCustomModel;

- (NSEntityDescription *)entityWithName:(NSString *)name attributes:(NSArray *)attributes;
void addRelationships(NSEntityDescription *source, NSEntityDescription *destination,
					  NSString *forwardName, NSString *reverseName, BOOL forwardIsToMany, BOOL reverseIsToMany);

@end
