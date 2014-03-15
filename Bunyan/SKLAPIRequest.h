//
//  SKLURLRequest.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// the encoding used for a POST (rather, any non-GET) request's body
typedef NS_ENUM(NSInteger, SKLParamsEncoding) {
	SKLFormURLParamsEncoding, // transform to query params, encode as data, and set Content-Type:x-www-form-urlencoded
	SKLJSONParamsEncoding, // transform to JSON, encode as data, and set Content-Type:x-www-form-urlencoded
	SKLQueryParamsEncoding, // use query params in URL (no body)
};

typedef NS_ENUM(NSInteger, SKLResponseParsing) {
	SKLStringResponseParsing,
	SKLJSONResponseParsing,
};

@interface SKLAPIRequest : NSObject

@property (nonatomic) NSString *endPoint;
@property (nonatomic) NSString *method;
@property (nonatomic) NSDictionary *params;

// Options
@property (nonatomic) SKLParamsEncoding paramsEncoding;
@property (nonatomic) SKLResponseParsing responseParsing;

// In case a different content-type header is desired from the one used for encoding
@property (nonatomic) NSString *contentType;

// The response should be wrapped in this key before passing it to the model
#warning Add test for remoteWrappingKey
@property (nonatomic) NSString *responseWrappingKey;

// Constructors

// DEFAULTS:
// Params encoding: form-url encoding
// Response parsing: JSON
+ (instancetype)with:(NSString *)endPoint
			  method:(NSString *)method
			  params:(NSDictionary *)params;

@end
