//
//  SKLFakePerson.h
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLManagedObject.h"

@class SKLFakeOpus;

@interface SKLFakePerson : SKLManagedObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *location;
@property (nonatomic) NSDate *birthdate;
@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) SKLFakeOpus *magnumOpus;
@property (nonatomic) NSSet *opuses;
@property (nonatomic) NSSet *favoriteOpuses;

+ (NSArray *)attributesForEntity;

@end
