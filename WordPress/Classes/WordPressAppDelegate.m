/*
 * WordPressAppDelegate.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Crashlytics/Crashlytics.h>
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"
#import "WordPressComApiCredentials.h"
#import "WPMobileStats.h"
#import "ReachabilityUtils.h"
#import "WordPressDataModel.h"
#import "FileLogger.h"
#import "NotificationsManager.h"
#import "MediaManager.h"
#import <PocketAPI/PocketAPI.h>
#import "CameraPlusPickerManager.h"
#import "WPAccount.h"
#import "UpdateChecker.h"
#import "UserAgent.h"
#import "Blog.h"
#import <GPPShare.h>

#import <UIDeviceHardware.h>
#import "UIDevice+WordPressIdentifier.h"
#import "NSString+Helpers.h"
#import "HelpViewController.h"

@interface WordPressAppDelegate () <CrashlyticsDelegate>

@property (nonatomic, assign) BOOL listeningForBlogChanges;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;

@end

@implementation WordPressAppDelegate

#pragma mark - Class Methods

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate {
    return (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self configureCrashlytics];
    
    // Since crashlytics is keeping a copy of the logs, we don't need to anymore
    // Start with an empty log file when the app launches
    [[FileLogger sharedInstance] reset];

    [self printExtraDebugInfo];
    
    [UserAgent setupAppUserAgent];
    [WPMobileStats initializeStats];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [ReachabilityUtils startReachabilityNotifier];
    
	[WordPressDataModel initializeCoreData];
	
	[self toggleExtraDebuggingIfNeeded];
    
	// Stats use core data, so run them after initialization
    [UpdateChecker checkForUpdateAndSendDeviceStats];
    
    // Move into notifier/op / visible panel in base view class
//    [self checkWPcomAuthentication];
    
    [self customizeAppearance];
    
    [WordPressComApi setupSingleSignOn];
    
    // View hierarchy setup
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    
    self.panelNavigationController = [[PanelNavigationController alloc] init];
    [self.window setRootViewController:self.panelNavigationController];
    
    
	//listener for XML-RPC errors
	//in the future we could put the errors message in a dedicated screen that users can bring to front when samething went wrong, and can take a look at the error msg.
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:kXML_RPC_ERROR_OCCURS object:nil];
//	
//	// another notification message came from comments --> CommentUploadFailed
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"CommentUploadFailed" object:nil];
//    
//    // another notification message came from WPWebViewController
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"OpenWebPageFailed" object:nil];
    
  	[self.window makeKeyAndVisible];
    
	[NotificationsManager registerForRemotePushNotifications];
    
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        [[NotificationsManager sharedInstance] handleRemoteNotificationFromLaunch:remoteNotif];
    }
    
    
#if DEBUG
    /*
     A dictionary containing the credentials for all available protection spaces.
     The dictionary has keys corresponding to the NSURLProtectionSpace objects.
     The values for the NSURLProtectionSpace keys consist of dictionaries where the keys are user name strings, and the value is the corresponding NSURLCredential object.
     */
    [[[NSURLCredentialStorage sharedCredentialStorage] allCredentials] enumerateKeysAndObjectsUsingBlock:^(NSURLProtectionSpace *ps, NSDictionary *dict, BOOL *stop) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSURLCredential *credential, BOOL *stop) {
            NSLog(@"Removing credential %@ for %@", [credential user], [ps host]);
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:ps];
        }];
    }];
#endif
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[GPPShare sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation]) {
        return YES;
    }

    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }

