//
//  WPKeyboardToolbar.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "EditorKeyboardToolbar.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define CGColorFromRGB(rgbValue) UIColorFromRGB(rgbValue).CGColor

#pragma mark - Constants

#define kStartColor UIColorFromRGB(0xb0b7c1)
#define kEndColor UIColorFromRGB(0x9199a4)
#define kStartColorIpad UIColorFromRGB(0xb7b6bf)
#define kEndColorIpad UIColorFromRGB(0x9d9ca7)

#pragma mark Sizes

// Spacing between button groups
#define WPKT_BUTTON_SEPARATOR 6.0f

#define WPKT_BUTTON_HEIGHT_PORTRAIT 39.0f
#define WPKT_BUTTON_HEIGHT_LANDSCAPE 34.0f
#define WPKT_BUTTON_HEIGHT_IPAD 65.0f

// Button Width is icon width + padding
#define WPKT_BUTTON_PADDING_IPAD 18.0f
#define WPKT_BUTTON_PADDING_IPHONE 10.0f

// Button margin
#define WPKT_BUTTON_MARGIN_IPHONE 4.0f
#define WPKT_BUTTON_MARGIN_IPAD 0.0f

#pragma mark -

@implementation EditorKeyboardToolbar

- (CGRect)gradientFrame {
    CGRect rect = self.bounds;
    rect.origin.y += 2;
    rect.size.height -= 2;
    return rect;
}

- (void)drawTopBorder {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x404040));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x52555b));        
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 0.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 0.5f);
    CGContextStrokePath(context);
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xd9d9d9));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xdbdfe4));
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 1.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 1.5f);
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
}

- (void)drawRect:(CGRect)rect {
    [self drawTopBorder];
}

- (void)buttonAction:(EditorKeyboardToolbarButtonItem *)sender {
    WPFLogMethod();
    if (![sender.actionTag isEqualToString:@"done"]) {
        [[UIDevice currentDevice] playInputClick];        
    }
    if (self.delegate) {
        [self.delegate keyboardToolbarButtonItemPressed:sender];
    }
}

