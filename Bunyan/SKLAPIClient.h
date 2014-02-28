//
//  SKLAPIClient.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKLAPIClient : NSObject

+ (instancetype)apiClientWithBaseURL:(NSString *)baseURL;

- (NSURLRequest *)requestWithMethod:(NSString *)method endPoint:(NSString *)endPoint;

@end
