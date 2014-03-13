//
//  SKLAPIClientTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLTestableAPIClient.h"
#import "SKLAPIRequest.h"
#import "SKLMockURLSession.h"

@interface SKLAPIClientTests : XCTestCase
@property (nonatomic) SKLTestableAPIClient *apiClient;
@property (nonatomic) SKLMockURLSession *mockSession;
@end

@implementation SKLAPIClientTests

- (void)testCorrectRequestIsMade {
	SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:nil];
	[self.apiClient makeRequest:request completion:nil];
	NSURLRequest *madeRequest = self.mockSession.lastRequest;
	XCTAssertEqualObjects(madeRequest.URL, [NSURL URLWithString:@"http://www.sakunlabs.com/api/go/here/please"], @"Correct URL should be used");
	XCTAssertEqualObjects(madeRequest.HTTPMethod, @"GET", @"Correct HTTP method should be used");
}

- (void)testGETRequestIsMadeWithParams {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:params];
    [self.apiClient makeRequest:request completion:nil];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
	NSURLComponents *components = [NSURLComponents componentsWithURL:madeRequest.URL
											 resolvingAgainstBaseURL:NO];
	NSArray *paramComps = [components.query componentsSeparatedByString:@"&"];
	NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
	NSMutableArray *arrayParamValues = [NSMutableArray array];
	for (NSString *paramString in paramComps) {
		NSArray *comps = [paramString componentsSeparatedByString:@"="];
		requestParams[comps[0]] = comps[1];
		// if it is the array, then we want to collect all the elements
		if ([comps[0] isEqualToString:@"traits[]"]) {
			[arrayParamValues addObject:comps[1]];
		}
	}
	
	XCTAssertEqualObjects(requestParams[@"token"], @"my_t0k3n", @"Correct query params must be sent");
	XCTAssertEqualObjects(requestParams[@"id"], @"102", @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"12"], @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"2"], @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"23"], @"Correct query params must be sent");
}

- (void)testPOSTRequestIsMadeWithParams {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params];
    [self.apiClient makeRequest:request completion:nil];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
    
	NSString *httpBodyString = [[NSString alloc] initWithData:madeRequest.HTTPBody encoding:NSUTF8StringEncoding];
	httpBodyString = [httpBodyString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(httpBodyString, @"token=my_t0k3n&id=102&traits[]=12&traits[]=2&traits[]=23", @"URL Form encoding is used for params");
	XCTAssertEqualObjects(madeRequest.allHTTPHeaderFields[@"Content-Type"], @"application/x-www-form-urlencoded", @"application/x-www-form-urlencoded must be the Content-Type");
}

- (void)testPOSTRequestCanBeMadeWithQueryParams {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params];
	request.paramsEncoding = SKLQueryParamsEncoding;
    [self.apiClient makeRequest:request completion:nil];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
	NSURLComponents *components = [NSURLComponents componentsWithURL:madeRequest.URL
											 resolvingAgainstBaseURL:NO];
	NSArray *paramComps = [components.query componentsSeparatedByString:@"&"];
	NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
	NSMutableArray *arrayParamValues = [NSMutableArray array];
	for (NSString *paramString in paramComps) {
		NSArray *comps = [paramString componentsSeparatedByString:@"="];
		requestParams[comps[0]] = comps[1];
		// if it is the array, then we want to collect all the elements
		if ([comps[0] isEqualToString:@"traits[]"]) {
			[arrayParamValues addObject:comps[1]];
		}
	}
	
	XCTAssertEqualObjects(requestParams[@"token"], @"my_t0k3n", @"Correct query params must be sent");
	XCTAssertEqualObjects(requestParams[@"id"], @"102", @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"12"], @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"2"], @"Correct query params must be sent");
	XCTAssertTrue([arrayParamValues containsObject:@"23"], @"Correct query params must be sent");
}
- (void)testJSONEncoding {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params];
    request.paramsEncoding = SKLJSONParamsEncoding;
    [self.apiClient makeRequest:request completion:nil];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
    
    NSError *error;
    NSDictionary *sentParams = [NSJSONSerialization JSONObjectWithData:madeRequest.HTTPBody options:0 error:&error];
    XCTAssertNil(error, @"JSON encoding is used for params");
    XCTAssertEqualObjects(sentParams, params, @"JSON encoding is used for params");
}

