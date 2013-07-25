//
//  BaseOperation.h
//  WordPress
//
//  Created by DX074-XL on 13-07-22.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@protocol  NetworkRequestDelegate

@required
- (void)networkRequestComplete:(NSOperation*)operation;
- (void)networkRequestFailed:(NSError *)error;

@end

@interface BaseOperation : AFHTTPRequestOperation

- (id)initWithOwner:(id<NetworkRequestDelegate>)owner request:(NSURLRequest*)request;

@end
