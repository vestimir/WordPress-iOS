/*
 * WordPressAppDelegate.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */



@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) PanelNavigationController *panelNavigationController;
@property (nonatomic, assign) BOOL isUploadingPost;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

@end
