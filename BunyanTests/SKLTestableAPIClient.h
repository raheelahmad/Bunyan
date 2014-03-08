//
//  SKLTestableAPIClient.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"

@class SKLMockURLSession;

@interface SKLTestableAPIClient : SKLAPIClient

@property (nonatomic) SKLMockURLSession *mockSession;

- (NSString *)lastRequestPath;

@end
