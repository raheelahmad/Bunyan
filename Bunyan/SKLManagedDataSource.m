//
//  SKLManagedDataSource.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/5/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedDataSource.h"
#import "SKLManagedObject.h"

@interface SKLManagedDataSource ()<NSFetchedResultsControllerDelegate>

@property (nonatomic) NSFetchedResultsController *controller;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) Class modelClass;
@property (nonatomic) Class cellClass;

@end

@implementation SKLManagedDataSource

#pragma mark Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray *sections = [self.controller sections];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.controller sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self.cellClass)];
    
    id object = [self.controller objectAtIndexPath:indexPath];
    [self.delegate configureCell:cell withObject:object];
    
    return cell;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark Initialization

- (void)setupTableView:(UITableView *)tableView {
    [tableView registerClass:self.cellClass forCellReuseIdentifier:NSStringFromClass(self.cellClass)];
    tableView.dataSource = self;
    self.tableView = tableView;
    
    NSManagedObjectContext *context = [self.modelClass mainContext];
    self.controller = [self.modelClass controllerInContext:context];
    self.controller.delegate = self;
    
    NSError *fetchError;
    BOOL fetched = [self.controller performFetch:&fetchError];
    if (!fetched) {
        NSLog(@"Error fetching: %@", fetchError);
    }
}

- (id)initWithModelClass:(Class)modelClass cellCalss:(Class)cellClass {
	if (self = [super init]) {
        self.modelClass = modelClass;
        self.cellClass = cellClass;
	}
	return self;
}

@end
