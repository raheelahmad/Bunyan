//
//  SKLTestableManagedObjectContext.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/2/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLTestableManagedObjectContext.h"

@implementation SKLTestableManagedObjectContext

- (void)performBlock:(void (^)())block {
	if (self.shouldPerformBlockAsSync) {
		[self performBlockAndWait:block];
	} else {
		[super performBlock:block];
	}
}

@end
