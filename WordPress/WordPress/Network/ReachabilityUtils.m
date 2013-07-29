//
//  ReachabilityUtils.m
//  WordPress
//
//  Created by Eric on 8/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"

@interface ReachabilityAlert : NSObject <UIAlertViewDelegate>

@property (nonatomic, copy) void (^retryBlock)();

- (id)initWithRetryBlock:(void (^)())retryBlock;
- (void)show;

@end

static ReachabilityAlert *currentReachabilityAlert = nil;

@implementation ReachabilityAlert

- (id)initWithRetryBlock:(void (^)())retryBlock {
    self = [super init];
    if (self) {
        self.retryBlock = retryBlock;
    }
    return self;
}

- (void)show {
    if (currentReachabilityAlert) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Connection", @"")
                                                    message:NSLocalizedString(@"The Internet connection appears to be offline.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    if(self.retryBlock) {
        [alert addButtonWithTitle:NSLocalizedString(@"Retry?", @"")];
    }
    [alert show];
    currentReachabilityAlert = self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    ReachabilityAlert *alert = currentReachabilityAlert;
    currentReachabilityAlert = nil;
    if (buttonIndex == 1 && self.retryBlock) {
        self.retryBlock();
    }
    alert = nil;
}

@end

#pragma mark - 

@implementation ReachabilityUtils

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ReachabilityUtils *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ReachabilityUtils alloc] init];
        instance.wpcomAvailable = true;
        instance.connectionAvailable = true;
        instance.currentBlogAvailable = true;
    });
    return instance;
}

+ (BOOL)isInternetReachable {
    return [[ReachabilityUtils sharedInstance] connectionAvailable];
}


+ (void)showAlertNoInternetConnection {
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:nil];
    [alert show];
}


+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock {
    ReachabilityAlert *alert = [[ReachabilityAlert alloc] initWithRetryBlock:retryBlock];
    [alert show];
}

+ (void)startReachabilityNotifier {
    ReachabilityUtils __weak *instance = [ReachabilityUtils sharedInstance];
    
    // Set the wpcom availability to YES to avoid issues with lazy reachibility notifier
    instance.wpcomAvailable = YES;
    
    // Same for general internet connection
    instance.connectionAvailable = YES;
    
    // allocate the internet reachability object
    instance.internetReachability = [Reachability reachabilityForInternetConnection];
    
    instance.connectionAvailable = [instance.internetReachability isReachable];
    
    instance.internetReachability.reachableBlock = ^(Reachability*reach)
    {
        WPLog(@"Internet connection is back");
        instance.connectionAvailable = YES;
    };
    instance.internetReachability.unreachableBlock = ^(Reachability*reach)
    {
        WPLog(@"No internet connection");
        instance.connectionAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [instance.internetReachability startNotifier];
    
    // allocate the WP.com reachability object
    instance.wpcomReachability = [Reachability reachabilityWithHostname:@"wordpress.com"];
    
    instance.wpcomReachability.reachableBlock = ^(Reachability*reach)
    {
        WPLog(@"Connection to WordPress.com is back");
        instance.wpcomAvailable = YES;
    };
    instance.wpcomReachability.unreachableBlock = ^(Reachability*reach)
    {
        WPLog(@"No connection to WordPress.com");
        instance.wpcomAvailable = NO;
    };
    
    // start the notifier which will cause the reachability object to retain itself!
    [instance.wpcomReachability startNotifier];
}

@end
