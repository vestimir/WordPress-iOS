//
//  PocketActivity.m
//  WordPress
//
//  Created by Jorge Bernal on 2/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>

#import "PocketActivity.h"
#import "PocketAPI.h"
#import "WordPressComApiCredentials.h"

@interface PocketActivity ()

@property (nonatomic, strong) NSURL *url;

@end

@implementation PocketActivity

+ (void)setupPocket {
    [[PocketAPI sharedAPI] setConsumerKey:[WordPressComApiCredentials pocketConsumerKey]];
}

- (void)dealloc {
    [self removeNotificationObserver];
}

- (UIImage *)activityImage {
	return [UIImage imageNamed:@"NNPocketActivity"];
}

- (NSString *)activityTitle {
	return @"Pocket";
}

- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
			return YES;
		}
	}

	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			self.url = activityItem;
		}
	}
}

- (void)performActivity {
    [SVProgressHUD show];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[PocketAPI sharedAPI] saveURL:self.url handler:^(PocketAPI *api, NSURL *url, NSError *error) {
        BOOL completed = (error == nil);
        if (completed) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Saved to %@", @""), [self activityTitle]]];
        } else {
            WPFLog(@"Failed saving to Pocket: %@ err: %@", url, error);
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed", @"")];
        }

        [self activityDidFinish:completed];
    }];
}

- (void)didEnterBackground:(NSNotification *)notification {
    [SVProgressHUD dismiss];
    [self removeNotificationObserver];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

@end
