//
//  NSURL+Util.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/18/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

@interface NSURL (Util)

- (BOOL)isWordPressComURL;
- (NSURL *)ensureSecureURL;

@end