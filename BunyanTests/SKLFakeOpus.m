//
//  SKLFakeOpus.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLFakeOpus.h"
#import "SKLCoreDataTests.h"

@implementation SKLFakeOpus

@dynamic name, pageCount, remoteId, magnumOwner, favoriteOwner, owner;

+ (NSArray *)attributesForEntity {
	return @[
			 @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
			 @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
			 @{ SKLAttrNameKey : @"pageCount", SKLAttrTypeKey : @"int" }
			 ];
}

@end
