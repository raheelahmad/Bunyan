//
//  SKLTestableAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLTestableAPIClient.h"
#import "SKLMockURLSession.h"

@interface SKLAPIClient ()

- (id)session;

@end

@implementation SKLTestableAPIClient

- (id)session {
	return self.mockSession ? : [super session];
}

- (NSString *)lastRequestPath {
	NSURLRequest *requestMade = self.mockSession.lastRequest;
	NSString *path = [[NSURLComponents componentsWithURL:requestMade.URL resolvingAgainstBaseURL:NO] path];
	return path;
}

@end
