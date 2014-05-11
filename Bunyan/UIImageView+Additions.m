//
//  UIImageView+Additions.m
//  HubHub
//
//  Created by Raheel Ahmad on 3/16/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "UIImageView+Additions.h"
#import "SKLImageFetcher.h"

@implementation UIImageView (Additions)

- (void)setImageFromURL:(NSString *)url {
	if (!url.length) {
		return;
	}
	
	[SKLImageFetcher fetchImageAtURL:url
						  completion:^(NSError *error, UIImage *image) {
							  dispatch_async(dispatch_get_main_queue(), ^{
								  self.image = image;
							  });
						  }];
}

@end
