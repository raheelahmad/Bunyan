//
//  SKLTestableAPIClient.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"

@interface SKLTestableAPIClient : SKLAPIClient

@property (nonatomic) id mockSession;

@end
