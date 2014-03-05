//
//  NSManagedObjectContext+Additions.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/2/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "NSManagedObjectContext+Additions.h"

@implementation NSManagedObjectContext (Additions)

- (void)save {
	NSError *error;
	BOOL saved = [self save:&error];
	if (!saved) {
		NSLog(@"Error saving: %@", error);
	}
}

@end
