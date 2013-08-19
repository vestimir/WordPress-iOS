//
//  EditorKeyboardToolbarButtonItem.h
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditorKeyboardToolbarButtonItem : UIButton

@property (nonatomic, strong) NSString *actionTag, *actionName, *imageName;

+ (id)button;

@end
