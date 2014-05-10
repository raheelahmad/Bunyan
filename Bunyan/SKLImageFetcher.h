//
//  SKLImageFetcher.h
//  Bunyan
//
//  Created by Raheel Ahmad on 5/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <UIKit/UIImage.h>

extern NSString *const SKLImageFetcherErrorDomain;

@interface SKLImageFetcher : NSObject

+ (void)fetchImageAtURL:(NSString *)url completion:(void(^)(NSError *error, UIImage *image))completion;

@end
