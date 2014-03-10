//
//  SKLAPIClientTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLTestableAPIClient.h"
#import "SKLMockURLSession.h"

@interface SKLAPIClientTests : XCTestCase
@property (nonatomic) SKLTestableAPIClient *apiClient;
@property (nonatomic) SKLMockURLSession *mockSession;
@end

@implementation SKLAPIClientTests

- (void)testBaseURLUsage {
	NSURLRequest *request = [self.apiClient requestWithMethod:@"GET" endPoint:@"/go/here/please"];
	NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
	
	XCTAssertEqualObjects(components.host, @"www.sakunlabs.com", @"Should use base URL");
	XCTAssertEqualObjects(components.path, @"/api/go/here/please", @"Should use base URL");
}

- (void)testMethodName {
    NSURLRequest *request = [self.apiClient requestWithMethod:@"GET" endPoint:@"some/where"];
    XCTAssertEqualObjects(request.HTTPMethod, @"GET", @"Should have correct HTTP method");
}

- (void)testCorrectRequestIsMade {
	NSURLRequest *request = [self.apiClient requestWithMethod:@"GET" endPoint:@"/go/here/please"];
	[self.apiClient makeRequest:request completion:nil];
	NSURLRequest *madeRequest = self.mockSession.lastRequest;
	XCTAssertEqualObjects(madeRequest.URL, request.URL, @"Correct URL should be used");
	XCTAssertEqualObjects(madeRequest.HTTPMethod, request.HTTPMethod, @"Correct HTTP method should be used");
}

- (void)testRequestIsMadeWithParams {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
	NSURLRequest *request = [self.apiClient requestWithMethod:@"GET" endPoint:@"/go/here/please" params:params];
	NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL
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

- (void)testPostRequest {
	NSDictionary *params = @{
							 @"token" : @"my_t0k3n",
							 @"id" : @102,
							 @"traits" : @[ @12, @2, @23 ]
							 };
	NSURLRequest *request = [self.apiClient requestWithMethod:@"POST" endPoint:@"/go/here/please" params:params];
	NSString *paramSent = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(paramSent, @"token=my_t0k3n&id=102&traits%5B%5D=12&traits%5B%5D=2&traits%5B%5D=23", @"Should POST params correctly");
	NSLog(@"Params %@", paramSent);
}

- (void)testResponseHandling {
	NSURLRequest *request = [self.apiClient requestWithMethod:@"GET" serializer:JSONSerializer endPoint:@"/go/here/please" params:nil];
	__block id received;
    __block NSError *receivedError;
	[self.apiClient makeRequest:request
						 expect:ExpectJSONResponse
					 completion:^(NSError *error, id responseObject) {
						 received = responseObject;
                         receivedError = error;
					 }];
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
    
    NSDictionary *responseDict = @{ @"name" : @"Thales" };
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDict options:0 error:NULL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertEqualObjects([received objectForKey:@"name"], @"Thales", @"Response dictionary is passed correctly");
    
    // test on error
    NSError *responseError = [NSError errorWithDomain:@"ErrorDomain" code:100 userInfo:nil];
    self.mockSession.lastCompletionHandler(responseData, response, responseError);
    XCTAssertNil(received, @"Response should be nil on error");
    XCTAssertNotNil(receivedError, @"Response error should be non-nil on error");
    XCTAssertEqualObjects(receivedError.userInfo[SKLOriginalNetworkingErrorKey], responseError, @"Response error should include original error");
    
    // test on 400
    response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:400 HTTPVersion:@"1.1" headerFields:jsonResponseHeaderDict];
    self.mockSession.lastCompletionHandler(responseData, response, nil);
    XCTAssertNil(received, @"For 400, response object should be nil");
    XCTAssertNotNil(receivedError, @"For 400, response error should be non-nil");
    XCTAssertEqual(receivedError.code, (NSInteger)BadRequestCode, @"For 400, should receive the correct error code");
    
    // test on non json
	NSString *someHTMLString = @"<html><body>Live graciously and kindly.</body></html>";
	responseData = [someHTMLString dataUsingEncoding:NSUTF8StringEncoding];
	response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
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
