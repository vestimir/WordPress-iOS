/*
 * CommentTableViewCell.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "VerticalAlignLabel.h"
#import "Comment.h"

#define COMMENT_ROW_HEIGHT 130

@interface CommentTableViewCell : UITableViewCell {
    Comment *comment;

    UIButton *checkButton;
    UILabel *nameLabel;
    UILabel *urlLabel;
    UILabel *postLabel;
    VerticalAlignLabel *commentLabel;
    UIImageView *gravatarImageView;

    BOOL checked;
}

+ (float) calculateCommentCellHeight:(NSString *)commentText availableWidth:(CGFloat)availableWidth;

@property (readwrite, weak) Comment *comment;
@property BOOL checked;

@end
