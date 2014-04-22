//
//  SKLPersonFetcher.h
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLModelFetcher.h"

@class SKLTestableAPIClient;

@interface SKLPersonFetcher : SKLModelFetcher

@property (nonatomic) NSManagedObjectContext *mockImportContext;
@property (nonatomic) SKLTestableAPIClient *mockApiClient;

@end
