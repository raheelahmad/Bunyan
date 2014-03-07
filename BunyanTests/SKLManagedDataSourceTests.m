//
//  SKLManagedDataSourceTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/5/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLTestableManagedDataSource.h"

@interface SKLFakeResultsController : NSObject
@property (nonatomic) id sections;
- (id)objectAtIndexPath:(id)indexPath;
@end

@implementation SKLFakeResultsController

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sections = self.sections;
    id<NSFetchedResultsSectionInfo> section = sections[indexPath.section];
    return [section objects][indexPath.row];
}

@end

@interface SKLFakeSectionInfo : NSObject<NSFetchedResultsSectionInfo>
@property (nonatomic) NSArray *objects;
@end

@implementation SKLFakeSectionInfo
@synthesize objects;
- (NSUInteger)numberOfObjects { return [objects count]; }
@end

// ---

@interface SKLManagedDataSourceTests : XCTestCase

@property (nonatomic) SKLTestableManagedDataSource *dataSource;
@property (nonatomic) SKLFakeResultsController *resultsController;

@end

@implementation SKLManagedDataSourceTests

- (void)testNumberOfSections {
    NSInteger sections = [self.dataSource numberOfSectionsInTableView:nil];
    XCTAssertEqual(sections, (NSInteger)2, @"Number of sections should be correct");
}

- (void)testNumberOfRows {
	NSInteger rowsInSectionZero = [self.dataSource tableView:nil numberOfRowsInSection:0];
	NSInteger rowsInSectionOne = [self.dataSource tableView:nil numberOfRowsInSection:1];
    XCTAssertEqual(rowsInSectionZero, (NSInteger)2, @"Number of rows should be correct");
    XCTAssertEqual(rowsInSectionOne, (NSInteger)3, @"Number of rows should be correct");
}

- (void)setUp {
	[super setUp];
	
	self.dataSource = [[SKLTestableManagedDataSource alloc] initWithModelClass:[SKLFakeResultsController class]
                                                             cellCalss:nil];
    
	self.resultsController = [[SKLFakeResultsController alloc] init];
    SKLFakeSectionInfo *section1 = [[SKLFakeSectionInfo alloc] init];
    section1.objects = @[ @"Socrates", @"Ibn Sina" ];
    SKLFakeSectionInfo *section2 = [[SKLFakeSectionInfo alloc] init];
    section2.objects = @[ @"Augustine", @"Mosheh ben Maimon", @"Descartes" ];
    self.resultsController.sections = @[ section1, section2 ];
    
    self.dataSource.mockResultsController = self.resultsController;
}

@end