//    if ([facebook handleOpenURL:url]){
//        return YES;
//    }

    if ([[CameraPlusPickerManager sharedManager] shouldHandleURLAsCameraPlusPickerCallback:url]) {
        /* Note that your application has been in the background and may have been terminated.
         * The only CameraPlusPickerManager state that is restored is the pickerMode, which is
         * restored to indicate the mode used to pick images.
         */

        /* Handle the callback and notify the delegate. */
        [[CameraPlusPickerManager sharedManager] handleCameraPlusPickerCallback:url usingBlock:^(CameraPlusPickedImages *images) {
            NSLog(@"Camera+ returned %@", [images images]);
            UIImage *image = [images image];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:image forKey:@"image"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kCameraPlusImagesNotification object:nil userInfo:userInfo];
        } cancelBlock:^(void) {
            NSLog(@"Camera+ picker canceled");
        }];
        return YES;
    }

    if ([WordPressApi handleOpenURL:url]) {
        return YES;
    }
    
    if (url && [url isKindOfClass:[NSURL class]]) {
        NSString *URLString = [url absoluteString];
        NSLog(@"Application launched with URL: %@", URLString);
        if ([[url absoluteString] hasPrefix:@"wordpress://wpcom_signup_completed"]) {
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            // WPFLog(@"%@", params);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"wpcomSignupNotification" object:nil userInfo:params];
            return YES;
        }
    }

    return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self resetAppBadge];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    [WPMobileStats trackEventForWPComWithSavedProperties:StatsEventAppClosed];
    [WPMobileStats resetStatsRelatedVariables];
    
    // Keep the app alive in the background if we are uploading a post, currently only used for quick photo posts
    if (!_isUploadingPost) {
        if (_bgTask != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }
    }
    
    _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_bgTask != UIBackgroundTaskInvalid)
            {
                [application endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    [[WordPressDataModel sharedDataModel] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [MediaManager cleanUnusedFiles];
    [[NotificationsManager sharedInstance] checkForUnseenNotifications];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    // TODO - Shouldn't actually dismiss things, as the user can come right back.
    // Toggling the pull-down notification enter causes this delegate method to run. Spamming notifications
    
//    if (passwordAlertRunning && passwordTextField != nil)
//        [passwordTextField resignFirstResponder];
//    else
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"DismissAlertViewKeyboard" object:nil];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    // TODO There is already a notification for this...
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
    
    if ([WPMobileStats hasRecordedAppLaunched]) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpened];
    }
    
    // Clear notifications badge and update server
    [self resetAppBadge];
    [NotificationsManager syncPushNotificationSettings];
}

#pragma mark -
#pragma mark Public Methods

+ (void)showHelpAlertWithTitle:(NSString *)title message:(NSString *)message {
	WPLog(@"Showing alert with title: %@", message);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:[WordPressAppDelegate sharedWordPressApplicationDelegate]
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label.")
                                          otherButtonTitles:NSLocalizedString(@"Need Help?", @"'Need help?' button label, links off to the WP for iOS FAQ."), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        HelpViewController *helpViewController = [[HelpViewController alloc] init];
        UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
        if (IS_IPAD) {
            aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        UIViewController *presenter = self.panelNavigationController;
        if (presenter.presentedViewController) {
            presenter = presenter.presentedViewController;
        }
        [presenter presentViewController:aNavigationController animated:YES completion:nil];
    }
}

//- (void)showNotificationErrorAlert:(NSNotification *)notification {
//	NSString *cleanedErrorMsg = nil;
//	
//	if([self isAlertRunning] == YES) return; //another alert is already shown
//	[self setAlertRunning:YES];
//	
//	if([[notification object] isKindOfClass:[NSError class]]) {
//		
//		NSError *err  = (NSError *)[notification object];
//		cleanedErrorMsg = [err localizedDescription];
//		
//		//org.wordpress.iphone --> XML-RPC errors
//		if ([[err domain] isEqualToString:@"org.wordpress.iphone"]){
//			if([err code] == 401)
//				cleanedErrorMsg = NSLocalizedString(@"Sorry, you cannot access this feature. Please check your User Role on this blog.", @"");
//		}
//        
//        // ignore HTTP auth canceled errors
//        if ([err.domain isEqual:NSURLErrorDomain] && err.code == NSURLErrorUserCancelledAuthentication) {
//            [self setAlertRunning:NO];
//            return;
//        }
//	} else { //the notification obj is a String
//		cleanedErrorMsg  = (NSString *)[notification object];
//	}
//	
//	if([cleanedErrorMsg rangeOfString:@"NSXMLParserErrorDomain"].location != NSNotFound )
//		cleanedErrorMsg = NSLocalizedString(@"The app can't recognize the server response. Please, check the configuration of your blog.", @"");
//	
//	[self showAlertWithTitle:NSLocalizedString(@"Error", @"Generic popup title for any type of error.") message:cleanedErrorMsg];
//}

