/*
 * NotificationsManager.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

extern NSString *const WordPressComApiNotificationPreferencesKey;
extern NSString *const WordPressComApiUnseenNotesNotification;
extern NSString *const WordPressComApiNotesUserInfoKey;
extern NSString *const WordPressComApiUnseenNoteCountInfoKey;

@interface NotificationsManager : NSObject

+ (NotificationsManager*)sharedInstance;

+ (void)registerForRemotePushNotifications;
+ (void)unregisterForRemotePushNotifications;
+ (void)syncPushNotificationSettings;

- (void)handleRemoteNotificationFromLaunch:(NSDictionary*)notification;
- (void)handleRemoteNotification:(NSDictionary*)userInfo applicationState:(UIApplicationState)state;
- (void)didRegisterForRemoteNotifications:(NSData*)deviceToken;
- (void)didFailToRegisterForRemoteNotifications:(NSError*)error;

@end

@interface NotificationsManager (WordPressComApi)

- (void)saveNotificationSettings:(NSDictionary*)settings success:(void(^)())success failure:(void(^)(NSError *error))failure;
- (void)fetchNotificationSettingsWithSuccess:(void(^)())success failure:(void(^)(NSError *error))failure;
- (void)checkForUnseenNotifications;

@end
