//
//  WPXMLRPCNetworkManager.h
//  WordPress
//
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WPXMLRPCClient.h>

@interface WPXMLRPCNetworkManager : NSObject

+ (WPXMLRPCClient*)sharedXMLRPCClient;

@end
