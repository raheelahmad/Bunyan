//
//  SKLManagedDataSource.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/5/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedDataSource.h"

@interface SKLManagedDataSource ()

@property (nonatomic) NSFetchedResultsController *controller;

@end

@implementation SKLManagedDataSource

#pragma mark Initialization

- (id)initWithResultsController:(NSFetchedResultsController *)controller {
	if (self = [super init]) {
		_controller = controller;
	}
	return self;
}

@end
