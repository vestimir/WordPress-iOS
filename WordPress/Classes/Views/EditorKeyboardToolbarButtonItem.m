//
//  EditorKeyboardToolbarButtonItem.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "EditorKeyboardToolbarButtonItem.h"

@implementation EditorKeyboardToolbarButtonItem

+ (id)button {
    return [EditorKeyboardToolbarButtonItem buttonWithType:UIButtonTypeCustom];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (IS_IPAD) {
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtoniPad"] stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtoniPadHighlighted"] stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        } else {
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButton"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [self setBackgroundImage:[[UIImage imageNamed:@"keyboardButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setImageName:(NSString *)imageName {
    if (IS_IPAD) {
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@iPad", _imageName]] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@iPadHighlighted", _imageName]] forState:UIControlStateHighlighted];
    } else {
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", _imageName]] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@Highlighted", _imageName]] forState:UIControlStateHighlighted];
    }
}

@end