/**
 * This one is for APIs that expect encoding of params in one kind,
 * but expect the Content-Type header to be of another.
 * E.g., Github's API requires params be encoded as JSON, but Content-Type: application/x-www-form-urlencoded
 */
- (void)testCanSetAnyContentType {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params];
    request.paramsEncoding = SKLJSONParamsEncoding;
	request.contentType = @"application/x-www-form-urlencoded";
    [self.apiClient makeRequest:request completion:nil];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
    
    NSError *error;
    NSDictionary *sentParams = [NSJSONSerialization JSONObjectWithData:madeRequest.HTTPBody options:0 error:&error];
    XCTAssertNil(error, @"JSON encoding is used for params");
    XCTAssertEqualObjects(sentParams, params, @"JSON encoding is used for params");
    XCTAssertEqualObjects(madeRequest.allHTTPHeaderFields[@"Content-Type"], @"application/x-www-form-urlencoded", @"Content-Type should be set to the one provided");
}


- (void)testPostRequest {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params];
    [self.apiClient makeRequest:request completion:nil];
    
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
	NSString *paramSent = [[NSString alloc] initWithData:madeRequest.HTTPBody encoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(paramSent, @"token=my_t0k3n&id=102&traits%5B%5D=12&traits%5B%5D=2&traits%5B%5D=23", @"Should POST params correctly");
	NSLog(@"Params %@", paramSent);
}

- (void)testResponseHandling {
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:nil];
    request.paramsEncoding = SKLJSONParamsEncoding;
    request.responseParsing = SKLJSONResponseParsing;
	__block id received;
    __block NSError *receivedError;
	[self.apiClient makeRequest:request
					 completion:^(NSError *error, id responseObject) {
						 received = responseObject;
                         receivedError = error;
					 }];
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
    
    NSDictionary *responseDict = @{ @"name" : @"Thales" };
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDict options:0 error:NULL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://www.sakunlabs.com/go/here/please"]
                                                              statusCode:200
                                                             HTTPVersion:@"1.1"
                                                            headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertEqualObjects([received objectForKey:@"name"], @"Thales", @"Response dictionary is passed correctly");
    
    // test on error
    NSError *responseError = [NSError errorWithDomain:@"ErrorDomain" code:100 userInfo:nil];
    self.mockSession.lastCompletionHandler(responseData, response, responseError);
    XCTAssertNil(received, @"Response should be nil on error");
    XCTAssertNotNil(receivedError, @"Response error should be non-nil on error");
    XCTAssertEqualObjects(receivedError.userInfo[SKLOriginalNetworkingErrorKey], responseError, @"Response error should include original error");
    
    // test on 400
    response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://www.sakunlabs.com/go/here/please"]
                                           statusCode:400
                                          HTTPVersion:@"1.1"
                                         headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertNil(received, @"For 400, response object should be nil");
    XCTAssertNotNil(receivedError, @"For 400, response error should be non-nil");
    XCTAssertEqual(receivedError.code, (NSInteger)BadRequestCode, @"For 400, should receive the correct error code");
	
    // test on 404
    response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://www.sakunlabs.com/go/here/please"]
                                           statusCode:404
                                          HTTPVersion:@"1.1"
                                         headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertNil(received, @"For 404, response object should be nil");
    XCTAssertNotNil(receivedError, @"For 404, response error should be non-nil");
    XCTAssertEqual(receivedError.code, (NSInteger)NotFoundCode, @"For 404, should receive the correct error code");
    
    // test on non json
	NSString *someHTMLString = @"<html><body>Live graciously and kindly.</body></html>";
	responseData = [someHTMLString dataUsingEncoding:NSUTF8StringEncoding];
	response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://www.sakunlabs.com/go/here/please"]
										   statusCode:200
										  HTTPVersion:@"1.1"
										 headerFields:@{ @"Content-Type" : @"text/html" }];
	self.mockSession.lastCompletionHandler(responseData, response, nil);
	XCTAssertNil(received, @"For non application/json content-type, do not parse the JSON");
	XCTAssertEqualObjects(receivedError.userInfo[SKLOriginalNetworkingResponseStringKey], someHTMLString, @"Should receive original response string for non-JSON response");
}

- (void)setUp {
    self.apiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://www.sakunlabs.com/api"];
	self.mockSession = [[SKLMockURLSession alloc] init];
	self.apiClient.mockSession = self.mockSession;
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


@end
