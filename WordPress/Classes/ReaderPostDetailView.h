//
//  ReaderPostDetailView.h
//  WordPress
//
//  Created by Eric J on 5/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"

extern const NSUInteger ReaderPostDetailViewEventGravatarTouched;

@protocol ReaderPostDetailViewDelegate <NSObject>

- (void)readerPostDetailViewLayoutChanged;

@end

@interface ReaderPostDetailView : UIControl

- (id)initWithFrame:(CGRect)frame post:(ReaderPost *)post delegate:(id<ReaderPostDetailViewDelegate>)delegate;
- (void)updateLayout;

@end
