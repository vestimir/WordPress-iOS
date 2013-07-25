//
//  WPXMLRPCNetworkManager.m
//  WordPress
//
//  Created by DX074-XL on 13-07-23.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPXMLRPCNetworkManager.h"

@implementation WPXMLRPCNetworkManager

+ (WPXMLRPCClient *)sharedXMLRPCClient {
    static WPXMLRPCClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:nil];
    });
    return instance;
}

@end