#pragma mark -
#pragma mark Private Methods

- (void)customizeAppearance {
    // Configure global styles.
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar_bg"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_bg"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0],
      UITextAttributeTextColor,
      [UIColor whiteColor],
      UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
      UITextAttributeTextShadowOffset,
      nil]];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0]];
    
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_active"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_landscape"] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_landscape_active"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_active"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_landscape"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_landscape_active"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
    
    NSDictionary *titleTextAttributesForStateNormal = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIColor colorWithRed:34.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1.0],
                                                       UITextAttributeTextColor,
                                                       [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                       UITextAttributeTextShadowColor,
                                                       [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                       UITextAttributeTextShadowOffset,
                                                       nil];
    
    
    NSDictionary *titleTextAttributesForStateDisabled = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0],
                                                         UITextAttributeTextColor,
                                                        [UIColor colorFromHex:0xeeeeee],
                                                         UITextAttributeTextShadowColor,
                                                         [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                         UITextAttributeTextShadowOffset,
                                                         nil];
    
    NSDictionary *titleTextAttributesForStateHighlighted = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            [UIColor colorWithRed:34.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1.0],
                                                            UITextAttributeTextColor,
                                                            [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                            UITextAttributeTextShadowColor,
                                                            [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                            UITextAttributeTextShadowOffset,
                                                            nil];
    
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateDisabled forState:UIControlStateDisabled];
    [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateHighlighted forState:UIControlStateHighlighted];
    
    [[UISegmentedControl appearance] setTintColor:[UIColor colorFromHex:0xeeeeee]];
    [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateDisabled forState:UIControlStateDisabled];
    [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateHighlighted forState:UIControlStateHighlighted];
}

- (void)resetAppBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

// TODO move to a dependent op or at least runnable inside networking
//- (void)checkWPcomAuthentication {
//	NSString *authURL = @"https://wordpress.com/xmlrpc.php";
//    
//    WPAccount *account = [WPAccount defaultWordPressComAccount];
//	if (account) {
//        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
//        [client callMethod:@"wp.getUsersBlogs"
//                parameters:[NSArray arrayWithObjects:account.username, account.password, nil]
//                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                       isWPcomAuthenticated = YES;
//                       WPFLog(@"Logged in to WordPress.com as %@", account.username);
//                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                       if ([error.domain isEqualToString:@"XMLRPC"] && error.code == 403) {
//                           isWPcomAuthenticated = NO;
//                       }
//                       WPFLog(@"Error authenticating %@ with WordPress.com: %@", account.username, [error description]);
//                   }];
//	} else {
//		isWPcomAuthenticated = NO;
//	}
//    
//	if (isWPcomAuthenticated)
//		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
//	else
//		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
//}


- (void)handleLogoutOrBlogsChangedNotification:(NSNotification *)notification {
	[self toggleExtraDebuggingIfNeeded];
}


#pragma mark - Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[NotificationsManager sharedInstance] didRegisterForRemoteNotifications:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	[[NotificationsManager sharedInstance] didFailToRegisterForRemoteNotifications:error];
}

// The notification is delivered when the application is running
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    application.applicationIconBadgeNumber = 0;

    [[NotificationsManager sharedInstance] handleRemoteNotification:userInfo applicationState:application.applicationState];
}

#pragma mark - Crashlytics

