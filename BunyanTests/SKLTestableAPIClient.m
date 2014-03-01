//
//  SKLTestableAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLTestableAPIClient.h"

@interface SKLAPIClient ()

- (id)session;

@end

@implementation SKLTestableAPIClient

- (id)session {
	return self.mockSession ? : [super session];
}

@end
