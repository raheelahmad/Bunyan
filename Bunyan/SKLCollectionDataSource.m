//
//  SKLCollectionDataSource.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLCollectionDataSource.h"
#import "SKLManagedObject.h"
#import <UIKit/UICollectionViewLayout.h>

@interface SKLCollectionDataSource ()

@property (nonatomic, readwrite) NSFetchedResultsController *controller;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) Class modelClass;
@property (nonatomic) Class cellClass;

@property (nonatomic) NSMutableArray *sectionChanges;
@property (nonatomic) NSMutableArray *itemChanges;

@end

@implementation SKLCollectionDataSource

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	NSArray *sections = [self.controller sections];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return [[self.controller sections] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.cellClass)
																		   forIndexPath:indexPath];
    id object = [self.controller objectAtIndexPath:indexPath];
	[self.delegate configureCell:cell withObject:object];
	
	return cell;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	self.sectionChanges = [NSMutableArray array];
	self.itemChanges = [NSMutableArray array];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
	NSMutableDictionary *changeObject = [NSMutableDictionary dictionary];
    switch (type) {
        case NSFetchedResultsChangeDelete:
			changeObject[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeInsert:
			changeObject[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeMove:
			changeObject[@(type)] = @[ indexPath, newIndexPath ];
            break;
        case NSFetchedResultsChangeUpdate:
			changeObject[@(type)] = indexPath;
            break;
            
        default:
            break;
    }
	[self.itemChanges addObject:changeObject];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	NSDictionary *changeObject = @{ @(type) : @(sectionIndex) };
	[self.sectionChanges addObject:changeObject];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.collectionView performBatchUpdates:^{
		for (NSDictionary *itemChange in self.itemChanges) {
			NSAssert([itemChange count] == 1, @"Should have 1 key in change dict");
			NSInteger type = [[[itemChange allKeys] firstObject] integerValue];
			switch (type) {
				case NSFetchedResultsChangeDelete:
					[self.collectionView deleteItemsAtIndexPaths:@[ itemChange[@(type)] ]];
					break;
				case NSFetchedResultsChangeInsert:
					[self.collectionView insertItemsAtIndexPaths:@[ itemChange[@(type)] ] ];
					break;
				case NSFetchedResultsChangeMove:
				{
					NSIndexPath *fromPath = [itemChange[@(type)] objectAtIndex:0];
					NSIndexPath *toPath = [itemChange[@(type)] objectAtIndex:1];
					[self.collectionView moveItemAtIndexPath:fromPath  toIndexPath:toPath];
					break;
				}
				case NSFetchedResultsChangeUpdate:
					[self.collectionView reloadItemsAtIndexPaths:@[ itemChange[@(type)] ]];
					break;
				default:
					break;
			}
		}
		
		for (NSDictionary *sectionChange in self.sectionChanges) {
			NSAssert([sectionChange count] == 1, @"Should have 1 key in change dict");
			NSNumber *typeObject = [[sectionChange allKeys] firstObject];
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[sectionChange[typeObject] integerValue]];
			switch ([typeObject integerValue]) {
				case NSFetchedResultsChangeInsert:
					[self.collectionView insertSections:indexSet];
					break;
				case NSFetchedResultsChangeDelete:
					[self.collectionView deleteSections:indexSet];
					break;
					
				default:
					break;
			}
		}
	} completion:^(BOOL finished) {
		
	}];
}

#pragma mark Helpers for Subclasses

- (NSPredicate *)collectionPredicate {
    return nil;
}

- (NSArray *)collectionSortDescriptors {
	return [self.modelClass sortDescriptors];
}

- (NSString *)collectionSectionKeyPath {
	return [self.modelClass defaultSectionKeyPath];
}

#pragma mark Public Helpers

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
	return [self.controller objectAtIndexPath:indexPath];
}

#pragma mark Initialization

- (void)setupCollectionView:(UICollectionView *)collectionView {
    collectionView.dataSource = self;
    self.collectionView = collectionView;
    [self setupController];
}

- (void)setupController {
	self.controller.delegate = nil;
	self.controller = nil;
	
    NSManagedObjectContext *context = [self.modelClass mainContext];
	NSString *sectionKeyPath = [self collectionSectionKeyPath];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self modelClass])];
	request.predicate = [self collectionPredicate];
    request.sortDescriptors = [self collectionSortDescriptors];
	self.controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
														  managedObjectContext:context
															sectionNameKeyPath:sectionKeyPath
																	 cacheName:nil];
    self.controller.delegate = self;
    
    NSError *fetchError;
    BOOL fetched = [self.controller performFetch:&fetchError];
    if (!fetched) {
        NSLog(@"Error fetching: %@", fetchError);
    }
}

- (void)reloadController {
    [self setupController];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.collectionView addSubview:[UIView new]];
		[self.collectionView reloadData];
		[self.collectionView.collectionViewLayout invalidateLayout];
	});
}

- (id)initWithModelClass:(Class)modelClass cellCalss:(Class)cellClass {
	self = [super init];
	if (self) {
		self.modelClass = modelClass;
		self.cellClass = cellClass;
	}
	return self;
}

@end
