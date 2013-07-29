//
//  SignInOperation.h
//  WordPress
//
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BaseOperation.h"

@interface WPComSignInOperation : BaseOperation

- (id)initWithOwner:(id<NetworkRequestDelegate>)owner username:(NSString*)username password:(NSString*)password;

@end