- (void)configureCrashlytics {
#if DEBUG
    return;
#endif
    
    if ([[WordPressComApiCredentials crashlyticsApiKey] length] == 0) {
        return;
    }
    
    [Crashlytics startWithAPIKey:[WordPressComApiCredentials crashlyticsApiKey]];
    [[Crashlytics sharedInstance] setDelegate:self];

    [self setCommonCrashlyticsParameters];
    
    if ([WPAccount defaultWordPressComAccount].username) {
        [Crashlytics setUserName:[WPAccount defaultWordPressComAccount].username];
    }
    
    void (^wpcomLoggedInBlock)(NSNotification *) = ^(NSNotification *note) {
        [Crashlytics setUserName:[WPAccount defaultWordPressComAccount].username];
        [self setCommonCrashlyticsParameters];
    };
    void (^wpcomLoggedOutBlock)(NSNotification *) = ^(NSNotification *note) {
        [Crashlytics setUserName:nil];
        [self setCommonCrashlyticsParameters];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:wpcomLoggedInBlock];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:wpcomLoggedOutBlock];
}

- (void)setCommonCrashlyticsParameters
{
    [Crashlytics setObjectValue:[NSNumber numberWithBool:[WPAccount defaultWordPressComAccount].isWpComAuthenticated] forKey:@"logged_in"];
    [Crashlytics setObjectValue:@([WPAccount defaultWordPressComAccount].isWpComAuthenticated) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([Blog countWithContext:[[WordPressDataModel sharedDataModel] managedObjectContext]]) forKey:@"number_of_blogs"];
}

- (void)crashlytics:(Crashlytics *)crashlytics didDetectCrashDuringPreviousExecution:(id<CLSCrashReport>)crash
{
    WPFLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
    [WPMobileStats trackEventForSelfHostedAndWPCom:@"Crashed" properties:@{@"crash_id": crash.identifier}];
}


#pragma mark - Debug

- (void)printExtraDebugInfo {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"crashCount"];
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    NSString *extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"] ? @"YES" : @"NO";
    WPFLog(@"===========================================================================");
	WPFLog(@"Launching WordPress for iOS %@...", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    WPFLog(@"Crash count:       %d", crashCount);
#ifdef DEBUG
    WPFLog(@"Debug mode:  Debug");
#else
    WPFLog(@"Debug mode:  Production");
#endif
    WPFLog(@"Extra debug: %@", extraDebug);
    WPFLog(@"Device model: %@ (%@)", [UIDeviceHardware platformString], [UIDeviceHardware platform]);
    WPFLog(@"OS:        %@ %@", [device systemName], [device systemVersion]);
    WPFLog(@"Language:  %@", currentLanguage);
    WPFLog(@"UDID:      %@", [device wordpressIdentifier]);
    WPFLog(@"APN token: %@", [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey]);
    WPFLog(@"===========================================================================");
}

- (void)toggleExtraDebuggingIfNeeded {
    if (!_listeningForBlogChanges) {
        _listeningForBlogChanges = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutOrBlogsChangedNotification:) name:BlogChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutOrBlogsChangedNotification:) name:WordPressComApiDidLogoutNotification object:nil];
    }
    
	int num_blogs = [Blog countWithContext:[[WordPressDataModel sharedDataModel] managedObjectContext]];
	BOOL authed = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"] boolValue];
	if (num_blogs == 0 && !authed) {
		// When there are no blogs in the app the settings screen is unavailable.
		// In this case, enable extra_debugging by default to help troubleshoot any issues.
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"orig_extra_debug"] != nil) {
			return; // Already saved. Don't save again or we could loose the original value.
		}
		
		NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"] ? @"YES" : @"NO";
		[[NSUserDefaults standardUserDefaults] setObject:origExtraDebug forKey:@"orig_extra_debug"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"extra_debug"];
		[NSUserDefaults resetStandardUserDefaults];
	} else {
		NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] stringForKey:@"orig_extra_debug"];
		if(origExtraDebug == nil) {
			return;
		}
		
		// Restore the original setting and remove orig_extra_debug.
		[[NSUserDefaults standardUserDefaults] setBool:[origExtraDebug boolValue] forKey:@"extra_debug"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"orig_extra_debug"];
		[NSUserDefaults resetStandardUserDefaults];
	}
}

@end
