//
//  SKLTestableManagedObjectContext.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/2/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface SKLTestableManagedObjectContext : NSManagedObjectContext

@property (nonatomic) BOOL shouldPerformBlockAsSync;

@end
