//
//  SKLFakeOpus.h
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObject.h"

@class SKLFakePerson;

@interface SKLFakeOpus : SKLManagedObject

@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *pageCount;
@property (nonatomic) SKLFakePerson *magnumOwner;
@property (nonatomic) SKLFakePerson *favoriteOwner;
@property (nonatomic) SKLFakePerson *owner;

+ (NSArray *)attributesForEntity;

@end
