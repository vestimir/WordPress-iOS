/*
 * NotificationsManager.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "NotificationsManager.h"
#import "WPMobileStats.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "WPXMLRPCClient.h"
#import "UIDevice+WordPressIdentifier.h"
#import "WPMobileStats.h"
#import "WordPressAppDelegate.h"
#import "SidebarViewController.h"
#import <objc/runtime.h>

NSString *const WordPressComApiNotificationPreferencesKey = @"notification_preferences";
NSString *const WordPressComApiUnseenNotesNotification = @"WordPressComUnseenNotes";
NSString *const WordPressComApiNotesUserInfoKey = @"notes";
NSString *const WordPressComApiUnseenNoteCountInfoKey = @"note_count";

@interface NotificationsManager (WPXMLRPCAPI_Private)

- (void)registerTokenWithAccount:(WPAccount*)account
                     deviceToken:(NSString*)token
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

- (void)unregisterTokenWithAccount:(WPAccount*)account
                     deviceToken:(NSString*)token
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

@end

@interface NotificationsManager ()

@property (nonatomic, strong) WPXMLRPCClient *authClient;
@property (nonatomic, strong) NSNumber *useAPNSSandbox;

@end

@implementation NotificationsManager

+ (instancetype)sharedInstance {
    static NotificationsManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NotificationsManager alloc] init];
        instance.authClient = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:kNotificationAuthURL]];
#if DEBUG
        instance.useAPNSSandbox = @YES;
#else
        instance.useAPNSSandbox = @NO;
#endif
    });
    return instance;
}

+ (void)registerForRemotePushNotifications {
    // Push notifications only supported for WP.com blogs
    WPAccount *defaultAccount = [WPAccount defaultWordPressComAccount];
    
    if (defaultAccount.isWpComAuthenticated) {
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                             UIRemoteNotificationTypeSound |
                                             UIRemoteNotificationTypeAlert)];
    }
}

+ (void)unregisterForRemotePushNotifications {
    [[NotificationsManager sharedInstance] unregisterApnsToken];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}

+ (void)syncPushNotificationSettings {
    [[NotificationsManager sharedInstance] fetchNotificationSettingsWithSuccess:nil failure:nil];
}

- (void)didRegisterForRemoteNotifications:(NSData *)deviceToken {
    // Send the deviceToken to our server...
	NSString *myToken = [[[[deviceToken description]
                           stringByReplacingOccurrencesOfString: @"<" withString: @""]
                          stringByReplacingOccurrencesOfString: @">" withString: @""]
                         stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    WPLog(@"Registered for push notifications and stored device token: %@", myToken);
    
	// Store the token
    NSString *previousToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (![previousToken isEqualToString:myToken]) {
        [[NSUserDefaults standardUserDefaults] setObject:myToken forKey:kApnsDeviceTokenPrefKey];
        [[NotificationsManager sharedInstance] sendApnsToken];
    }
}

- (void)didFailToRegisterForRemoteNotifications:(NSError *)error {
    WPLog(@"Failed to register for push notifications: %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
}

- (void)sendApnsToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available

    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
        [self registerTokenWithAccount:account deviceToken:token success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self fetchNotificationSettingsWithSuccess:nil failure:nil];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //Remove the token from Preferences, otherwise the token is never re-sent to the server on the next startup
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey]; 
            WPFLog(@"Couldn't register token: %@", [error localizedDescription]);
        }];
	}
}

- (void)unregisterApnsToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
        [self unregisterTokenWithAccount:account deviceToken:token success:^(AFHTTPRequestOperation *operation, id responseObject) {
            WPFLog(@"Unregistered token %@", token);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            WPFLog(@"Couldn't unregister token: %@", [error localizedDescription]);
        }];
    }
}

- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    
    if ([remoteNotif objectForKey:@"type"]) { //new social PNs
        WPFLog(@"Received new notification: %@", remoteNotif);

        if(appDelegate.panelNavigationController) {
            [appDelegate.panelNavigationController showNotificationsView:YES];
        }
        
    } else if ([remoteNotif objectForKey:@"blog_id"] && [remoteNotif objectForKey:@"comment_id"]) {
        WPFLog(@"Received notification: %@", remoteNotif);
        SidebarViewController *sidebar = (SidebarViewController *)appDelegate.panelNavigationController.masterViewController;
        [sidebar showCommentWithId:[[remoteNotif objectForKey:@"comment_id"] numericValue] blogId:[[remoteNotif objectForKey:@"blog_id"] numericValue]];
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
            [[NotificationsManager sharedInstance] checkForUnseenNotifications];
            [NotificationsManager syncPushNotificationSettings];
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

@implementation NotificationsManager (WPXMLRPCAPI_Private)

- (void)registerTokenWithAccount:(WPAccount *)account
                     deviceToken:(NSString *)token
                         success:(void (^)(AFHTTPRequestOperation *, id))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *error))failureBlock {
    [self.authClient setAuthorizationHeaderWithToken:account.authToken];
    
    [self.authClient callMethod:@"wpcom.mobile_push_register_token"
                     parameters:@[account.username, account.password, token, [[UIDevice currentDevice] wordpressIdentifier], @"apple", self.useAPNSSandbox]
                        success:successBlock failure:failureBlock];
}

- (void)unregisterTokenWithAccount:(WPAccount *)account
                       deviceToken:(NSString *)token
                           success:(void (^)(AFHTTPRequestOperation *, id))successBlock
                           failure:(void (^)(AFHTTPRequestOperation *, NSError *error))failureBlock {
    [self.authClient setAuthorizationHeaderWithToken:account.authToken];
    
    [self.authClient callMethod:@"wpcom.mobile_push_unregister_token"
                     parameters:@[account.username, account.password, token, [[UIDevice currentDevice] wordpressIdentifier], @"apple", self.useAPNSSandbox]
                        success:successBlock failure:failureBlock];
}

@end

@implementation NotificationsManager (WordPressComApi)

- (void)saveNotificationSettings:(NSDictionary*)settings success:(void (^)())success failure:(void (^)(NSError *error))failure {
    WPAccount *account = [WPAccount defaultWordPressComAccount];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:WordPressComApiNotificationPreferencesKey];
    if (account && token) {
        [[WordPressComApi sharedApi] saveNotificationSettingsForUsername:account.username password:account.password deviceToken:token notificationSettings:settings success:^{
            if (success) {
                success();
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    } else {
        WPLog(@"No active default account and no token. Not saving notification settings to server.");
    }
}

- (void)fetchNotificationSettingsWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure {
    WPAccount *account = [WPAccount defaultWordPressComAccount];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (account && token) {
        [[WordPressComApi sharedApi] fetchNotificationSettingsWithUsername:account.username password:account.password deviceToken:token success:^(NSDictionary *notificationSettings) {
            // Save the preferences
            [[NSUserDefaults standardUserDefaults] setObject:notificationSettings forKey:WordPressComApiNotificationPreferencesKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (success) {
                success();
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    } else {
        WPLog(@"No active default account and no token. Will not fetch notification settings.");
    }
}

- (void)checkForUnseenNotifications {
    [[WordPressComApi sharedApi] fetchUnseenNotificationsWithSuccess:^(NSArray *unseenNotes) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:WordPressComApiUnseenNotesNotification
                              object:self
                            userInfo:@{
                WordPressComApiNotesUserInfoKey: unseenNotes,
                WordPressComApiUnseenNoteCountInfoKey: [NSNumber numberWithInteger:[unseenNotes count]]
             }];
    } failure:^(NSError *error) {
        WPLog(@"Checking for unseen notifications failed with error %@", error);
    }];
}

@end
