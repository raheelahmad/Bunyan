//
//  SKLMockURLSession.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/27/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKLMockURLSession : NSURLSession

@property (nonatomic, readonly) NSURLRequest *lastRequest;
@property (nonatomic, copy) void (^ lastCompletionHandler)(NSData *, NSURLResponse *, NSError *);

@end