- (void)buildMainButtons {
    CGFloat x = 4.0f;
    CGFloat padding = IS_IPAD ? WPKT_BUTTON_PADDING_IPAD : WPKT_BUTTON_PADDING_IPHONE;
    CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
	CGFloat margin = IS_IPAD ? WPKT_BUTTON_MARGIN_IPAD : WPKT_BUTTON_MARGIN_IPHONE;
    if (_boldButton == nil) {
        _boldButton = [EditorKeyboardToolbarButtonItem button];
        [_boldButton setImageName:@"toolbarBold"];
        _boldButton.frame = CGRectMake(x, 0, _boldButton.imageView.image.size.width + padding, height);
        x += _boldButton.frame.size.width + margin;
        _boldButton.actionTag = @"strong";
        _boldButton.actionName = NSLocalizedString(@"bold", @"Bold text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [_boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_italicsButton == nil) {
        _italicsButton = [EditorKeyboardToolbarButtonItem button];
        [_italicsButton setImageName:@"toolbarItalic"];
        _italicsButton.frame = CGRectMake(x, 0, _italicsButton.imageView.image.size.width + padding, height);
        x += _italicsButton.frame.size.width + margin;
        _italicsButton.actionTag = @"em";
        _italicsButton.actionName = NSLocalizedString(@"italic", @"Italic text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [_italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_linkButton == nil) {
        _linkButton = [EditorKeyboardToolbarButtonItem button];
        [_linkButton setImageName:@"toolbarLink"];
        _linkButton.frame = CGRectMake(x, 0, _linkButton.imageView.image.size.width + padding, height);
        x += _linkButton.frame.size.width + margin;
        _linkButton.actionTag = @"link";
        _linkButton.actionName = NSLocalizedString(@"link", @"Link helper button in the Post Editor. This string will be used in the Undo message if the last change was adding a link.");
        [_linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_quoteButton == nil) {
        _quoteButton = [EditorKeyboardToolbarButtonItem button];
        [_quoteButton setImageName:@"toolbarBlockquote"];
        _quoteButton.frame = CGRectMake(x, 0, _quoteButton.imageView.image.size.width + padding, height);
		x += _quoteButton.frame.size.width + margin;
        _quoteButton.actionTag = @"blockquote";
        _quoteButton.actionName = NSLocalizedString(@"quote", @"Blockquote HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a blockquote.");
        [_quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_delButton == nil) {
        _delButton = [EditorKeyboardToolbarButtonItem button];
        [_delButton setImageName:@"toolbarDel"];
        _delButton.frame = CGRectMake(x, 0, _delButton.imageView.image.size.width + padding, height);
        _delButton.actionTag = @"del";
        _delButton.actionName = NSLocalizedString(@"del", @"<del> (deleted text) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a <del> HTML element.");
        [_delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildExtendedButtons {
    CGFloat padding = IS_IPAD ? WPKT_BUTTON_PADDING_IPAD : WPKT_BUTTON_PADDING_IPHONE;
    CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
	CGFloat margin = IS_IPAD ? WPKT_BUTTON_MARGIN_IPAD : WPKT_BUTTON_MARGIN_IPHONE;
    CGFloat x = 4.0f;
    if (_ulButton == nil) {
        _ulButton = [EditorKeyboardToolbarButtonItem button];
        [_ulButton setImageName:@"toolbarUl"];
        _ulButton.frame = CGRectMake(x, 0, _ulButton.imageView.image.size.width + padding, height);
        x += _ulButton.frame.size.width + margin;
        _ulButton.actionTag = @"ul";
        _ulButton.actionName = NSLocalizedString(@"unordered list", @"Unordered list (ul) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [_ulButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_olButton == nil) {
        _olButton = [EditorKeyboardToolbarButtonItem button];
        [_olButton setImageName:@"toolbarOl"];
        _olButton.frame = CGRectMake(x, 0, _olButton.imageView.image.size.width + padding, height);
        x += _olButton.frame.size.width + margin;
        _olButton.actionTag = @"ol";
        _olButton.actionName = NSLocalizedString(@"ordered list", @"Ordered list (<ol>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [_olButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_liButton == nil) {
        _liButton = [EditorKeyboardToolbarButtonItem button];
        [_liButton setImageName:@"toolbarLi"];
        _liButton.frame = CGRectMake(x, 0, _liButton.imageView.image.size.width + padding, height);
        x += _liButton.frame.size.width + margin;
        _liButton.actionTag = @"li";
        _liButton.actionName = NSLocalizedString(@"list item", @"List item (<li>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [_liButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_codeButton == nil) {
        _codeButton = [EditorKeyboardToolbarButtonItem button];
        [_codeButton setImageName:@"toolbarCode"];
        _codeButton.frame = CGRectMake(x, 0, _codeButton.imageView.image.size.width + padding, height);
        x += _codeButton.frame.size.width + margin;
        _codeButton.actionTag = @"code";
        _codeButton.actionName = NSLocalizedString(@"code", @"Code (<code>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [_codeButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_moreButton == nil) {
        _moreButton = [EditorKeyboardToolbarButtonItem button];
        [_moreButton setImageName:@"toolbarMore"];
        _moreButton.frame = CGRectMake(x, 0, _moreButton.imageView.image.size.width + padding, height);
        _moreButton.actionTag = @"more";
        _moreButton.actionName = NSLocalizedString(@"more", @"Adding a More excerpt cut-off in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [_moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildMainView {
    if (_mainView == nil) {
        CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
        _mainView = [[UIView alloc] init];
        [self buildMainButtons];
        CGFloat mainWidth = _delButton.frame.origin.x + _delButton.frame.size.width;
        _mainView.frame = CGRectMake(0, 0, mainWidth, height);
        _mainView.autoresizesSubviews = YES;

        [_mainView addSubview:_boldButton];
        [_mainView addSubview:_italicsButton];
        [_mainView addSubview:_linkButton];
        [_mainView addSubview:_quoteButton];
        [_mainView addSubview:_delButton];
    }
}

- (void)buildExtendedView {
    if (_extendedView == nil) {
        CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
        _extendedView = [[UIView alloc] init];
        [self buildExtendedButtons];
        CGFloat extendedWidth = _moreButton.frame.origin.x + _moreButton.frame.size.width;
        _extendedView.frame = CGRectMake(0, 0, extendedWidth, height);
        [_extendedView addSubview:_ulButton];
        [_extendedView addSubview:_olButton];
        [_extendedView addSubview:_liButton];
        [_extendedView addSubview:_codeButton];
        [_extendedView addSubview:_moreButton];
    }
}

- (void)toggleExtendedView {
	WPFLogMethod();
    [[UIDevice currentDevice] playInputClick];        
	if (!_toggleButton.selected == true) {
		[_toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonExtended"] forState:UIControlStateNormal];
	}
	else {
		[_toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateNormal];
	}

    _toggleButton.selected = !_toggleButton.selected;
    [self setNeedsLayout];
}

- (void)buildToggleButton {
    if (_toggleButton == nil) {
        _toggleButton = [EditorKeyboardToolbarButtonItem button];
        _toggleButton.frame = CGRectMake(2, 2, 39, 39);
        _toggleButton.adjustsImageWhenHighlighted = NO;
        [_toggleButton addTarget:self action:@selector(toggleExtendedView) forControlEvents:UIControlEventTouchDown];
		[_toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateNormal];
		//[_toggleButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateHighlighted];
		[_toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonExtended"] forState:UIControlStateSelected];
		[_toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateSelected || UIControlStateHighlighted];
    }    
}

- (void)setupDoneButton {
    if (_doneButton == nil) {
        _doneButton = [EditorKeyboardToolbarButtonItem button];
        _doneButton.frame = CGRectMake(4, 2, 50, 39);
        [_doneButton setTitle:@"Done" forState:UIControlStateNormal];
		_doneButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	    _doneButton.actionTag = @"done";
        [_doneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        if (IS_IPAD) {
            _doneButton.titleLabel.font = [UIFont systemFontOfSize:22.0f];
            [_doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_doneButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            _doneButton.titleLabel.shadowOffset = CGSizeMake(0, 1.0f);
            _doneButton.titleEdgeInsets = UIEdgeInsetsMake(2, 2, 0, 0); // Needed to make the label align
        } else {
            _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
            _doneButton.titleLabel.shadowColor = [UIColor darkGrayColor];
            _doneButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0);
            _doneButton.contentEdgeInsets = UIEdgeInsetsMake(1, 1, 0, 0); // Needed to make the label align
            [_doneButton setBackgroundImage:[[UIImage imageNamed:@"doneButton"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [_doneButton setBackgroundImage:[[UIImage imageNamed:@"doneButtonHighlighted"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        }
        [self addSubview:_doneButton];
    }
}

- (void)setupView {
    self.backgroundColor = UIColorFromRGB(0xb0b7c1);
    _gradient = [CAGradientLayer layer];
    _gradient.frame = [self gradientFrame];
    if (IS_IPAD) {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColorIpad.CGColor, (id)kEndColorIpad.CGColor, nil];
    } else {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColor.CGColor, (id)kEndColor.CGColor, nil];
    }
    [self.layer insertSublayer:_gradient atIndex:0];
    
    [self buildMainView];
    [self buildExtendedView];
    [self buildToggleButton];
    [self setupDoneButton];
}

- (void)layoutSubviews {
    _gradient.frame = [self gradientFrame];
    
    CGRect doneFrame = _doneButton.frame;
    doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
    if (IS_IPAD) {
        doneFrame.size.height = WPKT_BUTTON_HEIGHT_IPAD;
        doneFrame.size.width = WPKT_BUTTON_HEIGHT_IPAD + 14.0f;
        doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
        doneFrame.origin.y = 0;
    } else {
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            doneFrame.origin.y = -1;
            doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 3;
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE + 2;
        } else {
            doneFrame.origin.y = 2;
            doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }        
    }
    _doneButton.frame = doneFrame;
    
    CGRect toggleFrame = _toggleButton.frame;
    toggleFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
    _toggleButton.frame = toggleFrame;
    
    if (self.frame.size.width <= 320.0f) {
        // iPhone portrait
        
        // Add toggle button
        if (_toggleButton.superview == nil) {
            [self addSubview:_toggleButton];
        }

        if (_toggleButton.selected) {
            // Remove main view
            if (_mainView.superview != nil) {
                [_mainView removeFromSuperview];
            }
            
            // Show extended view
            CGRect frame = _extendedView.frame;
            frame.origin.x = _toggleButton.frame.origin.x + _toggleButton.frame.size.width + 3;
            frame.origin.y = 2;
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
            _extendedView.frame = frame;
            if (_extendedView.superview == nil) {
                [self addSubview:_extendedView];
            }
        } else {
            // Remove extended view
            if (_extendedView.superview != nil) {
                [_extendedView removeFromSuperview];
            }
            
            // Show main view
            CGRect frame = _mainView.frame;
            frame.origin.x = _toggleButton.frame.origin.x + _toggleButton.frame.size.width + 3;
            frame.origin.y = 2;
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
            _mainView.frame = frame;
            if (_mainView.superview == nil) {
                [self addSubview:_mainView];            
            }            
        }
    } else {
        // iPhone Landscape or iPad

        // Remove toggle button
        if (_toggleButton.superview != nil) {
            [_toggleButton removeFromSuperview];
        }
		
        // Show main view
        CGRect frame = _mainView.frame;
        frame.origin.x = -1;
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            frame.origin.y = -1;
            frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        }
        _mainView.frame = frame;
        if (_mainView.superview == nil) {
            [self addSubview:_mainView];
        }
        
        frame = _extendedView.frame;
        frame.origin.x = _mainView.frame.origin.x + _mainView.frame.size.width;
		if (IS_IPAD) frame.origin.x -= 4; // Dirty fix, but works for now
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            frame.origin.y = -1;
            frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        }
        _extendedView.frame = frame;
        if (_extendedView.superview == nil) {
            [self addSubview:_extendedView];
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

@end
