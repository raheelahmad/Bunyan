//
//  SKLImageFetcher.m
//  Bunyan
//
//  Created by Raheel Ahmad on 5/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLImageFetcher.h"
#import "SKLAPIClient.h"

@implementation SKLImageFetcher

NSString *const SKLImageFetcherErrorDomain = @"SKLImageFetcherErrorDomain";

+ (void)fetchImageAtURL:(NSString *)url completion:(void (^)(NSError *, UIImage *))completion {
	if (!url) {
		if (completion) {
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
			completion(error, nil);
		}
	}
	
	// first attempt to find it in in-memory cache
	UIImage *inMemoryImage = [self memoryImageCache][url];
	if (inMemoryImage) {
		if (completion) {
			completion(nil, inMemoryImage);
		}
	} else {
		// otherwise, fetch from disk
		[[self diskQueue] addOperationWithBlock:^{
			NSString *localImagePath = [self diskLCacheLocations][url];
			UIImage *image = [UIImage imageWithContentsOfFile:localImagePath];
			if (image) {
				[self memoryImageCache][url] = image;
				if (completion) {
					completion(nil, image);
				}
			} else {
				// if we do not have the image on disk, fetch it from the orignal remote URL
				[[SKLAPIClient defaultClient] fetchImageAtURL:url
												   completion:^(NSError *error, UIImage *image) {
													   if (image && !error) {
														   NSData *imageData;
														   if (isPNGImageURL(url)) {
															   imageData = UIImagePNGRepresentation(image);
														   } else if (isJPGImageURL(url)) {
															   imageData = UIImageJPEGRepresentation(image, 1.0);
														   }
														   if (imageData) {
															   // if the image was successfully fetched and can be stored faithfully as NSData,
															   // store it on disk
															   NSURL *localImageURL = [self localUrlForRemoteImageURL:url];
															   NSError *error;
															   BOOL written = [imageData writeToURL:localImageURL
																							options:0
																							  error:&error];
															   if (!written) {
																   NSLog(@"Error writing to local %@: %@", url, error);
															   } else {
																   // if stored on disk successfully, add it in the disk cache, ...
																   [self addLocalURL:[localImageURL path] forRemoteURL:url];
																   // and the image in the in-memory cache
																   [self memoryImageCache][url] = image;
															   }
														   }
													   }
													   
													   if (completion) {
														   completion(error, image);
													   }
												   }];
			}
		}];
	}
}

BOOL isPNGImageURL(NSString *imageURL) {
	return [[[imageURL pathExtension] lowercaseString] isEqual:@"png"];
}

BOOL isJPGImageURL(NSString *imageURL) {
	NSString *lowerCaseURL = [[imageURL pathExtension] lowercaseString];
	return [lowerCaseURL isEqual:@"jpg"] || [lowerCaseURL isEqual:@"jpeg"];
}
		 
+ (NSURL *)localUrlForRemoteImageURL:(NSString *)url {
	for (NSString *remove in @[ @"/", @":", @"https", @"http" ]) {
		url = [url stringByReplacingOccurrencesOfString:remove withString:@""];
	}
	NSURL *cachesDirURL = [[[self fileManager] URLsForDirectory:(NSCachesDirectory) inDomains:(NSUserDomainMask)] firstObject];
	return [cachesDirURL URLByAppendingPathComponent:url];
}
		 

#pragma mark In Memory Cache

+ (NSMutableDictionary *)memoryImageCache {
	static NSMutableDictionary *_memoryImageCache;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_memoryImageCache = [[NSMutableDictionary alloc] init];
	});
	return _memoryImageCache;
}

+ (NSMutableDictionary *)diskLCacheLocations {
	static NSMutableDictionary *_diskCacheLocations;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_diskCacheLocations = [[NSDictionary dictionaryWithContentsOfURL:[self diskCacheFileURL]] mutableCopy];
		if (!_diskCacheLocations) {
			_diskCacheLocations = [NSMutableDictionary dictionary];
		}
	});
	return _diskCacheLocations;
}

+ (void)addLocalURL:(NSString *)localURL forRemoteURL:(NSString *)remoteURL {
	[[self diskQueue] addOperationWithBlock:^{
		[self diskLCacheLocations][remoteURL] = localURL;
		[[self diskLCacheLocations] writeToURL:[self diskCacheFileURL] atomically:YES];
	}];
}

+ (NSURL *)diskCacheFileURL {
	return [[self cacheDirURL] URLByAppendingPathComponent:@"image_cache.plist"];
}

+ (NSURL *)cacheDirURL {
	return [[[self fileManager] URLsForDirectory:(NSCachesDirectory) inDomains:(NSUserDomainMask)] firstObject];
}

#pragma mark Disk Cache

+ (NSOperationQueue *)diskQueue {
	static NSOperationQueue *_diskQueue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_diskQueue = [[NSOperationQueue alloc] init];
		_diskQueue.name = @"SKLDiskQueue";
		_diskQueue.maxConcurrentOperationCount = 1;
	});
	return _diskQueue;
}

+ (NSFileManager *)fileManager {
	static NSFileManager *_fileManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_fileManager = [[NSFileManager alloc] init];
	});
	return _fileManager;
}

@end
