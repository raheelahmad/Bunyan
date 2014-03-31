//
//  SKLAPIClient.h
//  Bunyan
//
//  Created by Raheel Ahmad on 2/26/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

@class UIImage, SKLAPIResponse;

typedef void (^ SKLAPIResponseBlock)(NSError *error, SKLAPIResponse *apiResponse);
typedef void (^ SKLImageFetchResponseBlock)(NSError *error, UIImage *image);

typedef NS_ENUM(NSInteger, ResponseErrorCode) {
    BadRequestCode,
    ServerErrorCode,
    NotHereCode,
    NonJSONErrorCode,
    ImageParsingErrorCode,
	NotFoundCode,
    NSURLSessionErrorCode,
};

extern NSString *const SKLOriginalNetworkingErrorKey;
extern NSString *const SKLOriginalNetworkingResponseStringKey;

@class SKLAPIRequest;

@interface SKLAPIClient : NSObject


- (id)initWithBaseURL:(NSString *)baseURL;

+ (void)setDefaultClientBaseURL:(NSString *)baseURL;
+ (instancetype)defaultClient;

- (NSString *)paramsAsQueryString:(NSDictionary *)params;

- (void)makeRequest:(SKLAPIRequest *)request;

- (void)fetchImageAtURL:(NSString *)url completion:(SKLImageFetchResponseBlock)completion;

@end
