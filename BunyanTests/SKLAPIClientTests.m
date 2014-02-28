//
//  SKLAPIClientTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLAPIClient.h"

@interface SKLAPIClientTests : XCTestCase
@property (nonatomic) SKLAPIClient *apiClient;
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

- (void)setUp
{
    self.apiClient = [SKLAPIClient apiClientWithBaseURL:@"http://www.sakunlabs.com/api"];
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


@end
