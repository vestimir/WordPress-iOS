/*
 * SidebarViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "SidebarSectionHeaderView.h"

@class Post;

@interface SidebarViewController : UIViewController <UIActionSheetDelegate, SidebarSectionHeaderViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIButton *settingsButton;
@property (nonatomic, strong) IBOutlet UIView *utililtyView;
@property (nonatomic, assign) BOOL restoringView;

- (IBAction)showSettings:(id)sender;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath;
- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath closingSidebar:(BOOL)closingSidebar;
- (void)showCommentWithId:(NSNumber *)itemId blogId:(NSNumber *)blogId;
- (void)selectNotificationsRow;

- (void)uploadQuickPhoto:(Post *)post;
- (void)restorePreservedSelection;
- (void)didReceiveUnseenNotesNotification;

@end
