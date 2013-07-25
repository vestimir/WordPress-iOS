#import "PushManager.h"
#import "WPMobileStats.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "WPXMLRPCClient.h"
#import "UIDevice+WordPressIdentifier.h"
#import "WPMobileStats.h"

@implementation PushManager

+ (instancetype)sharedInstance {
    static PushManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PushManager alloc] init];
    });
    return instance;
}

+ (void)registerForRemotePushNotifications {
    // Push notifications only supported for WP.com blogs
//    if (isWPcomAuthenticated) {
//        [[UIApplication sharedApplication]
//         registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
//                                             UIRemoteNotificationTypeSound |
//                                             UIRemoteNotificationTypeAlert)];
//    }
}

+ (void)unregisterForRemotePushNotifications {
    [[PushManager sharedInstance] unregisterApnsToken];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}

- (void)didRegisterForRemoteNotifications:(NSData *)deviceToken {
    // Send the deviceToken to our server...
	NSString *myToken = [[[[deviceToken description]
                           stringByReplacingOccurrencesOfString: @"<" withString: @""]
                          stringByReplacingOccurrencesOfString: @">" withString: @""]
                         stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"Registered for push notifications and stored device token: %@", myToken);
    
	// Store the token
    NSString *previousToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (![previousToken isEqualToString:myToken]) {
        [[NSUserDefaults standardUserDefaults] setObject:myToken forKey:kApnsDeviceTokenPrefKey];
        [[PushManager sharedInstance] sendApnsToken];
    }
}

- (void)didFailToRegisterForRemoteNotifications:(NSError *)error {
    NSLog(@"Failed to register for push notifications: %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
}

- (void)sendApnsToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    NSString *authURL = kNotificationAuthURL;
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
#ifdef DEBUG
        NSNumber *sandbox = [NSNumber numberWithBool:YES];
#else
        NSNumber *sandbox = [NSNumber numberWithBool:NO];
#endif
        WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        
        [api setAuthorizationHeaderWithToken:[[WordPressComApi sharedApi] authToken]];
        
        [api callMethod:@"wpcom.mobile_push_register_token"
             parameters:[NSArray arrayWithObjects:account.username, account.password, token, [[UIDevice currentDevice] wordpressIdentifier], @"apple", sandbox, nil]
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    WPFLog(@"Registered token %@, sending blogs list", token);
                    [[WordPressComApi sharedApi] syncPushNotificationInfo];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey]; //Remove the token from Preferences, otherwise the token is never re-sent to the server on the next startup
                    WPFLog(@"Couldn't register token: %@", [error localizedDescription]);
                }];
	}
}

- (void)unregisterApnsToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    NSString *authURL = kNotificationAuthURL;
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
#ifdef DEBUG
        NSNumber *sandbox = [NSNumber numberWithBool:YES];
#else
        NSNumber *sandbox = [NSNumber numberWithBool:NO];
#endif
        WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        [api setAuthorizationHeaderWithToken:[[WordPressComApi sharedApi] authToken]];
        [api callMethod:@"wpcom.mobile_push_unregister_token"
             parameters:[NSArray arrayWithObjects:account.username, account.password, token, [[UIDevice currentDevice] wordpressIdentifier], @"apple", sandbox, nil]
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    WPFLog(@"Unregistered token %@", token);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    WPFLog(@"Couldn't unregister token: %@", [error localizedDescription]);
                }];
    }
}

- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif {
    if ([remoteNotif objectForKey:@"type"]) { //new social PNs
        WPFLog(@"Received new notification: %@", remoteNotif);
        
        // Make the panel a singleton
//        if( self.panelNavigationController )
//            [self.panelNavigationController showNotificationsView:YES];
        
    } else if ([remoteNotif objectForKey:@"blog_id"] && [remoteNotif objectForKey:@"comment_id"]) {
        WPFLog(@"Received notification: %@", remoteNotif);
//        SidebarViewController *sidebar = (SidebarViewController *)self.panelNavigationController.masterViewController;
//        [sidebar showCommentWithId:[[remoteNotif objectForKey:@"comment_id"] numericValue] blogId:[[remoteNotif objectForKey:@"blog_id"] numericValue]];
    } else {
        WPFLog(@"Got unsupported notification: %@", remoteNotif);
    }
}

- (void)handleRemoteNotificationFromLaunch:(NSDictionary *)notification {
    // User opened the notification and the app launched
    [self handleRemoteNotification:notification applicationState:UIApplicationStateBackground];
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo applicationState:(UIApplicationState)state {
    /* Payload
     {
     aps =     {
     alert = "New comment on test from maria";
     badge = 1;
     sound = default;
     };
     "blog_id" = 16841252;
     "comment_id" = 571;
     }*/

    switch (state) {
            // Application is already in the foreground when we received the notification
        case UIApplicationStateActive:
            [[WordPressComApi sharedApi] checkForNewUnseenNotifications];
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
//            [SoundUtil playNotificationSound];
            break;
            
            // Application was inactive the user opened the notification
        case UIApplicationStateInactive:
            [WPMobileStats recordAppLaunched];
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpenedDueToPushNotification];
            
            [self openNotificationScreenWithOptions:userInfo];
            break;
            
            // User opened the notification while the app was in the background
        case UIApplicationStateBackground:
            [WPMobileStats recordAppLaunched];
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpenedDueToPushNotification];
            
            [self openNotificationScreenWithOptions:userInfo];
            break;
        default:
            break;
    }
}

@end
