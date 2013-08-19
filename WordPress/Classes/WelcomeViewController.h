/*
 * WelcomeViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController {
    BOOL isFirstRun;
}

@property (nonatomic, strong) IBOutlet UIView *logoView;
@property (nonatomic, strong) IBOutlet UIView *buttonView;
@property (nonatomic, strong) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) IBOutlet UIButton *orgBlogButton;
@property (nonatomic, strong) IBOutlet UIButton *addBlogButton;
@property (nonatomic, strong) IBOutlet UIButton *createBlogButton;
@property (nonatomic, strong) IBOutlet UILabel *createLabel;

- (IBAction)handleInfoTapped:(id)sender;
- (IBAction)handleOrgBlogTapped:(id)sender;
- (IBAction)handleAddBlogTapped:(id)sender;
- (IBAction)handleCreateBlogTapped:(id)sender;

- (IBAction)cancel:(id)sender;
- (void)automaticallyDismissOnLoginActions; //used when shown as a Real Welcome controller
- (void)showAboutView;

@end
