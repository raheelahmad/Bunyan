//  SKLManagedObjectTests.h
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObjectTests.h"
#import "SKLTestableManagedObjectContext.h"
#import "SKLFakePerson.h"

@implementation SKLManagedObjectTests

#pragma mark Helper tests

- (void)testInsertInContext {
    SKLFakePerson *person = [SKLFakePerson insertInContext:self.context];
    XCTAssertNotNil(person, @"Should insert a new person");
    XCTAssertTrue([person isKindOfClass:[SKLFakePerson class]], @"Should insert entity of correct type");
}

- (void)testAllInContext {
    [SKLFakePerson insertInContext:self.context];
    [SKLFakePerson insertInContext:self.context];
    NSArray *all = [SKLFakePerson allInContext:self.context];
    XCTAssertEqual([all count], (NSUInteger)2, @"Should fetch same # of inserted objects");
}

- (void)testAllInContextWithPredicate {
    SKLFakePerson *personWithName = [SKLFakePerson insertInContext:self.context];
    personWithName.name = @"Aristotle";
    [SKLFakePerson insertInContext:self.context];
    NSPredicate *onlyNamePredicate = [NSPredicate predicateWithFormat:@"name != nil"];
    NSArray *onlyWithName = [SKLFakePerson allInContext:self.context
                                              predicate:onlyNamePredicate];
    XCTAssertEqualObjects([onlyWithName firstObject], personWithName, @"all fetches with predicate");
    XCTAssertEqual([onlyWithName count], (NSUInteger)1, @"all fetches with predicate");
}

- (void)testAny {
    [SKLFakePerson insertInContext:self.context];
    SKLFakePerson *anyPerson = [SKLFakePerson anyInContext:self.context];
    XCTAssertNotNil(anyPerson, @"Can fetch any object");
}

- (void)testOneWith {
	SKLFakePerson *person = [SKLFakePerson insertInContext:self.context];
	person.name = @"Maimonedes";
	[SKLFakePerson insertInContext:self.context];
	SKLFakePerson *oneWithName = [SKLFakePerson oneWith:@"Maimonedes" for:@"name" inContext:self.context];
	XCTAssertEqualObjects(oneWithName.name, @"Maimonedes", @"Should fetch oneWith:key:");
}

- (void)testController {
	NSFetchedResultsController *controller = [SKLFakePerson controllerInContext:self.context];
	NSFetchRequest *request = controller.fetchRequest;
	XCTAssertNotNil(request, @"Controller should have a request");
	XCTAssertEqualObjects(request.entityName, @"SKLFakePerson", @"Controller should have MO's entity");
	XCTAssertNil(request.predicate, @"Controller should not have a predicate");
	XCTAssertNotNil(request.sortDescriptors, @"Controller should have sort descriptors");
	XCTAssertEqualObjects(controller.managedObjectContext, self.context, @"Controller should not have the supplied context");
}



#pragma mark Basic tests

- (void)testPersonIsLoaded {
    SKLFakePerson *person = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SKLFakePerson class])
                                                          inManagedObjectContext:self.context];
    XCTAssertNotNil(person, @"Should insert entity from custom model");
    [self.context save:NULL];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SKLFakePerson class])];
    NSArray *result = [self.context executeFetchRequest:request error:NULL];
    XCTAssertEqual([result count], (NSUInteger)1, @"Should fetch inserted entity");
}

#pragma mark Setup

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLFakePerson class])
									   attributes:[SKLFakePerson attributesForEntity]
									];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[ personEntity ];
    return model;
}

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


@end
