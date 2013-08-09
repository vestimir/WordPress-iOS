//
//  NSURL+Util.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/18/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NSURL+Util.h"

@implementation NSURL (Util)

- (BOOL)isWordPressComURL
{
    NSString *url = [self absoluteString];
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:0 range:NSMakeRange(0, [[url trim] length])];
    
    return [result count] != 0;
}

- (NSURL *)ensureSecureURL
{
    NSString *url = [self absoluteString];
    return [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
}

@end