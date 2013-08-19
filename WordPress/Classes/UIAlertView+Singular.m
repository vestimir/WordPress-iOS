/*
 * UIAlertView+Singular.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "UIAlertView+Singular.h"
#import <objc/runtime.h>

static bool isShowingAlert = false;

@implementation UIAlertView (Singular)

+ (void)load {
    SEL originalShow = @selector(show);
    SEL managedShow = @selector(managed_show);
    SEL originalClicked = @selector(dismissWithClickedButtonIndex:animated:);
    SEL managedClicked = @selector(managed_dismissWithClickedButtonAtIndex:);
    
    Method originalShowMethod = class_getInstanceMethod(UIAlertView.class, originalShow);
    Method managedShowMethod = class_getInstanceMethod(UIAlertView.class, managedShow);
    Method originalClickedMethod = class_getInstanceMethod(UIAlertView.class, originalClicked);
    Method managedClickedMethod = class_getInstanceMethod(UIAlertView.class, managedClicked);
    
    method_exchangeImplementations(originalShowMethod, managedShowMethod);
    method_exchangeImplementations(originalClickedMethod, managedClickedMethod);
}

- (void)managed_show {
    if (!isShowingAlert) {
        isShowingAlert = true;
        [self managed_show];
    }
}

- (void)managed_dismissWithClickedButtonAtIndex:(NSUInteger)index {
    [self managed_dismissWithClickedButtonAtIndex:index];
    isShowingAlert = false;
}

@end
