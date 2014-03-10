//
//  SKLURLRequest.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLAPIRequest.h"

@interface SKLAPIRequest ()

@property (nonatomic) NSMutableURLRequest *urlRequest;

@end

@implementation SKLAPIRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
	SKLAPIRequest *request = [[self alloc] init];
	request.urlRequest = [NSMutableURLRequest requestWithURL:URL];
	return request;
}

#pragma mark Accessors

- (NSURL *)URL {
	return self.urlRequest.URL;
}

@end
