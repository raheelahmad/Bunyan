//
//  SKLAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"
#import "SKLAPIRequest.h"
#import <UIKit/UIImage.h>

@interface SKLAPIClient ()

@property (nonatomic) NSString *baseAPIURL;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableArray *pendingRequests;
@property (nonatomic) SKLAPIRequest *currentRequest;

@property (nonatomic) NSMutableDictionary *imageDictionary;

@end

static NSString *const SKLAPIErrorDomain = @"SKLAPIErrorDomain";
NSString *const SKLOriginalNetworkingErrorKey = @"SKLOriginalNetworkingErrorKey";
NSString *const SKLOriginalNetworkingResponseStringKey = @"SKLOriginalNetworkingResponseStringKey";

@implementation SKLAPIClient

#pragma mark Initialization

+ (void)setDefaultClientBaseURL:(NSString *)baseURL {
	[[self defaultClient] setBaseAPIURL:baseURL];
}

+ (instancetype)defaultClient {
	static SKLAPIClient *_defaultClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_defaultClient = [[self alloc] initWithBaseURL:nil];
	});
	return _defaultClient;
}

- (id)init {
	return [self initWithBaseURL:nil];
}

- (id)initWithBaseURL:(NSString *)baseURL {
	self = [super init];
	if (self) {
		self.baseAPIURL = baseURL;
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		self.session = [NSURLSession sessionWithConfiguration:configuration];
		self.pendingRequests = [NSMutableArray array];
		self.imageDictionary = [NSMutableDictionary dictionary];
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

#pragma mark Other requests

- (void)fetchImageAtURL:(NSString *)url completion:(SKLImageFetchResponseBlock)completion {
	if (!url) {
		completion(nil, nil);
		return;
	}
	
	UIImage *image = self.imageDictionary[url];
	if (image) {
		completion(nil, image);
		return;
	}
	
	SKLAPIRequest *request = [SKLAPIRequest with:url
										  method:@"GET"
										  params:nil
											body:nil ];
	request.responseParsing = SKLNoResponseParsing;
	request.completionBlock = ^(NSError *error, id responseObject) {
		UIImage *image;
		if (!error) {
			image = [UIImage imageWithData:responseObject];
			if (!image) {
				error = [NSError errorWithDomain:SKLAPIErrorDomain
											code:ImageParsingErrorCode
										userInfo:nil];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				self.imageDictionary[url] = image;
			});
		}
		if (completion) {
			completion(error, image);
		}
	};
	[[SKLAPIClient defaultClient] makeRequest:request];
	
}

#pragma mark Making requests

- (void)makeRequest:(SKLAPIRequest *)request {
	[self.pendingRequests addObject:request];
	
	if ([self.pendingRequests count] == 1) {
		// only 1 request left, let's make it now
		[self makeNextRequest];
	}
}

- (void)makeNextRequest {
	if ([self.pendingRequests count] == 0) {
		return;
	}
	
	SKLAPIRequest *firstRequest = self.pendingRequests[0];
	[self _makeRequest:firstRequest];
}

- (void)cleanupCurrentRequest {
	if (self.currentRequest) {
		[self.pendingRequests removeObject:self.currentRequest];
		self.currentRequest = nil;
	}
	[self makeNextRequest];
}

- (void)_makeRequest:(SKLAPIRequest *)request {
	NSString *endPoint = request.endPoint;
	NSString *method = request.method;
	NSDictionary *params = request.params;
	
	NSString *urlString = [self URLWithEndpoint:endPoint];
    BOOL isPOSTRequest = [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"];
    BOOL isGETRequest = [method isEqualToString:@"GET"];
    NSParameterAssert(isGETRequest || isPOSTRequest);
	
	if ([params count]) {
		urlString = [urlString stringByAppendingFormat:@"?%@", [self paramsAsQueryString:params]];
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
	
	NSDictionary *body = request.body;
	if (isPOSTRequest && [body count]) {
		if (request.bodyEncoding == SKLJSONBodyEncoding) {
            [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			NSError *error;
			urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:body
																  options:0 error:&error];
			if (!urlRequest.HTTPBody) {
				NSLog(@"Error constructing HTTP body: %@", error);
				urlRequest = nil;
			}
		} else if (request.bodyEncoding == SKLFormURLBodyEncoding) {
			[urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			urlRequest.HTTPBody = [[self paramsAsQueryString:body] dataUsingEncoding:NSUTF8StringEncoding];
		} else {
			NSAssert(@"Unrecognized body encoding set", nil);
		}
	}
	
	if (request.contentType) {
		[urlRequest setValue:request.contentType forHTTPHeaderField:@"Content-Type"];
	}
	
	urlRequest.HTTPMethod = method;
	
	self.currentRequest = request;
	
	if (!urlRequest) {
		NSLog(@"Could not send request: %@", request);
		[self cleanupCurrentRequest];
		return;
	}
	
	NSLog(@">>> %@ %@", urlRequest.HTTPMethod, urlRequest.URL);
	if (urlRequest.HTTPBody) {
		NSLog(@"\t\t\t>>>body size %ld bytes", [urlRequest.HTTPBody length]);
	}
	
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:urlRequest
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
													 
                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
													 SKLAPIResponseBlock completion = request.completionBlock;
													 NSLog(@"<<< %ld %@", httpResponse.statusCode, httpResponse.URL);
                                                     if (error) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NSURLSessionErrorCode userInfo:@{ SKLOriginalNetworkingErrorKey : error }];
														 NSLog(@"\t\t\t<<< %@", error);
                                                     }
                                                     if (httpResponse.statusCode == 400) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:BadRequestCode userInfo:nil];
                                                     }
                                                     if (httpResponse.statusCode == 404) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NotFoundCode userInfo:nil];
                                                     }
													 
													 id responseObject;
													 NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
													 responseObject = responseString;
													 
                                                     if (request.responseParsing == SKLJSONResponseParsing) {
														 id parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                         if (!parsedObject) {
                                                             error = [NSError errorWithDomain:SKLAPIErrorDomain
                                                                                         code:NonJSONErrorCode
                                                                                     userInfo:@{
                                                                                                SKLOriginalNetworkingErrorKey : error,
                                                                                                SKLOriginalNetworkingResponseStringKey : responseString
                                                                                                }];
                                                         } else {
                                                             responseObject = parsedObject;
                                                         }
                                                     } else if (request.responseParsing == SKLNoResponseParsing) {
														 responseObject = data;
													 }
                                                     
                                                     if (error) {
														 NSLog(@"\t\t\t%@", error);
														 responseObject = nil;
                                                     } else {
														 
														 NSString *wrappingKey = request.responseWrappingKey;
														 if (responseObject && wrappingKey) {
															 responseObject = [NSDictionary dictionaryWithObject:responseObject
																										  forKey:wrappingKey];
														 }
													 }
													 
													 
													 dispatch_async(dispatch_get_main_queue(), ^{
														 completion(error, responseObject);
														 [self cleanupCurrentRequest];
													 });
                                                 }];
    [task resume];
}

@end
