//
//  SKLImageFetcher.m
//  Bunyan
//
//  Created by Raheel Ahmad on 5/9/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLImageFetcher.h"
#import "SKLAPIRequest.h"
#import "SKLAPIResponse.h"
#import "SKLAPIClient.h"

@implementation SKLImageFetcher

NSString *const SKLImageFetcherErrorDomain = @"SKLImageFetcherErrorDomain";

+ (void)fetchImageAtURL:(NSString *)url completion:(void (^)(NSError *, UIImage *))completion {
	if (!url) {
		if (completion) {
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
			completion(error, nil);
			return;
		}
	}
	
	// first attempt to find it in in-memory cache
	UIImage *inMemoryImage = [self memoryImageCache][url];
	if (inMemoryImage) {
		if (completion) {
			completion(nil, inMemoryImage);
		}
		return;
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
				return;
			} else {
				// if we do not have the image on disk, fetch it from the orignal remote URL
				SKLAPIRequest *imageRequest = [SKLAPIRequest with:url method:@"GET" params:nil body:nil];
				imageRequest.responseParsing = SKLNoResponseParsing;
				imageRequest.completionBlock = ^(NSError *error, SKLAPIResponse *response) {
					NSData *imageData = response.responseObject;
					UIImage *image = [UIImage imageWithData:imageData];
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
					if (completion) {
						completion(error, image);
					}
				};
				[[SKLAPIClient defaultClient] makeRequest:imageRequest];
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
	NSURL *cachesDirURL = [self cacheDirURL];
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
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[self diskLCacheLocations] writeToURL:[self diskCacheFileURL] atomically:YES];
		});
	}];
}

+ (NSURL *)diskCacheFileURL {
	return [[self cacheDirURL] URLByAppendingPathComponent:@"image_cache.plist"];
}

+ (NSURL *)cacheDirURL {
	NSURL *cacheURL = [[[self fileManager] URLsForDirectory:(NSCachesDirectory) inDomains:(NSUserDomainMask)] firstObject];
	NSURL *cacheDirURL = [cacheURL URLByAppendingPathComponent:@"avatar_cache" isDirectory:YES];
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSError *error;
		BOOL created = [[self fileManager] createDirectoryAtURL:cacheDirURL withIntermediateDirectories:YES attributes:nil error:&error];
		if (!created) {
			NSLog(@"Error creating image cache directory: %@", error);
		}
	});
	return cacheDirURL;
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
