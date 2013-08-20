/*
 * ReaderUsersBlogsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@protocol ReaderUsersBlogsDelegate;

@interface ReaderUsersBlogsViewController : UIViewController

@property (nonatomic, weak) id<ReaderUsersBlogsDelegate>delegate;

+ (id)presentAsModalWithDelegate:(id<ReaderUsersBlogsDelegate>)delegate;

@end

@protocol ReaderUsersBlogsDelegate <NSObject>

- (void)userDidSelectBlog:(NSDictionary *)blog;

@end
