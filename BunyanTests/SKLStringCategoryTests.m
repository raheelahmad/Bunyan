//
//  SKLStringCategoryTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/12/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+Additions.h"

@interface SKLStringCategoryTests : XCTestCase

@end

@implementation SKLStringCategoryTests

- (void)testQueryParamsAsDictionary {
    NSString *queryParamsString = @"token=my_t0k3n&id=102&traits[]=12&traits[]=2&traits[]=23";
    NSDictionary *dict = [queryParamsString queryParamStringAsDictionary];
    XCTAssertEqualObjects(dict[@"token"], @"my_t0k3n", @"Correct decoding of string to dictionary");
    XCTAssertEqualObjects(dict[@"id"], @"102", @"Correct decoding of string to dictionary");
    NSArray *parsedArray = @[ @"12", @"2", @"23" ];
    XCTAssertEqualObjects(dict[@"traits"], parsedArray, @"Correct decoding of string to dictionary");
}

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

@end
