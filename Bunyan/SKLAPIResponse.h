//
//  SKLAPIResponse.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/25/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

@class SKLAPIRequest;

@interface SKLAPIResponse : NSObject

@property (nonatomic) id responseObject;
@property (nonatomic) NSHTTPURLResponse *httpResponse;
/// This is set after the request finishes and before the completion for this response is called
@property (nonatomic) SKLAPIRequest *request;

@property (nonatomic, readonly) NSArray *allResponseObjects;

@end
