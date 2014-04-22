//
//  SKLFakePerson.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLFakePerson.h"
#import "SKLCoreDataTests.h"

@implementation SKLFakePerson

@dynamic name, location, birthdate, remoteId, magnumOpus, opuses, favoriteOpuses;

+ (NSArray *)attributesForEntity {
	return @[
			 @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
			 @{ SKLAttrNameKey : @"location", SKLAttrTypeKey : @"string" },
			 @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
			 @{ SKLAttrNameKey : @"birthdate", SKLAttrTypeKey : @"date" }
			 ];
}

+ (NSArray *)sortDescriptors {
	return @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
}

@end
