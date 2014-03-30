//
//  SKLURLRequest.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIRequest.h"

@implementation SKLAPIRequest

+ (instancetype)with:(NSString *)endPoint
			  method:(NSString *)method
			  params:(NSDictionary *)params
				body:(NSDictionary *)body {
	SKLAPIRequest *request = [[self alloc] init];
	request.endPoint = endPoint;
	request.method = method;
	request.params = params;
	request.body = body;
    
    request.bodyEncoding = SKLFormURLBodyEncoding;
    request.responseParsing = SKLJSONResponseParsing;
    
	return request;
}

- (id)copyWithZone:(NSZone *)zone {
	typeof(self) request = [[[self class] allocWithZone:zone] init];
	
	request.endPoint = [self.endPoint copy];
	request.method = [self.method copy];
	request.params = [self.params copy];
	request.body = [self.body copy];
	request.headers = [self.headers copy];
	request.bodyEncoding = self.bodyEncoding;
	request.responseParsing = self.responseParsing;
	request.contentType = self.contentType;
	request.responseWrappingKey = self.responseWrappingKey;
	request.previousResponse = self.previousResponse;
	
	return request;
}

@end
