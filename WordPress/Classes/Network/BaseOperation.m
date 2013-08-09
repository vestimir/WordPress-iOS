//
//  BaseOperation.m
//  WordPress
//
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BaseOperation.h"

@implementation BaseOperation

- (id)initWithOwner:(id<NetworkRequestDelegate>)owner request:(NSURLRequest*)request {
    self = [super initWithRequest:request];
    if (self) {
        // Both to main thread for now
        __weak BaseOperation *weakSelf = self;
        [self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [weakSelf requestComplete:responseObject];
            [owner networkRequestComplete:operation];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [weakSelf requestFailed:error];
            [owner networkRequestFailed:error];
        }];
    }
    return self;
}

//- (id)initPostWithOwner:(id<NetworkRequestDelegate>)owner url:(NSURL *)url params:(NSDictionary *)params {
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
//    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:0];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    
//    self = [super initWithRequest:request];
//    if (self) {
//        BaseJSONOperation __weak *weakSelf = self;
//        [self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//            [weakSelf JSONRequestComplete];
//            [owner networkRequestComplete:weakSelf];
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [weakSelf JSONRequestFailed:error];
//            [owner networkRequestFailed:error];
//        }];
//    }
//    return self;
//}
//
//- (id)initGetWithOwner:(id<NetworkRequestDelegate>)owner url:(NSURL *)url params:(NSDictionary *)params {
//    NSURL *requestURL = url;
//    if (params) {
//        NSMutableArray *p = [NSMutableArray array];
//        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//            [p addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
//        }];
//        requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, [p componentsJoinedByString:@"&"]]];
//    }
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
//    self = [super initWithRequest:request];
//    if (self) {
//        BaseJSONOperation __weak *weakSelf = self;
//        // All on main thread for now
//        [self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//            [weakSelf JSONRequestComplete];
//            [owner networkRequestComplete:weakSelf];
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [weakSelf JSONRequestFailed:error];
//            [owner networkRequestFailed:error];
//        }];
//    }
//    return self;
//}
//
//- (id)initGetWithOwner:(id<NetworkRequestDelegate>)owner url:(NSURL *)url {
//    return [self initGetWithOwner:owner url:url params:nil];
//}

#pragma mark - Callbacks

- (void)requestComplete:(id)responseData {
    // Subclass
}

- (void)requestFailed:(NSError*)error {
    // Handle general errors
}



@end
