//
//  INManagedObjectTests.m
//  Ingredient1
//
//  Created by Raheel Ahmad on 11/1/13.
//  Copyright (c) 2013 Ingredient1. All rights reserved.
//

#import "SKLCoreDataTests.h"
#import "SKLTestableManagedObjectContext.h"

NSString *const SKLModelNameKey = @"SKLModelNameKey";
NSString *const SKLAttrNameKey = @"SKLAttrNameKey";
NSString *const SKLAttrTypeKey = @"SKLAttrTypeKey";

@interface SKLCoreDataTests ()

@property (nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic) NSManagedObjectModel *model;
@property (nonatomic) NSPersistentStore *store;

@end

@implementation SKLCoreDataTests

#pragma mark - Helpers

- (NSEntityDescription *)entityWithName:(NSString *)name attributes:(NSArray *)attributes {
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    entity.name = name;
    entity.managedObjectClassName = name;
    
	NSMutableArray *properties = [NSMutableArray array];
	for (NSDictionary *attrInfo in attributes) {
		NSAttributeDescription *attr = [[NSAttributeDescription alloc] init];
		attr.name = attrInfo[SKLAttrNameKey];
		NSString *type = attrInfo[SKLAttrTypeKey];
		if ([type isEqualToString:@"string"]) {
			attr.attributeType = NSStringAttributeType;
			attr.attributeValueClassName = NSStringFromClass([NSString class]);
		} else if ([type isEqualToString:@"int"]) {
			attr.attributeType = NSInteger32AttributeType;
			attr.attributeValueClassName = NSStringFromClass([NSNumber class]);
		}
		[properties addObject:attr];
	}
    
    entity.properties = properties;
	
	return entity;
}

void addRelationships(NSEntityDescription *source, NSEntityDescription *destination,
														  NSString *forwardName, NSString *reverseName, BOOL forwardIsToMany, BOOL reverseIsToMany) {
	NSRelationshipDescription *forwardRelationship = [[NSRelationshipDescription alloc] init];
	forwardRelationship.destinationEntity = destination;
	forwardRelationship.name = forwardName;
	NSRelationshipDescription *reverseRelationship = [[NSRelationshipDescription alloc] init];
	reverseRelationship.destinationEntity = source;
	reverseRelationship.name = reverseName;
	
	forwardRelationship.inverseRelationship = reverseRelationship;
	reverseRelationship.inverseRelationship = forwardRelationship;
	
	NSArray *existingForwardRelationships = source.properties;
	NSMutableArray *newForwardRelationships = [NSMutableArray arrayWithObject:forwardRelationship];
	[newForwardRelationships addObjectsFromArray:existingForwardRelationships];
	source.properties = newForwardRelationships;
	
	NSArray *existingReverseRelationships = destination.properties;
	NSMutableArray *newReverseRelationships = [NSMutableArray arrayWithObject:reverseRelationship];
	[newReverseRelationships addObjectsFromArray:existingReverseRelationships];
	destination.properties = newReverseRelationships;
	
	// use the toMany BOOL
	if (forwardIsToMany) {
		forwardRelationship.maxCount = -1;
	} else {
		forwardRelationship.maxCount = 1;
	}
	
	if (reverseIsToMany) {
		reverseRelationship.maxCount = -1;
	} else {
		reverseRelationship.maxCount = 1;
	}
}

- (NSManagedObjectModel *)loadModel {
    NSManagedObjectModel *model = [self loadCustomModel];
    if (!model) {
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return model;
}

- (NSManagedObjectModel *)loadCustomModel {
    return nil;
}

#pragma mark - Testing

- (void)testCanLoadAManagedObject {
    if (self.class != [SKLCoreDataTests class]) {
        // not for subclasses
        return;
    }
    XCTAssertNotNil(self.model, @"Should load the model");
    XCTAssertNotNil(self.coordinator, @"Should setup the coordinator");
    XCTAssertNotNil(self.store, @"Should add an in-memory store");
}

- (void)setUp
{
    [super setUp];
    self.model = [self loadModel];
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    self.store = [self.coordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                configuration:nil
                                                          URL:nil
                                                      options:nil error:NULL];
    self.context = [[SKLTestableManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.context.persistentStoreCoordinator = self.coordinator;
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

@end
