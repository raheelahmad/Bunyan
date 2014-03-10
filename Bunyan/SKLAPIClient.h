//
//  SKLAPIClient.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

typedef void (^ SKLAPIResponseBlock)(NSError *error, id responseObject);

typedef NS_ENUM(NSInteger, ResponseErrorCode) {
    BadRequestCode,
    ServerErrorCode,
    NonJSONErrorCode,
    NSURLSessionErrorCode,
};

typedef NS_ENUM(NSInteger, HTTPBodySerializer) {
	NOSerializer,
	JSONSerializer,
	URLFormSerializer,
};

typedef NS_ENUM(NSInteger, ExpectHTTPResponse) {
	ExpectAnyString,
	ExpectJSONResponse,
};

extern NSString *const SKLOriginalNetworkingErrorKey;
extern NSString *const SKLOriginalNetworkingResponseStringKey;

@class SKLAPIRequest;

@interface SKLAPIClient : NSObject


- (id)initWithBaseURL:(NSString *)baseURL;

+ (void)setDefaultClientBaseURL:(NSString *)baseURL;
+ (instancetype)defaultClient;

- (NSURLRequest *)requestWithMethod:(NSString *)method
						 serializer:(HTTPBodySerializer)serializer
						   endPoint:(NSString *)endPoint
							 params:(NSDictionary *)params;

- (NSURLRequest *)requestWithMethod:(NSString *)method
						   endPoint:(NSString *)endPoint;

- (NSURLRequest *)requestWithMethod:(NSString *)method
						   endPoint:(NSString *)endPoint
							 params:(NSDictionary *)params;

- (NSString *)paramsAsQueryString:(NSDictionary *)params;

- (void)makeRequest:(NSURLRequest *)request completion:(SKLAPIResponseBlock)completion;
- (void)makeRequest:(NSURLRequest *)request expect:(ExpectHTTPResponse)expectation completion:(SKLAPIResponseBlock)completion;

@end
