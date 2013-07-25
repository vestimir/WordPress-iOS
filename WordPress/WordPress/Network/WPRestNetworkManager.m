#import "WPRestNetworkManager.h"
#import <WordPressRestApi.h>

@interface WPRestNetworkManager ()


@end

@implementation WPRestNetworkManager

+ (AFHTTPClient *)sharedRestClient {
    static dispatch_once_t onceToken;
    static AFHTTPClient *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:WordPressRestApiEndpointURL]];
    });
    return instance;
}

- (id)initWithBaseURL:(NSURL*)baseURL {
    self = [super init];
    if (self) {
        
    }
    return self;
}




@end
