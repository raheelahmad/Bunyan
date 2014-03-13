//
//  NSString+Additions.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/12/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (NSDictionary *)queryParamStringAsDictionary {
	NSArray *paramComps = [self componentsSeparatedByString:@"&"];
	NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
	for (NSString *paramString in paramComps) {
		NSArray *comps = [paramString componentsSeparatedByString:@"="];
        id key = comps[0];
        id value = comps[1];
        
		// if it is the array, then we want to collect all the elements
        NSInteger lastTwoStartIndex = [key length] - 2;
        if (lastTwoStartIndex > 0) {
            if ([[key substringFromIndex:lastTwoStartIndex] isEqualToString:@"[]"]) {
                NSString *arrayName = [key substringToIndex:lastTwoStartIndex];
                NSMutableArray *arrayValues = requestParams[arrayName];
                if (!arrayValues) {
                    arrayValues = [NSMutableArray array];
                }
                [arrayValues addObject:value];
                key = arrayName;
                value = arrayValues;
            }
        }
        
        requestParams[key] = value;
	}
    return requestParams;
}

@end
