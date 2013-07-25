//
//  SettingsViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 6/1/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate <NSObject>

- (void)controllerDidDismiss:(UIViewController *)controller cancelled:(BOOL)cancelled;

@end

@interface SettingsViewController : UITableViewController

@end
