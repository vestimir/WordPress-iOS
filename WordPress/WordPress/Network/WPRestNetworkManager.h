#import <AFNetworking/AFHTTPClient.h>

@interface WPRestNetworkManager : NSObject

+ (AFHTTPClient*)sharedRestClient;


@end
