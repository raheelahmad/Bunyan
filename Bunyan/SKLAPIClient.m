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

+ (instancetype)apiClientWithBaseURL:(NSString *)baseURL {
	return [[self alloc] initWithBaseURL:baseURL];
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
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.baseAPIURL, endPoint];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	return request;
}

#pragma mark Making requests

- (void)makeRequest:(NSURLRequest *)request completion:(SKLAPIResponseBlock)completion {
	[self.session dataTaskWithRequest:request
					completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                        if (error) {
                            error = [NSError errorWithDomain:SKLAPIErrorDomain code:NSURLSessionErrorCode userInfo:@{ SKLOriginalNetworkingErrorKey : error }];
                            completion(error, nil);
                        }
                        if (httpResponse.statusCode == 400) {
                            error = [NSError errorWithDomain:SKLAPIErrorDomain code:BadRequestCode userInfo:nil];
                        }
						if (![self isJSONResponse:httpResponse]) {
                            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            NSDictionary *userInfo = responseString ? @{ SKLOriginalNetworkingResponseStringKey : responseString} : nil;
							error = [NSError errorWithDomain:SKLAPIErrorDomain code:NonJSONErrorCode userInfo:userInfo];
						}
                        
                        if (error) {
                            completion(error, nil);
                            return;
                        }
                        
                        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        completion(nil, responseObject);
					}];
}

- (BOOL)isJSONResponse:(NSHTTPURLResponse *)response {
	NSString *contentType = response.allHeaderFields[@"Content-Type"];
	if (!contentType) {
		contentType = response.allHeaderFields[@"content-type"];
	}
	return [contentType isEqualToString:@"application/json"];
}

#pragma mark Handling response

- (void)handleResponse:(NSHTTPURLResponse *)response
				  data:(NSData *)data
				 error:(NSError *)error
			   request:(NSURLRequest *)request
			completion:(SKLAPIResponseBlock)completion {
	
}

@end
