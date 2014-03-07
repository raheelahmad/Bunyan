//
//  SKLManagedDataSourceTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/5/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLManagedDataSource.h"

@interface SKLFakeResultsController : NSObject
@property (nonatomic) id sections;
- (id)objectAtIndexPath:(id)indexPath;
@end

@implementation SKLFakeResultsController

@end

// ---

@interface SKLManagedDataSourceTests : XCTestCase

@property (nonatomic) SKLManagedDataSource *dataSource;
@property (nonatomic) SKLFakeResultsController *resultsController;

@end

@implementation SKLManagedDataSourceTests

- (void)testNumberOfRows {
	[self.dataSource tableView:nil numberOfRowsInSection:1];
}

- (void)setUp {
	[super setUp];
	
	self.resultsController = [[SKLFakeResultsController alloc] init];
	self.dataSource = [[SKLManagedDataSource alloc] initWithResultsController:(NSFetchedResultsController *)self.resultsController];
}

@end
