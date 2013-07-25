//
//  ReachabilityUtils.h
//  WordPress
//
//  Created by Eric on 8/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>

@interface ReachabilityUtils : NSObject

//Connection Reachability variables
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) Reachability *wpcomReachability;
@property (nonatomic, strong) Reachability *currentBlogReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;

+ (ReachabilityUtils*)sharedInstance;

+ (BOOL)isInternetReachable;
+ (void)showAlertNoInternetConnection;
+ (void)showAlertNoInternetConnectionWithDelegate:(id)delegate;

+ (void)startReachabilityNotifier;

@end
