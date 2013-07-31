//
//  WordPressComApiCredentials.m
//  WordPress
//
//  Created by Jorge Bernal on 1/2/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WordPressComApiCredentials.h"

#define WPCOM_API_CLIENT_ID @"4304"
#define WPCOM_API_CLIENT_SECRET @"pm2XFIBmMJPmOmDTG0d0NvksiWFIHZtGmsfr2oHuUHZgLGlUxRzTps8nSiJEGjox"

@implementation WordPressComApiCredentials
+ (NSString *)client {
    return WPCOM_API_CLIENT_ID;
}

+ (NSString *)secret {
    return WPCOM_API_CLIENT_SECRET;
}

+ (NSString *)mixpanelAPIToken {
    return @"";
}

+ (NSString *)pocketConsumerKey {
    return @"";
}

+ (NSString *)crashlyticsApiKey {
    return @"";
}

+ (NSString *)googlePlusClientId {
    return @"";
}

@end
