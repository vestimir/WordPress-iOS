/*
 * CreateWPComAccountViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@protocol CreateWPComAccountViewControllerDelegate;
@interface CreateWPComAccountViewController : UITableViewController

@property (nonatomic, weak) id<CreateWPComAccountViewControllerDelegate> delegate;

@end

@protocol CreateWPComAccountViewControllerDelegate <NSObject>

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName;
- (void)createdAccountWithUserName:(NSString *)userName;

@end
