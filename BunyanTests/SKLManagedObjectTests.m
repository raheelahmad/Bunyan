//  SKLManagedObjectTests.h
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObjectTests.h"
#import "SKLTestPerson.h"

@implementation SKLManagedObjectTests

#pragma mark Helper tests

- (void)testInsertInContext {
    SKLTestPerson *person = [SKLTestPerson insertInContext:self.context];
    XCTAssertNotNil(person, @"Should insert a new person");
    XCTAssertTrue([person isKindOfClass:[SKLTestPerson class]], @"Should insert entity of correct type");
}

- (void)testAllInContext {
    [SKLTestPerson insertInContext:self.context];
    [SKLTestPerson insertInContext:self.context];
    NSArray *all = [SKLTestPerson allInContext:self.context];
    XCTAssertEqual([all count], (NSUInteger)2, @"Should fetch same # of inserted objects");
}

#pragma mark Basic tests

- (void)testPersonIsLoaded {
    SKLTestPerson *person = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SKLTestPerson class])
                                                          inManagedObjectContext:self.context];
    XCTAssertNotNil(person, @"Should insert entity from custom model");
    [self.context save:NULL];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SKLTestPerson class])];
    NSArray *result = [self.context executeFetchRequest:request error:NULL];
    XCTAssertEqual([result count], (NSUInteger)1, @"Should fetch inserted entity");
}

#pragma mark Setup

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLTestPerson class])
									   attributes:@[
													@{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
													@{ SKLAttrNameKey : @"age", SKLAttrTypeKey : @"int" },
													@{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"string" }
													]
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
