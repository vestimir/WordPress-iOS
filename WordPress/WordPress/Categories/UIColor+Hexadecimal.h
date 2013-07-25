//
//  UIColor+Hexadecimal.h
//  WordPress
//
//  Created by Danilo Ercoli on 07/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hexadecimal)

//[UIColor colorFromRGBAWithRed:10 green:20 blue:30 alpha:0.8]
+(UIColor *)colorFromRGBWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b;
+(UIColor *)colorFromRGBAWithRed: (CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;

//[UIColor colorFromHex:0xc5c5c5 alpha:0.8];
+(UIColor *)colorFromHex:(NSUInteger)rgb alpha:(CGFloat)alpha; 
+(UIColor *)colorFromHex:(NSUInteger)rgb;

@end
