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
			  params:(NSDictionary *)params {
	SKLAPIRequest *request = [[self alloc] init];
	request.endPoint = endPoint;
	request.method = method;
	request.params = params;
    
    request.paramsEncoding = SKLFormURLParamsEncoding;
    request.responseParsing = SKLJSONResponseParsing;
    
	return request;
}

@end
