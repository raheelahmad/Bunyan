//
//  SKLAPIRequestTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SKLAPIRequest.h"

@interface SKLAPIRequestTests : XCTestCase

@end

@implementation SKLAPIRequestTests

- (void)testAPIRequestURL {
	NSURL *someURL = [NSURL URLWithString:@"http://sakunlabs.com/go/here/please"];
	SKLAPIRequest *apiRequest = [SKLAPIRequest requestWithURL:someURL];
	XCTAssertEqualObjects(apiRequest.URL, someURL, @"Initial URL should be the same as accessed later");
}

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

@end
