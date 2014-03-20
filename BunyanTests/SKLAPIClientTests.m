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
	SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:nil body:nil];
	[self.apiClient makeRequest:request];
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
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:params body:nil];
    [self.apiClient makeRequest:request];
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

- (void)testPOSTRequestIsMadeWithBody {
	NSDictionary *body = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:nil body:body];
    [self.apiClient makeRequest:request];
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
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:params body:nil];
    [self.apiClient makeRequest:request];
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
	NSDictionary *body = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:nil body:body];
    request.bodyEncoding = SKLJSONBodyEncoding;
    [self.apiClient makeRequest:request];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
    
    NSError *error;
    NSDictionary *sentParams = [NSJSONSerialization JSONObjectWithData:madeRequest.HTTPBody options:0 error:&error];
    XCTAssertNil(error, @"JSON encoding is used for params");
    XCTAssertEqualObjects(sentParams, body, @"JSON encoding is used for params");
}

/**
 * This one is for APIs that expect encoding of params in one kind,
 * but expect the Content-Type header to be of another.
 * E.g., Github's API requires params be encoded as JSON, but Content-Type: application/x-www-form-urlencoded
 */
- (void)testCanSetAnyContentType {
	NSDictionary *body = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:nil body:body];
    request.bodyEncoding = SKLJSONBodyEncoding;
	request.contentType = @"application/x-www-form-urlencoded";
    [self.apiClient makeRequest:request];
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
    
    NSError *error;
    NSDictionary *sendBody = [NSJSONSerialization JSONObjectWithData:madeRequest.HTTPBody options:0 error:&error];
    XCTAssertNil(error, @"JSON encoding is used for params");
    XCTAssertEqualObjects(sendBody, body, @"JSON encoding is used for params");
    XCTAssertEqualObjects(madeRequest.allHTTPHeaderFields[@"Content-Type"], @"application/x-www-form-urlencoded", @"Content-Type should be set to the one provided");
}


- (void)testPostRequest {
	NSDictionary *body = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"POST" params:nil body:body];
    [self.apiClient makeRequest:request];
    
    NSURLRequest *madeRequest = self.mockSession.lastRequest;
	NSString *paramSent = [[NSString alloc] initWithData:madeRequest.HTTPBody encoding:NSUTF8StringEncoding];
	paramSent = [paramSent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(paramSent, @"token=my_t0k3n&id=102&traits[]=12&traits[]=2&traits[]=23", @"Should POST params correctly");
}

- (void)testAPIRequestHeadersAreAttached {
	SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET"
										  params:nil
											body:nil];
	request.headers = @{ @"Accept" : @"crazy/encoding", @"Deny" : @"nothing/ever" };
	[self.apiClient makeRequest:request];
	
	NSURLRequest *madeRequest = self.mockSession.lastRequest;
	XCTAssertEqualObjects(madeRequest.allHTTPHeaderFields[@"Accept"], @"crazy/encoding", @"Should accept API request");
	XCTAssertEqualObjects(madeRequest.allHTTPHeaderFields[@"Deny"], @"nothing/ever", @"Should accept API request");
}


- (void)testRequestsAreSentSerially {
	SKLAPIRequest *request1 = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:nil body:nil];
	SKLAPIRequest *request2 = [SKLAPIRequest with:@"/go/there/please" method:@"GET" params:nil body:nil];
	
	[self.apiClient makeRequest:request1];
	XCTAssertEqual([self.apiClient.pendingRequests count], (NSUInteger)1, @"Pending requests count should be correct");
	
	XCTAssertEqualObjects(self.apiClient.currentRequest, request1, @"Current request should be correct");
	
	[self.apiClient makeRequest:request2];
	
	// Should still report 1 as current request because it has not been completed
	XCTAssertEqualObjects(self.apiClient.currentRequest, request1, @"Current request should be correct");
	XCTAssertEqual([self.apiClient.pendingRequests count], (NSUInteger)2, @"Pending requests count should be correct");
}


- (void)testResponseHandling {
    SKLAPIRequest *request = [SKLAPIRequest with:@"/go/here/please" method:@"GET" params:nil body:nil];
    request.responseParsing = SKLJSONResponseParsing;
	__block id received;
    __block NSError *receivedError;
	request.completionBlock = ^(NSError *error, id responseObject) {
						 received = responseObject;
                         receivedError = error;
					 };
	[self.apiClient makeRequest:request];
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
    
    NSDictionary *responseDict = @{ @"name" : @"Thales" };
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDict options:0 error:NULL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://www.sakunlabs.com/go/here/please"]
                                                              statusCode:200
                                                             HTTPVersion:@"1.1"
                                                            headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertEqualObjects([received objectForKey:@"name"], @"Thales", @"Response dictionary is passed correctly");
	
	received = nil;
	receivedError = nil;
    
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

- (void)testResponseIsTreatedAsData {
	SKLAPIRequest *request = [SKLAPIRequest with:@"/some/where" method:@"GET" params:nil body:nil];
	request.responseParsing = SKLNoResponseParsing;
	
	__block id received = nil;
	__block id receivedError = nil;
	request.completionBlock = ^(NSError *error, id receivedData) {
		received = receivedData;
		receivedError = error;
	};
 	[self.apiClient makeRequest:request];
	
	NSData *someData = [@"These are dreams, Phaedrus." dataUsingEncoding:NSUTF8StringEncoding];
	NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/some/where"]
																 statusCode:200
																HTTPVersion:@"1.1"
															   headerFields:nil];
	self.mockSession.lastCompletionHandler(someData, urlResponse, nil);
	
	XCTAssertTrue([received isKindOfClass:[NSData class]], @"Can receive the raw data in response");
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
