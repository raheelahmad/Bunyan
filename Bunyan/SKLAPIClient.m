//
//  SKLAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"
#import "SKLAPIRequest.h"
#import "SKLAPIResponse.h"
#import <UIKit/UIImage.h>
#import <UIKit/UIApplication.h>

#define LOG_NETWORKING

@interface SKLAPIClient ()

@property (nonatomic) NSString *baseAPIURL;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableArray *pendingRequests;
@property (nonatomic) SKLAPIRequest *currentRequest;

@property (nonatomic) NSInteger requestsMade;
@property (nonatomic) NSInteger requestsCompleted;
@property (nonatomic) NSInteger requestsCached;

@end

NSString *const SKLAPIErrorDomain = @"SKLAPIErrorDomain";
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
        [self setup];
	}
	return self;
}

- (void)setup {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:15 * 1024 * 1024
                                                           diskCapacity:100 * 1024 * 1024
                                                               diskPath:nil];
    self.session = [NSURLSession sessionWithConfiguration:configuration];
    self.pendingRequests = [NSMutableArray array];
    
    self.requestsMade = 0;
    self.requestsCompleted = 0;
    self.requestsCached = 0;
}

- (void)reset {
    [self deleteAllCookies];
    self.session = nil;
    [self setup];
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
	
	SKLAPIRequest *request = [SKLAPIRequest with:url
										  method:@"GET"
										  params:nil
											body:nil ];
	request.responseParsing = SKLNoResponseParsing;
	request.completionBlock = ^(NSError *error, SKLAPIResponse *apiResponse) {
		NSData *imageData = apiResponse.responseObject;
		UIImage *image;
		if (!error) {
			image = [UIImage imageWithData:imageData];
			if (!image) {
				error = [NSError errorWithDomain:SKLAPIErrorDomain
											code:ImageParsingErrorCode
										userInfo:nil];
			}
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
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if ([self.pendingRequests count] == 1) {
		// only 1 request left, let's make it now
		[self makeNextRequest];
	}
}

- (void)makeNextRequest {
	if ([self.pendingRequests count] == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		return;
	}
	
	self.requestsMade++;
	
	SKLAPIRequest *firstRequest = self.pendingRequests[0];
	[self _makeRequest:firstRequest];
}

- (void)cleanupCurrentRequest {
	if (self.currentRequest) {
		[self.pendingRequests removeObject:self.currentRequest];
		self.currentRequest = nil;
	}
	
	self.requestsCompleted++;
	
	[self makeNextRequest];
}

- (void)_makeRequest:(SKLAPIRequest *)request {
	NSString *endPoint = request.endPoint;
	NSString *method = request.method;
	NSDictionary *params = request.params;
	
	NSString *urlString = [self URLWithEndpoint:endPoint];
    BOOL isPOSTRequest = [method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"PATCH"];
    BOOL isGETRequest = [method isEqualToString:@"GET"];
    NSParameterAssert(isGETRequest || isPOSTRequest);
	
	if ([params count]) {
		urlString = [urlString stringByAppendingFormat:@"?%@", [self paramsAsQueryString:params]];
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
	
	// Attach all other headers
	urlRequest.allHTTPHeaderFields = request.headers;
	
	// Attach contentType header (should overwrite one if provided in request.headers above)
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
	
#ifdef LOG_NETWORKING
	NSLog(@">>> %@ %@", urlRequest.HTTPMethod, urlRequest.URL);
	if (urlRequest.HTTPBody) {
		NSLog(@"\t\t\t>>>body size %ld bytes", (long) [urlRequest.HTTPBody length]);
	}
#endif
	
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:urlRequest
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
													 
                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
													 SKLAPIResponseBlock completion = request.completionBlock;
#ifdef LOG_NETWORKING
													 NSLog(@"<<< %ld %@", (long) httpResponse.statusCode, httpResponse.URL);
#endif
													 
													 // Parse response
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
													 
													 // Handle NSURLSession errors
                                                     if (error) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NSURLSessionErrorCode userInfo:@{ SKLOriginalNetworkingErrorKey : error }];
														 NSLog(@"\t\t\t<<< %@", error);
                                                     }
													 
													 // Handle HTTP errors
													 NSDictionary *errorUserInfo;
													 if (responseObject) {
														 errorUserInfo = @{ SKLOriginalNetworkingResponseStringKey : responseObject };
													 }
                                                     if (httpResponse.statusCode == 400) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:BadRequestCode userInfo:errorUserInfo ];
                                                     } else if (httpResponse.statusCode == 404) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NotFoundCode userInfo:errorUserInfo];
                                                     } else if (httpResponse.statusCode == 405) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:MethodNotAllowedCode userInfo:errorUserInfo];
                                                     } else if (httpResponse.statusCode == 410) {
                                                         error = [NSError errorWithDomain:SKLAPIErrorDomain code:NotHereCode userInfo:errorUserInfo];
                                                     }
                                                     
													 // Handle errors and final response processing
                                                     if (error) {
														 NSLog(@"\t\t\t%@", error);
                                                     } else {
														 NSString *wrappingKey = request.responseWrappingKey;
														 NSString *unwrappingKeypath = request.responseUnwrappingKeypath;
														 if (responseObject && wrappingKey) {
															 responseObject = [NSDictionary dictionaryWithObject:responseObject
																										  forKey:wrappingKey];
														 }
														 if (responseObject && unwrappingKeypath) {
															 responseObject = [responseObject valueForKeyPath:unwrappingKeypath];
														 }
													 }
													 
													 // Call the completion
													 SKLAPIResponse *apiResponse = [[SKLAPIResponse alloc] init];
													 apiResponse.responseObject = responseObject;
													 apiResponse.httpResponse = httpResponse;
													 apiResponse.request = request;
                                                     completion(error, apiResponse);
													 
													 // Wrap up this request (will also start next request if any)
													 dispatch_async(dispatch_get_main_queue(), ^{
														 // Track cached requests
														 if (apiResponse.cached) {
															 self.requestsCached++;
#ifdef LOG_NETWORKING
															 NSLog(@"\t\t\t<<< Cached %ld [out of %ld]", (long)self.requestsCached, (long)self.requestsCompleted + 1);
#endif
														 }
														 
														 [self cleanupCurrentRequest];
													 });
                                                 }];
    [task resume];
}

#pragma mark Cookies

- (void)deleteAllCookies {
    NSHTTPCookieStorage *cookieStorage = self.session.configuration.HTTPCookieStorage;
    NSArray *cookies = cookieStorage.cookies;
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
    }
}

@end
