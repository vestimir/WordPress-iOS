/*
 * ReaderPostDetailView.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */
#import <UIKit/UIKit.h>
#import "ReaderPost.h"

@protocol ReaderPostDetailViewDelegate <NSObject>

- (void)readerPostDetailViewLayoutChanged;

@end

@interface ReaderPostDetailView : UIView

- (id)initWithFrame:(CGRect)frame post:(ReaderPost *)post delegate:(id<ReaderPostDetailViewDelegate>)delegate;
- (void)updateLayout;

@end
