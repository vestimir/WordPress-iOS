/*
 * BetaUIWindow.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "BetaFeedbackViewController.h"

@interface BetaUIWindow : UIWindow

@property (nonatomic, strong) BetaFeedbackViewController *betaFeedbackViewController;

@end
