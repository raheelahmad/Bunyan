//
//  SKLManagedObject.m
//  Khasoos
//
//  Created by Raheel Ahmad on 2/13/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObject.h"

@implementation SKLManagedObject

+ (instancetype)insertInContext:(NSManagedObjectContext *)context {
    id item =  [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class])
                                             inManagedObjectContext:context];
    return item;
}

+ (NSArray *)allInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
    NSError *error;
    NSArray *result = [context executeFetchRequest:request
                                             error:&error];
    if (!result) {
        NSLog(@"Error when fetching %@: %@", NSStringFromClass(self), error);
    }

    return result;
}

@end
