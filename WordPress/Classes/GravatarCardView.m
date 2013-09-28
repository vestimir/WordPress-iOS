//
//  GravatarCardView.m
//  WordPress
//
//  Created by Jorge Bernal on 9/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GravatarCardView.h"

@implementation GravatarCardView {
    UIActivityIndicatorView *_avatarActivity;
    UIActivityIndicatorView *_profileActivity;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeSubviews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeSubviews];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self  = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeSubviews];
    }
    return self;
}

- (void)initializeSubviews
{
    self.backgroundColor = [UIColor whiteColor];

    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.backgroundColor = [WPStyleGuide darkAsNightGrey];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [WPStyleGuide largePostTitleFont];

    _bioTextView = [[UITextView alloc] init];
    _bioTextView.font = [WPStyleGuide regularTextFont];
    _bioTextView.editable = NO;

    _avatarActivity = [[UIActivityIndicatorView alloc] init];
    _avatarActivity.color = [WPStyleGuide readGrey];
    _profileActivity = [[UIActivityIndicatorView alloc] init];
    _profileActivity.color = [WPStyleGuide baseLighterBlue];

    [self addSubview:_avatarImageView];
    [self addSubview:_nameLabel];
    [self addSubview:_bioTextView];
    [self addSubview:_profileActivity];
    [self addSubview:_avatarActivity];
}

- (void)layoutSubviews
{
    CGFloat width = self.frame.size.width;

    CGRect frame = self.frame;
    frame.size.height = width;
    _avatarImageView.frame = frame;
    _avatarActivity.frame = frame;

    frame = CGRectMake(0, CGRectGetMaxY(frame), width, 60);
    frame = CGRectInset(frame, 10, 10);
    _nameLabel.frame = frame;

    frame.origin.y += frame.size.height;
    frame.size.height = self.bounds.size.height - frame.origin.y;
    frame = CGRectInset(frame, 0, 10);
    _bioTextView.frame = frame;

    _profileActivity.frame = frame;
}

- (void)setProfileLoading:(BOOL)loading
{
    if (loading) {
        [_profileActivity startAnimating];
    } else {
        [_profileActivity stopAnimating];
    }
}

- (BOOL)profileLoading
{
    return [_profileActivity isAnimating];
}

- (void)setAvatarLoading:(BOOL)loading
{
    if (loading) {
        [_avatarActivity startAnimating];
    } else {
        [_avatarActivity stopAnimating];
    }
}

- (BOOL)avatarLoading
{
    return [_avatarActivity isAnimating];
}

@end
