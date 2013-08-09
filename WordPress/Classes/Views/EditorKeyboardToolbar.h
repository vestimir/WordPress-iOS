//
//  WPKeyboardToolbar.h
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EditorKeyboardToolbarButtonItem.h"

#define WPKT_HEIGHT_IPHONE_PORTRAIT 42.0f
#define WPKT_HEIGHT_IPHONE_LANDSCAPE 33.0f
#define WPKT_HEIGHT_IPAD_PORTRAIT 65.0f
#define WPKT_HEIGHT_IPAD_LANDSCAPE 65.0f
#define WPKT_HEIGHT_PORTRAIT (IS_IPAD ? WPKT_HEIGHT_IPAD_PORTRAIT : WPKT_HEIGHT_IPHONE_PORTRAIT)
#define WPKT_HEIGHT_LANDSCAPE (IS_IPAD ? WPKT_HEIGHT_IPAD_LANDSCAPE : WPKT_HEIGHT_IPHONE_LANDSCAPE)

@protocol EditorKeyboardToolbarDelegate <NSObject>

- (void)keyboardToolbarButtonItemPressed:(EditorKeyboardToolbarButtonItem *)buttonItem;

@end

@interface EditorKeyboardToolbar : UIView<UIInputViewAudioFeedback>

@property (nonatomic, weak) id<EditorKeyboardToolbarDelegate> delegate;

@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UIView *mainView, *extendedView;
@property (nonatomic, strong) EditorKeyboardToolbarButtonItem *boldButton, *italicsButton, *linkButton, *quoteButton, *delButton;
@property (nonatomic, strong) EditorKeyboardToolbarButtonItem *ulButton, *olButton, *liButton, *codeButton, *moreButton;
@property (nonatomic, strong) EditorKeyboardToolbarButtonItem *doneButton, *toggleButton;

@end
