//
//  GeneralWalkthroughView.h
//  WordPress
//
//  Created by DX074 on 13-06-25.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GeneralWalkthroughView : UIView <UIScrollViewDelegate, UITextFieldDelegate>

- (id)initWithFrame:(CGRect)frame andViewController:(UIViewController *)controller;
- (BOOL)areFieldsValid;
- (BOOL)hasUserOnlyEnteredValuesForDotCom;

@property (nonatomic, strong) UITextField *usernameText;
@property (nonatomic, strong) UITextField *passwordText;
@property (nonatomic, strong) UITextField *siteUrlText;

@end
