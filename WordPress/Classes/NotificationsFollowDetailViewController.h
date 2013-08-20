/*
 * NotificationsLikesDetailViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "Note.h"

@interface NotificationsFollowDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Note *note;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *postTitleView;
@property (nonatomic, strong) IBOutlet UIImageView *postBlavatar;
@property (nonatomic, strong) IBOutlet UILabel *postTitleLabel;
@property (nonatomic, strong) IBOutlet UIButton *postTitleButton;

- (void)loadWebViewWithURL: (NSString*)url;
- (IBAction)viewPostTitle:(id)sender;
- (IBAction)highlightButton:(id)sender;
- (IBAction)resetButton:(id)sender;

@end
