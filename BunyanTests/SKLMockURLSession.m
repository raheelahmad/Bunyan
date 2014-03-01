//
//  SKLMockURLSession.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLMockURLSession.h"

@interface SKLMockURLSession ()

@property (nonatomic, readwrite) NSURLRequest *lastRequest;

@end

@implementation SKLMockURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
	self.lastRequest = request;
	self.lastCompletionHandler = completionHandler;
	return nil;
}

@end
