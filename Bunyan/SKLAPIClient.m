//
//  SKLAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"

@interface SKLAPIClient ()

@property (nonatomic) NSString *baseAPIURL;
@property (nonatomic) NSURLSession *session;

@end

static NSString *const SKLAPIErrorDomain = @"SKLAPIErrorDomain";
NSString *const SKLOriginalNetworkingErrorKey = @"SKLOriginalNetworkingErrorKey";
NSString *const SKLOriginalNetworkingResponseStringKey = @"SKLOriginalNetworkingResponseStringKey";

@implementation SKLAPIClient

#pragma mark Initialization

+ (void)setDefaultClientBaseURL:(NSString *)baseURL {
	[SKLAPIClient defaultClient].baseAPIURL = baseURL;
}

+ (instancetype)defaultClient {
	static SKLAPIClient *_defaultClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_defaultClient = [[self alloc] initWithBaseURL:nil];
	});
	return _defaultClient;
}

- (id)initWithBaseURL:(NSString *)baseURL {
	self = [super init];
	if (self) {
		self.baseAPIURL = baseURL;
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		self.session = [NSURLSession sessionWithConfiguration:configuration];
	}
	return self;
}

#pragma mark Composing requests

- (NSURLRequest *)requestWithMethod:(NSString *)method endPoint:(NSString *)endPoint {
	return [self requestWithMethod:method
						  endPoint:endPoint
							params:nil];
}

- (NSURLRequest *)requestWithMethod:(NSString *)method endPoint:(NSString *)endPoint params:(NSDictionary *)params {
	return [self requestWithMethod:method
						serializer:NOSerializer
						  endPoint:endPoint
							params:params];
}

- (NSURLRequest *)requestWithMethod:(NSString *)method
						 serializer:(HTTPBodySerializer)serializer
						   endPoint:(NSString *)endPoint
							 params:(NSDictionary *)params {
	NSString *urlString = [self URLWithEndpoint:endPoint];
    BOOL isPOSTRequest = [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"];
    BOOL isGETRequest = [method isEqualToString:@"GET"];
    NSParameterAssert(isGETRequest || isPOSTRequest);
	if ([params count]) {
		if (isGETRequest) {
			urlString = [urlString stringByAppendingFormat:@"%@?%@", urlString, [self paramsAsQueryString:params]];
		}
	}
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	if (isPOSTRequest && [params count]) {
		if (serializer == JSONSerializer) {
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			NSError *error;
			request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params
															   options:0 error:&error];
			if (!request.HTTPBody) {
				NSLog(@"Error constructing HTTP body: %@", error);
				request = nil;
			}
		} else {
			// for now not everything except JSON serialized, is assumed
			[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			request.HTTPBody = [[self paramsAsQueryString:params] dataUsingEncoding:NSUTF8StringEncoding];
		}
	}
	
	request.HTTPMethod = method;
	
	return request;
}

- (NSString *)URLWithEndpoint:(NSString *)path {
    NSParameterAssert([path length]);
    NSString *URLString = path;
    BOOL containsFullURL = [[path substringToIndex:4] isEqualToString:@"http"];
    if (!containsFullURL) {
        URLString = [NSString stringWithFormat:@"%@%@", [self baseAPIURL], path];
    }
    return URLString;
}

- (NSString *)paramsAsQueryString:(NSDictionary *)params {
    NSMutableArray *paramsArray = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSArray class]]) {
            for (NSString *subValue in value) {
                [paramsArray addObject:[NSString stringWithFormat:@"%@[]=%@", key, subValue]];
            }
        } else {
            [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        }
    }];
    NSString *paramsString = [paramsArray componentsJoinedByString:@"&"];
    return [paramsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Making requests

- (void)makeRequest:(NSURLRequest *)request completion:(SKLAPIResponseBlock)completion {
	[self makeRequest:request
			   expect:ExpectAnyString
		   completion:completion];
}

- (void)makeRequest:(NSURLRequest *)request expect:(ExpectHTTPResponse)expectation completion:(SKLAPIResponseBlock)completion {
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                     if (error) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NSURLSessionErrorCode userInfo:@{ SKLOriginalNetworkingErrorKey : error }];
                                                         completion(error, nil);
                                                     }
                                                     if (httpResponse.statusCode == 400) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:BadRequestCode userInfo:nil];
                                                     }
													 
													 id responseObject;
													 NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
													 responseObject = responseString;
													 
                                                     if (expectation == ExpectJSONResponse) {
														 if (![self isJSONResponse:httpResponse]) {
															 NSDictionary *userInfo = responseString ? @{ SKLOriginalNetworkingResponseStringKey : responseString} : nil;
															 error = [NSError errorWithDomain:SKLAPIErrorDomain code:NonJSONErrorCode userInfo:userInfo];
														 } else {
															 responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
														 }
                                                     }
                                                     
                                                     if (error) {
                                                         completion(error, nil);
                                                         return;
                                                     }
                                                     
													 
                                                     completion(nil, responseObject);
                                                 }];
    [task resume];
}

- (BOOL)isJSONResponse:(NSHTTPURLResponse *)response {
	NSString *contentType = response.allHeaderFields[@"Content-Type"];
	if (!contentType) {
		contentType = response.allHeaderFields[@"content-type"];
	}
	return [contentType rangeOfString:@"application/json"].location != NSNotFound;
}

#pragma mark Handling response

- (void)handleResponse:(NSHTTPURLResponse *)response
				  data:(NSData *)data
				 error:(NSError *)error
			   request:(NSURLRequest *)request
			completion:(SKLAPIResponseBlock)completion {
	
}

@end
