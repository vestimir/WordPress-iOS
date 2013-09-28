//
//  GravatarCardView.h
//  WordPress
//
//  Created by Jorge Bernal on 9/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GravatarCardView : UIView

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UITextView *bioTextView;
@property BOOL profileLoading;
@property BOOL avatarLoading;

@end
