/*
 * ReaderCommentTableViewCell.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "ReaderTableViewCell.h"
#import "ReaderComment.h"

@interface ReaderCommentTableViewCell : ReaderTableViewCell

+ (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options;

+ (CGFloat)heightForComment:(ReaderComment *)comment
					  width:(CGFloat)width
				 tableStyle:(UITableViewStyle)tableStyle
			  accessoryType:(UITableViewCellAccessoryType *)accessoryType;

- (void)configureCell:(ReaderComment *)comment;

@end
