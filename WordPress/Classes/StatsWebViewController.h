/*
 * StatsWebViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPChromelessWebViewController.h"

@class Blog;

#define kSelectedBlogChanged @"kSelectedBlogChanged"

@interface StatsWebViewController : WPChromelessWebViewController <UIAlertViewDelegate>

@property (nonatomic, strong) Blog *blog;

- (void)initStats;
- (void)promptForCredentials;
- (void)authStats;
- (void)loadStats;

@end
