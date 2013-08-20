/*
 * PostViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "EditPostViewController.h"

@class Post;

@interface PostViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIWebViewDelegate, UIActionSheetDelegate> {
    BOOL isShowingActionSheet;
}

@property (nonatomic, strong) IBOutlet UILabel *titleTitleLabel, *tagsTitleLabel, *categoriesTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel, *tagsLabel, *categoriesLabel;
@property (nonatomic, strong) IBOutlet UITextView *contentView;
@property (nonatomic, strong) IBOutlet UIWebView *contentWebView;
@property (nonatomic, strong) IBOutlet AbstractPost *apost;
@property (nonatomic, weak) Post *post;
@property (nonatomic, weak) Blog * blog;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)showModalEditor;
- (void)refreshUI;
- (void)checkForNewItem;
- (EditPostViewController *) getPostOrPageController: (AbstractPost *)revision;
- (void)showDeletePostActionSheet:(id)sender;
- (void)deletePost;
- (NSString *)formatString:(NSString *)str;
- (void)showModalPreview;
- (void)dismissPreview;

@end
