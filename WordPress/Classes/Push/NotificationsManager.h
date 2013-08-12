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
