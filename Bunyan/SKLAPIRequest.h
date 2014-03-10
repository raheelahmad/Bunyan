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
};

typedef NS_ENUM(NSInteger, SKLResponseParsing) {
	SKLStringResponseParsing,
	SKLJSONResponseParsing,
};

@interface SKLAPIRequest : NSObject

@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic) SKLParamsEncoding paramsEncoding;
@property (nonatomic) SKLResponseParsing responseParsing;

+ (instancetype)requestWithURL:(NSURL *)URL;

@end
