/*
 * PostsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "PostViewController.h"
#import "WPTableViewController.h"

@class EditPostViewController;

@interface PostsViewController : WPTableViewController <UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, DetailViewDelegate>

@property (nonatomic, strong) PostViewController *postReaderViewController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSMutableArray *drafts;

- (void)showAddPostView;
- (void)reselect;
- (BOOL)refreshRequired;
- (NSString *)statsPropertyForViewOpening;

@end
