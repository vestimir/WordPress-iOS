//
//  WPXMLRPCNetworkManager.h
//  WordPress
//
//  Created by DX074-XL on 13-07-23.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WPXMLRPCClient.h>

@interface WPXMLRPCNetworkManager : NSObject

+ (WPXMLRPCClient*)sharedXMLRPCClient;

@end
