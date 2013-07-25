//
//  InstapaperActivity.m
//  WordPress
//
//  Created by Jorge Bernal on 2/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "InstapaperActivity.h"

@interface InstapaperActivity ()

@property (nonatomic, strong) NSURL *url;

@end

@implementation InstapaperActivity

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNInstapaperActivity"];
}

- (NSString *)activityTitle {
    return @"Instapaper";
}

- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    NSURL *URL = [self URLFromActivityItems:activityItems];
    return (URL && [[UIApplication sharedApplication] canOpenURL:URL]);
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    self.url = [self URLFromActivityItems:activityItems];
}

- (void)performActivity {
	BOOL completed = [[UIApplication sharedApplication] openURL:self.url];

	[self activityDidFinish:completed];
}

- (NSURL *)URLFromActivityItems:(NSArray *)activityItems {
    NSURL *URL = nil;
    for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"i%@", [activityItem absoluteString]]];
		}
	}
    return URL;
}

@end
