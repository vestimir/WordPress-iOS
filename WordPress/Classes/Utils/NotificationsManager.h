/*
 * NotificationsManager.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@interface NotificationsManager : NSObject

+ (NotificationsManager*)sharedInstance;

+ (void)registerForRemotePushNotifications;
+ (void)unregisterForRemotePushNotifications;
- (void)handleRemoteNotificationFromLaunch:(NSDictionary*)notification;
- (void)handleRemoteNotification:(NSDictionary*)userInfo applicationState:(UIApplicationState)state;
- (void)didRegisterForRemoteNotifications:(NSData*)deviceToken;
- (void)didFailToRegisterForRemoteNotifications:(NSError*)error;

@end
