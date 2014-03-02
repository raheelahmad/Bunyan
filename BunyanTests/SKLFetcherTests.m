//
//  SKLFetcherTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLTestableAPIClient.h"
#import "SKLManagedObject.h"
#import "SKLRemoteRequestInfo.h"
#import "SKLMockURLSession.h"

@interface SKLFakePerson : SKLManagedObject

@end

SKLTestableAPIClient *apiClient;

@implementation SKLFakePerson

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	SKLRemoteRequestInfo *info = [[SKLRemoteRequestInfo alloc] init];
	info.path = @"/get/persons";
	return info;
}

+ (SKLAPIClient *)apiClient {
	return apiClient;
}

@end


// ----

@interface SKLFetcherTests : XCTestCase

@end

@implementation SKLFetcherTests

- (void)testFetchMakesCorrectEndpointAPIRequest {
	[SKLFakePerson fetch];
	NSURLRequest *requestMade = apiClient.mockSession.lastRequest;
	NSString *path = [[NSURLComponents componentsWithURL:requestMade.URL resolvingAgainstBaseURL:NO] path];
	XCTAssertEqualObjects(path, @"/get/persons", @"Fetch should be made with model request info path");
}

- (void)setUp {
    [super setUp];
	
	apiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://sakunlabs.com"];
	apiClient.mockSession = [[SKLMockURLSession alloc] init];
}

- (void)tearDown {
	apiClient = nil;
    [super tearDown];
}

@end
