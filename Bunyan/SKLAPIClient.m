//
//  SKLAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"
#import "SKLAPIRequest.h"

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

- (void)makeRequest:(SKLAPIRequest *)request completion:(SKLAPIResponseBlock)completion {
	NSString *endPoint = request.endPoint;
	NSString *method = request.method;
	NSDictionary *params = request.params;
	
	NSString *urlString = [self URLWithEndpoint:endPoint];
    BOOL isPOSTRequest = [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"];
    BOOL isGETRequest = [method isEqualToString:@"GET"];
    NSParameterAssert(isGETRequest || isPOSTRequest);
	
	BOOL paramsSet = NO;
	
	if ([params count]) {
		if (isGETRequest || request.paramsEncoding == SKLQueryParamsEncoding) {
			urlString = [urlString stringByAppendingFormat:@"?%@", [self paramsAsQueryString:params]];
			paramsSet = YES;
		}
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
	
	if (isPOSTRequest && [params count] && !paramsSet) {
		if (request.paramsEncoding == SKLJSONParamsEncoding) {
            [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			NSError *error;
			urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:params
															   options:0 error:&error];
			if (!urlRequest.HTTPBody) {
				NSLog(@"Error constructing HTTP body: %@", error);
				request = nil;
			}
		} else {
			[urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			urlRequest.HTTPBody = [[self paramsAsQueryString:params] dataUsingEncoding:NSUTF8StringEncoding];
		}
	}
	
	if (request.contentType) {
		[urlRequest setValue:request.contentType forHTTPHeaderField:@"Content-Type"];
	}
	
	urlRequest.HTTPMethod = method;
	
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:urlRequest
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
													 
                                                     if (request.responseParsing == SKLJSONResponseParsing) {
														 responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                     }
                                                     
                                                     if (error) {
                                                         completion(error, nil);
                                                         return;
                                                     }
                                                     
													 
                                                     completion(nil, responseObject);
                                                 }];
    [task resume];
}

#pragma mark Handling response

- (void)handleResponse:(NSHTTPURLResponse *)response
				  data:(NSData *)data
				 error:(NSError *)error
			   request:(NSURLRequest *)request
			completion:(SKLAPIResponseBlock)completion {
	
}

@end
