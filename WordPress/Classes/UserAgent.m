#import "UserAgent.h"

static NSString *const USER_AGENT_DEFAULT = @"DefaultUserAgent";
static NSString *const USER_AGENT_CURRENT = @"UserAgent";
static NSString *const USER_AGENT_APP = @"AppUserAgent";

@implementation UserAgent

+ (void)setupAppUserAgent {
    // Keep a copy of the original userAgent for use with certain webviews in the app.
    UIWebView *webView = [[UIWebView alloc] init];
    NSString *defaultUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"version_preference"];
    NSString *appUA = [NSString stringWithFormat:@"wp-iphone/%@ (%@ %@, %@) Mobile",
                       appVersion,
                       [[UIDevice currentDevice] systemName],
                       [[UIDevice currentDevice] systemVersion],
                       [[UIDevice currentDevice] model]
                       ];
    
    NSDictionary *dictionary = @{USER_AGENT_CURRENT: appUA,
                                 USER_AGENT_DEFAULT: defaultUA,
                                 USER_AGENT_APP: appUA};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

+ (void)useDefaultUserAgent {
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:USER_AGENT_DEFAULT];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, USER_AGENT_CURRENT, nil];
    
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    WPLog(@"User-Agent set to: %@", ua);
}

+ (void)useAppUserAgent {
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:USER_AGENT_APP];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, USER_AGENT_CURRENT, nil];
    
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    WPLog(@"User-Agent set to: %@", ua);
}

+ (NSString*)appUserAgent {
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_AGENT_APP];
}

+ (NSString*)defaultUserAgent {
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_AGENT_DEFAULT];
}

@end
