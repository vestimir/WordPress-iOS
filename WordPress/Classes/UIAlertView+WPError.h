//
//  WPError.h
//  WordPress
//
//  Created by Jorge Bernal on 4/17/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIAlertView (WPError) <UIAlertViewDelegate>

+ (void)showAlertWithError:(NSError *)error title:(NSString *)title;
+ (void)showAlertWithError:(NSError *)error;
//+ (void)showHelpAlertWithTitle:(NSString *)title message:(NSString *)message;

@end
