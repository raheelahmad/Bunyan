//
//  SKLURLRequest.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"

// the encoding used for a POST (rather, any non-GET) request's body
typedef NS_ENUM(NSInteger, SKLBodyEncoding) {
	SKLFormURLBodyEncoding, // transform to query params, encode as data, and set Content-Type:x-www-form-urlencoded
	SKLJSONBodyEncoding, // transform to JSON, encode as data, and set Content-Type:x-www-form-urlencoded
};

typedef NS_ENUM(NSInteger, SKLResponseParsing) {
	SKLNoResponseParsing,
	SKLStringResponseParsing,
	SKLJSONResponseParsing,
};

@interface SKLAPIRequest : NSObject<NSCopying>

@property (nonatomic) NSString *endPoint;
@property (nonatomic) NSString *method;
@property (nonatomic) NSDictionary *params;
@property (nonatomic) NSDictionary *body;
@property (nonatomic) NSDictionary *headers;
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;

// Options
@property (nonatomic) SKLBodyEncoding bodyEncoding;
@property (nonatomic) SKLResponseParsing responseParsing;

// In case a different content-type header is desired from the one used for encoding
@property (nonatomic) NSString *contentType;

// The response should be wrapped in this key before passing it to the model
@property (nonatomic) NSString *responseWrappingKey;
// The response should be unwrapped in this key before passing it to the model
@property (nonatomic) NSString *responseUnwrappingKeypath;

@property (nonatomic, copy) SKLAPIResponseBlock completionBlock;

/// Useful for keeping track of chained requests (APIResponse holds its APIRequest)
@property (nonatomic) SKLAPIResponse *previousResponse;

// Constructors

// DEFAULTS:
// Params encoding: form-url encoding
// Response parsing: JSON
+ (instancetype)with:(NSString *)endPoint
			  method:(NSString *)method
			  params:(NSDictionary *)params
				body:(NSDictionary *)body;

@end
