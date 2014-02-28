//
//  SKLAPIClient.m
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIClient.h"

@interface SKLAPIClient ()

@property (nonatomic) NSString *baseAPIURL;

@end


@implementation SKLAPIClient

#pragma mark Initialization

+ (instancetype)apiClientWithBaseURL:(NSString *)baseURL {
	return [[self alloc] initWithBaseURL:baseURL];
}

- (id)initWithBaseURL:(NSString *)baseURL {
	self = [super init];
	if (self) {
		self.baseAPIURL = baseURL;
	}
	return self;
}

#pragma mark Composing requests

- (NSURLRequest *)requestWithMethod:(NSString *)method endPoint:(NSString *)endPoint {
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.baseAPIURL, endPoint];
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	return request;
}

@end
