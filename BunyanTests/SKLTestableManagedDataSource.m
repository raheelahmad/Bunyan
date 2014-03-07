//
//  SKLTestableManagedDataSource.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/6/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLTestableManagedDataSource.h"

@interface SKLManagedDataSource ()
- (id)controller;
@end

@implementation SKLTestableManagedDataSource

- (id)controller {
    return self.mockResultsController ? : [super controller];
}

@end
