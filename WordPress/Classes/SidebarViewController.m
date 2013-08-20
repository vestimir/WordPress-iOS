/*
 * SidebarViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <QuartzCore/QuartzCore.h>

#import "SidebarViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "SidebarSectionHeaderView.h"
#import "SidebarTableViewCell.h"
#import "SectionInfo.h"
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "SettingsViewController.h"
#import "StatsWebViewController.h"
#import "PanelNavigationConstants.h"
#import "WPWebViewController.h"
#import "WPAccount.h"
#import "CameraPlusPickerManager.h"
#import "QuickPhotoViewController.h"
#import "QuickPhotoButtonView.h"
#import "NotificationsViewController.h"
//#import "SoundUtil.h"
#import "ReaderPostsViewController.h"
#import "GeneralWalkthroughViewController.h"
#import "WordPressDataModel.h"

// Height for reader/notification/blog cells
NSUInteger const SIDEBAR_CELL_HEIGHT = 51.0f;
// Height for secondary cells (posts/pages/comments/... inside a blog)
NSUInteger const SIDEBAR_CELL_SECONDARY_HEIGHT = 48.0f;
// Max width for right view (currently : size of the sidebar_comment_bubble image)
NSUInteger const SIDEBAR_CELL_ACCESSORY_MAX_WIDTH = 54.0f;
NSUInteger const HEADER_HEIGHT = 42.0f;
NSUInteger const DEFAULT_ROW_HEIGHT = 48;
NSUInteger const NUM_ROWS = 6;

NSString *const kSelectedSidebarIndexDictionary = @"kSelectedSidebarIndexDictionary";

@interface SidebarViewController () <NSFetchedResultsControllerDelegate, QuickPhotoButtonViewDelegate>

@property (nonatomic, strong) Post *currentQuickPost;
@property (nonatomic, weak) QuickPhotoButtonView *quickPhotoButton;
@property (nonatomic, strong) UIActionSheet *quickPhotoActionSheet;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, weak) SectionInfo *openSection;
@property (nonatomic, strong) NSMutableArray *sectionInfoArray;
@property (nonatomic, strong) NSArray *sidebarItems;
@property (readonly) NSInteger topSectionRowCount;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, assign) NSUInteger openSectionIdx;
@property (nonatomic, assign) BOOL hasUnseenNotes;
@property (nonatomic, assign) BOOL showingWelcomeScreen;
@property (nonatomic, assign) BOOL selectionRestored;
@property (nonatomic, assign) BOOL changingContentForSelectedSection;
@property (nonatomic, assign) BOOL wantedSection;

@end

@implementation SidebarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Section 0 and 1 sidebar items
        self.sidebarItems = @[// Section 0
                              @[@{@"title": NSLocalizedString(@"Reader", @"Menu item to view the Reader for WordPress.com blogs"), @"icon": @"sidebar_read"},
                                @{@"title": NSLocalizedString(@"Notifications", @"Menu item to view Notifications"), @"icon": @"sidebar_notifications"},],
                              
                              // Section 1
                              @[@{@"title": NSLocalizedString(@"Posts", @"Menu item to view posts"), @"icon": @"sidebar_posts"},
                                @{@"title": NSLocalizedString(@"Pages", @"Menu item to view pages"), @"icon": @"sidebar_pages"},
                                @{@"title": NSLocalizedString(@"Comments", @"Menu item to view comments"), @"icon": @"sidebar_comments"},
                                @{@"title": NSLocalizedString(@"Stats", @"Menu item to view Jetpack stats associated with a blog"), @"icon": @"sidebar_stats"},
                                @{@"title": NSLocalizedString(@"View Site", @"Menu item to view the site in a an in-app web view"), @"icon": @"sidebar_view"},
                                @{@"title": NSLocalizedString(@"View Admin", @"Menu item to load the dashboard in a an in-app web view"), @"icon": @"sidebar_dashboard"}]
                              ];
    }
    return self;
}

- (void)dealloc {
    self.resultsController.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_bg"]];

    self.utililtyView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sidebar_footer_bg"]];
    self.utililtyView.layer.shadowRadius = 10.0f;
    self.utililtyView.layer.shadowOpacity = 0.8f;
    self.utililtyView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.utililtyView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    self.utililtyView.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:self.utililtyView.bounds cornerRadius:PANEL_CORNER_RADIUS] CGPath];
    
    [self setupSettingsButton];
    
    void (^wpcomNotificationBlock)(NSNotification *) = ^(NSNotification *note) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        if (selectedIndexPath == nil || ([WPAccount defaultWordPressComAccount] == nil && (selectedIndexPath.section == 0))) {
            [self selectFirstAvailableItem];
        }
        [self checkNothingToShow];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:WPAccountDefaultWordPressComAccountChangedNotification object:nil queue:nil usingBlock:wpcomNotificationBlock];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCameraPlusImages:) name:kCameraPlusImagesNotification object:nil];
    
    //WPCom notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectNotificationsRow)
												 name:@"SelectNotificationsRow" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveUnseenNotesNotification)
												 name:@"WordPressComUnseenNotes" object:nil];
    
    if (_currentIndexPath) {
        // If we are restoring the view after a memory warning we want to try to set the tableview back to the selected row and section
        // Since controllerDidChangeContent will be triggered after the view is recreated, we want to restore our place from there, 
        // and not here. 
        _restoringView = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // create the sectionInfoArray, stores data for collapsing/expanding sections in the tableView
	if (self.sectionInfoArray == nil) {
        self.sectionInfoArray = [[NSMutableArray alloc] initWithCapacity:[[self.resultsController fetchedObjects] count]];
        // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
		for (Blog *blog in [self.resultsController fetchedObjects]) {
            [self addSectionInfoForBlog:blog];
		}
	}
    
    if ([[self.resultsController fetchedObjects] count] > 0) {
        [self setupQuickPhotoButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated]; 

    [self presentContent];

    if (IS_IPHONE && _showingWelcomeScreen) {
        _showingWelcomeScreen = NO;
        static dispatch_once_t sidebarTeaseToken;
        dispatch_once(&sidebarTeaseToken, ^{
            [self.panelNavigationController teaseSidebar];
        });
    }
    if (!IS_IPAD) {
        // Called here to ensure the section is opened after launch on the iPad.
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self restorePreservedSelection];
        });
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (self.quickPhotoActionSheet) {
        // The quickphoto actionsheet is showing but its location is probably off
        // due to the rotation. Just represent it.
        [self quickPhotoButtonViewTapped:nil];
    }
}

- (void)didReceiveMemoryWarning {
    self.settingsButton = nil;
    self.utililtyView = nil;
    self.quickPhotoActionSheet = nil;
    
    [super didReceiveMemoryWarning];
}

#pragma mark - Custom methods

- (void)presentContent {
    [self showWelcomeScreenIfNeeded];
    if (!_selectionRestored) {
        [self restorePreservedSelection];
        _selectionRestored = YES;
    }
}

- (NSInteger)topSectionRowCount {
    if ([WPAccount defaultWordPressComAccount]) {
        // reader and notifications
        return 2;
    } else {
        return 0;
    }
}

#pragma mark - SectionInfo

- (SectionInfo *)sectionInfoForBlog:(Blog *)blog {
    SectionInfo *sectionInfo = [[SectionInfo alloc] init];			
    sectionInfo.blog = blog;
    sectionInfo.open = NO;

    NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
    }

    return sectionInfo;
}

- (void)addSectionInfoForBlog:(Blog *)blog {    
    [self.sectionInfoArray addObject:[self sectionInfoForBlog:blog]];
}

- (void)insertSectionInfoForBlog:(Blog *)blog atIndex:(NSUInteger)index {
    [self.sectionInfoArray insertObject:[self sectionInfoForBlog:blog] atIndex:index];
}

- (void)showWelcomeScreenIfNeeded {
    if ( [[self.resultsController fetchedObjects] count] == 0 ) {
        // No blogs added yet
        if (![WPAccount defaultWordPressComAccount]) {
            // No .com added blogs yet
            _showingWelcomeScreen = YES;
            GeneralWalkthroughViewController *welcomeViewController = [[GeneralWalkthroughViewController alloc] init];
            
            UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
            aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;

            [self.panelNavigationController.view.window makeKeyAndVisible];

            [self.panelNavigationController presentViewController:aNavigationController animated:YES completion:nil];
            [self checkNothingToShow];
        }
    }
}

- (void)checkNothingToShow {
    if ( [[self.resultsController fetchedObjects] count] == 0 && ![WPAccount defaultWordPressComAccount] ) {
        _utililtyView.hidden = YES;
        _settingsButton.hidden = YES;
        
        // No user logged in and no blogs.
        // The panelViewController needs to loose its detail view if it has one.
        [self.panelNavigationController clearDetailViewController];
    } else {
        _utililtyView.hidden = NO;
        _settingsButton.hidden = NO;
    }
}

- (void)selectFirstAvailableItem {
    if ([self.tableView indexPathForSelectedRow] != nil) {
        return;
    }

    if ([self.tableView numberOfRowsInSection:0] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self processRowSelectionAtIndexPath:indexPath];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentIndexPath = indexPath;
    } else {
        [self selectFirstAvailableBlog];
    }
    [self checkNothingToShow];
}

- (void)selectFirstAvailableBlog {
    if ([self.sectionInfoArray count] > 0) {
        [self selectBlogWithSection:1];
    }
}

- (void)selectBlogWithSection:(NSUInteger)index {
    SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:index - 1];
    if (!sectionInfo.open) {
        [sectionInfo.headerView toggleOpenWithUserAction:YES];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [self processRowSelectionAtIndexPath:indexPath closingSidebar:NO];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.currentIndexPath = indexPath;
}

- (void)selectBlog:(Blog *)blog {
    int currentBlog = 1;
    
    for (Blog *tempBlog in [[[self.resultsController sections] objectAtIndex:0] objects]) {
        if ([blog isEqual:tempBlog]) {
            [self selectBlogWithSection:currentBlog];
            break;
        }
        currentBlog++;
    }
}

- (void)showCommentWithId:(NSNumber *)itemId blogId:(NSNumber *)blogId {
    __block SectionInfo *targetSection;
    __block NSUInteger sectionNumber;
    [self.sectionInfoArray enumerateObjectsUsingBlock:^(SectionInfo *obj, NSUInteger idx, BOOL *stop) {
        if (([obj.blog isWPcom] && [obj.blog.blogID isEqualToNumber:blogId])
            ||
           ( [obj.blog getOptionValue:@"jetpack_client_id"] != nil && [[[obj.blog getOptionValue:@"jetpack_client_id"] numericValue]  isEqualToNumber:blogId] ) ) {
            targetSection = obj;
            sectionNumber = idx;
            *stop = YES;
        }
    }];
      
    if (targetSection) {
        if (!targetSection.open) {
            [targetSection.headerView toggleOpenWithUserAction:YES];
        }
        NSIndexPath *commentsPath = [NSIndexPath indexPathForRow:2 inSection:sectionNumber+1];
        [self processRowSelectionAtIndexPath:commentsPath];
        [self.tableView selectRowAtIndexPath:commentsPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        if ([self.panelNavigationController.detailViewController respondsToSelector:@selector(setWantedCommentId:)]) {
            [self.panelNavigationController.detailViewController performSelector:@selector(setWantedCommentId:) withObject:itemId];
        }
    }
}

- (IBAction)showSettings:(id)sender {
    [WPMobileStats incrementProperty:StatsPropertySidebarClickedSettings forEvent:StatsEventAppClosed];
    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    if (IS_IPAD) {
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.panelNavigationController presentViewController:aNavigationController animated:YES completion:nil];
}


- (void)restorePreservedSelection {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSelectedSidebarIndexDictionary];
    if (!dict) {
        return [self selectFirstAvailableItem];
    }

    NSIndexPath *preservedIndexPath = [NSIndexPath indexPathForRow:[[dict objectForKey:@"row"] integerValue] inSection:[[dict objectForKey:@"section"] integerValue]];

    NSInteger numRows = (preservedIndexPath.section == 0) ? self.topSectionRowCount : NUM_ROWS;

    if (preservedIndexPath.section >= [self numberOfSectionsInTableView:self.tableView] || preservedIndexPath.row >= numRows) {
        // preserved index path is not valid anymore
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedSidebarIndexDictionary];
        [self selectFirstAvailableItem];
        return;
    }
    
    if (preservedIndexPath.section == 0 && preservedIndexPath.row == 1) {
        [self processRowSelectionAtIndexPath:preservedIndexPath closingSidebar:NO];
        [self.tableView selectRowAtIndexPath:preservedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentIndexPath = preservedIndexPath;
    }
    else if (preservedIndexPath.section > 0 && ((preservedIndexPath.section - 1) < [self.resultsController.fetchedObjects count] )) {
        if ([self.sectionInfoArray count] > (preservedIndexPath.section - 1)) {
            SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:(preservedIndexPath.section -1)];
            if (!sectionInfo.open) {
                sectionInfo.open = YES;
                self.openSection = sectionInfo;
                [sectionInfo.headerView toggleOpenWithUserAction:YES];
            }
            
            [self processRowSelectionAtIndexPath:preservedIndexPath closingSidebar:NO];
            [self.tableView selectRowAtIndexPath:preservedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            self.currentIndexPath = preservedIndexPath;
        }
    } else {
        if (preservedIndexPath.row > 0) {
            [self.tableView selectRowAtIndexPath:preservedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self processRowSelectionAtIndexPath:preservedIndexPath];
            self.currentIndexPath = preservedIndexPath;
        } else {
            [self selectFirstAvailableItem];
        }
    }
}

- (void)selectNotificationsRow {
    if ([self tableView:self.tableView numberOfRowsInSection:0] < 2) {
        // No notifications available. We probably got a push notification after sign out
        return;
    }
    self.hasUnseenNotes = NO;
    NSIndexPath *notificationsIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    if (notificationsIndexPath) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:notificationsIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView selectRowAtIndexPath:notificationsIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentIndexPath = notificationsIndexPath;
    }
}

- (void)viewAdminForBlog:(Blog*)blog
{
    [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedViewAdmin forEvent:StatsEventAppClosed];
    NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl]];
}

#pragma mark - Quick Photo Methods

- (void)quickPhotoButtonViewTapped:(QuickPhotoButtonView *)sender {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];

    if (self.quickPhotoActionSheet) {
        // Dismiss the previous action sheet without invoking a button click.
        [self.quickPhotoActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
    }
    
    [self.panelNavigationController showSidebar];
    
	UIActionSheet *actionSheet = nil;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if ([[CameraPlusPickerManager sharedManager] cameraPlusPickerAvailable]) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                      delegate:self 
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                        destructiveButtonTitle:nil 
                                             otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),NSLocalizedString(@"Add Photo from Camera+", @""), NSLocalizedString(@"Take Photo with Camera+", @""),nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                      delegate:self 
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                        destructiveButtonTitle:nil 
                                             otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];            
        }
	} else {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary useCameraPlus:NO withImage:nil];
        return;
	}
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    if (IS_IPAD) {
        [actionSheet showFromRect:self.quickPhotoButton.frame inView:self.utililtyView animated:YES];
    } else {
        [actionSheet showInView:self.panelNavigationController.view];        
    }
    self.quickPhotoActionSheet = actionSheet;
}

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType {
    [self showQuickPhoto:sourceType useCameraPlus:NO withImage:nil];
}

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType useCameraPlus:(BOOL)useCameraPlus {
    if (useCameraPlus) {
        CameraPlusPickerManager *picker = [CameraPlusPickerManager sharedManager];
        picker.callbackURLProtocol = @"wordpress";
        picker.maxImages = 1;
        picker.imageSize = 4096;
        CameraPlusPickerMode mode = (sourceType == UIImagePickerControllerSourceTypeCamera) ? CameraPlusPickerModeShootOnly : CameraPlusPickerModeLightboxOnly;
        [picker openCameraPlusPickerWithMode:mode];
    } else {
        [self showQuickPhoto:sourceType useCameraPlus:useCameraPlus withImage:nil];
    }
}

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType useCameraPlus:(BOOL)useCameraPlus withImage:(UIImage *)image {
    [WPMobileStats incrementProperty:StatsPropertySidebarClickedQuickPhoto forEvent:StatsEventAppClosed];
    
    QuickPhotoViewController *quickPhotoViewController = [[QuickPhotoViewController alloc] init];
    quickPhotoViewController.sidebarViewController = self;
    quickPhotoViewController.photo = image;
    if (!image) {
        quickPhotoViewController.sourceType = sourceType;
    }
    quickPhotoViewController.isCameraPlus = useCameraPlus;

    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:quickPhotoViewController];
    if (IS_IPAD) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.panelNavigationController presentViewController:navController animated:YES completion:nil];
    } else {
        [self.panelNavigationController presentViewController:navController animated:YES completion:nil];
    }
}

- (void)uploadQuickPhoto:(Post *)post {
    if (post != nil) {
        self.currentQuickPost = post;
        [self.quickPhotoButton showProgress:YES animated:YES];
        
        if (IS_IPHONE) {
            [self selectBlog:post.blog];
        }
    }
}

- (void)postDidUploadSuccessfully:(NSNotification *)notification {
//    appDelegate.isUploadingPost = NO;
    self.currentQuickPost = nil;
    [self.quickPhotoButton showSuccess];
}

- (void)postUploadFailed:(NSNotification *)notification {
//    appDelegate.isUploadingPost = NO;
    self.currentQuickPost = nil;
    [self.quickPhotoButton showProgress:NO animated:YES];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                    message:NSLocalizedString(@"The photo could not be published. It's been saved as a local draft.", @"")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)postUploadCancelled:(NSNotification *)notification {
    self.currentQuickPost = nil;
    [self.quickPhotoButton showProgress:NO animated:YES];
}

- (void)setCurrentQuickPost:(Post *)currentQuickPost {
    if (currentQuickPost != _currentQuickPost) {
        if (_currentQuickPost) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PostUploaded" object:_currentQuickPost];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PostUploadFailed" object:_currentQuickPost];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PostUploadCancelled" object:_currentQuickPost];
        }
        _currentQuickPost = currentQuickPost;
        if (_currentQuickPost) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDidUploadSuccessfully:) name:@"PostUploaded" object:currentQuickPost];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUploadFailed:) name:@"PostUploadFailed" object:currentQuickPost];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUploadCancelled:) name:@"PostUploadCancelled" object:currentQuickPost];
        }
    }
}

- (void)setupQuickPhotoButton {    
    if (self.quickPhotoButton) return;
    
    CGFloat gapWidth = 2.0f;
    CGFloat availableWidth = self.view.frame.size.width;
    CGFloat buttonWidth = (availableWidth - gapWidth) / 2; // Remove gap size, divide by 2 for 2 buttons
    
    // Make room for the photo button
    CGRect settingsFrame = _settingsButton.frame;
    settingsFrame.size.width = buttonWidth;
    settingsFrame.origin.x = (buttonWidth + 3.0f); // Using 3f since the parent view doesn't have an expected even width
    _settingsButton.frame = settingsFrame;
    
    // Match the height and y of the settings Button.
    CGRect frame = CGRectMake(0.0f, settingsFrame.origin.y, buttonWidth, settingsFrame.size.height);
    QuickPhotoButtonView *quickPhotoView = [[QuickPhotoButtonView alloc] initWithFrame:frame];
    self.quickPhotoButton = quickPhotoView;
    self.quickPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.quickPhotoButton.delegate = self;
    
    [self.utililtyView addSubview:self.quickPhotoButton];
}

- (void)tearDownQuickPhotoButton {
    if (!self.quickPhotoButton) return;

    [self.quickPhotoButton removeFromSuperview];
    self.quickPhotoButton.delegate = nil;
    self.quickPhotoButton = nil;
    
    CGFloat availableWidth = self.view.frame.size.width;
    CGRect frame = self.settingsButton.frame;
    frame.origin.x = 0.0f;
    frame.size.width = availableWidth;
    self.settingsButton.frame = frame;
}

- (void)setupSettingsButton {
    self.settingsButton.backgroundColor = [UIColor clearColor];
    [self.settingsButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButton"] stretchableImageWithLeftCapWidth:14.0 topCapHeight:0.0] forState:UIControlStateNormal];
    [self.settingsButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButtonHighlighted"] stretchableImageWithLeftCapWidth:14.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    [self.settingsButton setTitle:NSLocalizedString(@"Settings", @"App settings") forState:UIControlStateNormal ];
    self.settingsButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    self.settingsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.settingsButton.titleLabel.minimumScaleFactor = 0.8;
    self.settingsButton.titleEdgeInsets = UIEdgeInsetsMake (0.0f, 12.0f, 0.0f, 10.0f);
    self.settingsButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f);
    self.settingsButton.titleLabel.shadowColor = [UIColor colorFromHex:0x000000 alpha:0.45f];
    self.settingsButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0f);
    [self.settingsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)handleCameraPlusImages:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    UIImage *image = [userInfo objectForKey:@"image"];
    // The source type isn't really important since we're also passing an image.
    [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary useCameraPlus:YES withImage:image];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.quickPhotoActionSheet = nil;
    if(buttonIndex == 0) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if(buttonIndex == 1) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeCamera];
    } else if(buttonIndex == 2) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary useCameraPlus:YES];
    } else if(buttonIndex == 3) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeCamera useCameraPlus:YES];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of blogs + the top section
    return [[self.resultsController fetchedObjects] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.topSectionRowCount;
    } else {
        SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section - 1];
        return sectionInfo.open ? NUM_ROWS : 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return 0.0f;
    else 
        return HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SIDEBAR_CELL_SECONDARY_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return nil;
    Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(section - 1) inSection:0]];
    SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section - 1];
    if (!sectionInfo.headerView) {
        sectionInfo.headerView = [[SidebarSectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, SIDEBAR_WIDTH, HEADER_HEIGHT) blog:blog sectionInfo:sectionInfo delegate:self];
        if (sectionInfo.open) {
            [sectionInfo.headerView toggleOpenWithUserAction:NO];
        }
    }

    return sectionInfo.headerView;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const CellIdentifier = @"SideBarCell";
    SidebarTableViewCell *cell = (SidebarTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SidebarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (indexPath.section == 0) {
        
        cell.textLabel.text = self.sidebarItems[0][indexPath.row][@"title"];
        cell.imageView.image = [UIImage imageNamed:self.sidebarItems[0][indexPath.row][@"icon"]];
        
        if (indexPath.row == 1) {
            // Override cell image for unseen notifications
            cell.imageView.image = [UIImage imageNamed:(self.hasUnseenNotes) ? @"sidebar_notifications_highlighted" : @"sidebar_notifications"];
        }
    } else {
        
        cell.textLabel.text = self.sidebarItems[1][indexPath.row][@"title"];
        cell.imageView.image = [UIImage imageNamed:self.sidebarItems[1][indexPath.row][@"icon"]];
        
        switch (indexPath.row) {
            case 0:
            case 1:
            {
                UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SIDEBAR_CELL_ACCESSORY_MAX_WIDTH, SIDEBAR_CELL_SECONDARY_HEIGHT)];
                [addButton setImage:[UIImage imageNamed:@"sidebar_icon_add"] forState:UIControlStateNormal];
                [addButton addTarget:self action:@selector(quickAddNewPost:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = addButton;
                
                break;
            }
            case 2:
            {
                Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.section - 1) inSection:0]];
                cell.blog = blog;
                break;
            }
            default:;
        }
    }
    
    return cell;
}


-(void)quickAddNewPost:(id)sender {
    NSAssert([sender isKindOfClass:[UIView class]], nil);

    UITableViewCell *cell = (UITableViewCell *)[(UIView *)sender superview];
    NSAssert([cell isKindOfClass:[UITableViewCell class]], nil);
    if (![cell isKindOfClass:[UITableViewCell class]]) {
        return;
    }

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    [self processRowSelectionAtIndexPath:indexPath];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.currentIndexPath = indexPath;
    if ([self.panelNavigationController.topViewController respondsToSelector:@selector(showAddPostView)]) {
        [self.panelNavigationController.topViewController performSelector:@selector(showAddPostView)];
    }
}

#pragma mark Section header delegate

-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionOpened:(SectionInfo *)sectionOpened {
	sectionOpened.open = YES;
    NSUInteger sectionNumber = [self.sectionInfoArray indexOfObject:sectionOpened] + 1;
    self.openSectionIdx = sectionNumber;
    
    // Create an array containing the index paths of the rows to insert
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionNumber]];
    }
    
    
    //Create an array containing the index paths of the rows to delete
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    
    SectionInfo *previousOpenSection = self.openSection;
    NSUInteger previousOpenSectionIndex = NSNotFound;
    [self.tableView beginUpdates];
    if (previousOpenSection && previousOpenSection != sectionOpened) {
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        previousOpenSectionIndex = [self.sectionInfoArray indexOfObject:previousOpenSection] + 1;
        for (NSInteger i = 0; i < NUM_ROWS; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
    
    // Apply the updates.
    if ([self.tableView numberOfRowsInSection:sectionNumber] == 0) {
        [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
    }
    if ([self.tableView numberOfRowsInSection:previousOpenSectionIndex] == NUM_ROWS) {
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    self.openSection = sectionOpened;
    // select the first row in the section
    // if we don't, a) you lose the current selection, b) the sidebar doesn't open on iPad
    [self.tableView selectRowAtIndexPath:[indexPathsToInsert objectAtIndex:0] animated:NO scrollPosition:UITableViewScrollPositionNone];    
    [self processRowSelectionAtIndexPath:[indexPathsToInsert objectAtIndex:0] closingSidebar:NO];
    
    // scroll to the section header view if it's not visible
    CGRect sectionRect = [self.tableView rectForSection:self.openSectionIdx];
    [self.tableView scrollRectToVisible:sectionRect animated:YES];
    
}

- (void)didReceiveUnseenNotesNotification {
    NSIndexPath *notificationsIndexPath = [NSIndexPath indexPathForRow: 1 inSection:0];
    if (notificationsIndexPath && [notificationsIndexPath compare:self.currentIndexPath] != NSOrderedSame) {
        self.hasUnseenNotes = YES;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:notificationsIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self processRowSelectionAtIndexPath:indexPath];
}

- (void)processRowSelectionAtIndexPath: (NSIndexPath *) indexPath {
    [self processRowSelectionAtIndexPath:indexPath closingSidebar:YES];
}

- (void)processRowSelectionAtIndexPath:(NSIndexPath *)indexPath closingSidebar:(BOOL)closingSidebar {
    WPFLog(@"%@ %@ %@", self, NSStringFromSelector(_cmd), indexPath);
    
    if (self.currentIndexPath) {
        if ([indexPath compare:self.currentIndexPath] == NSOrderedSame && !_changingContentForSelectedSection) {
            if (IS_IPAD) {
                [self.panelNavigationController showSidebar];
            } else if (closingSidebar) {
                [self.panelNavigationController closeSidebar];
            }
            return;
        }
    }

    
    UIViewController *detailViewController = nil;
    if (indexPath.section == 0) { // Reader & Notifications
        
        if (indexPath.row == 0) { // Reader
            [WPMobileStats incrementProperty:StatsPropertySidebarClickedReader forEvent:StatsEventAppClosed];
			ReaderPostsViewController *readerViewController = [[ReaderPostsViewController alloc] init];
            detailViewController = readerViewController;
			
        } else if(indexPath.row == 1) { // Notifications
            [WPMobileStats incrementProperty:StatsPropertySidebarClickedNotifications forEvent:StatsEventAppClosed];
            
            self.hasUnseenNotes = NO;
            NotificationsViewController *notificationsViewController = [[NotificationsViewController alloc] init];
            detailViewController = notificationsViewController;
        }
    } else {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.section - 1) inSection:0]];
        Class controllerClass = nil;
        //did user select the same item, but for a different blog? If so then just update the data in the view controller.
        switch (indexPath.row) {
            case 0:
                [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedPosts forEvent:StatsEventAppClosed];
                 controllerClass = [PostsViewController class];
                break;
            case 1:
                [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedPages forEvent:StatsEventAppClosed];
                controllerClass = [PagesViewController class];
                break;
            case 2:
                [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedComments forEvent:StatsEventAppClosed];
                controllerClass = [CommentsViewController class];
                break;
            case 3:
                [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedStats forEvent:StatsEventAppClosed];
                controllerClass =  [StatsWebViewController class];
                break;
            case 4 :
                [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedViewSite forEvent:StatsEventAppClosed];
                
                blogURL = blog.url;
                if (![blogURL hasPrefix:@"http"]) {
                    blogURL = [NSString stringWithFormat:@"http://%@", blogURL];
                } else if ([blog isWPcom] && [blog.url rangeOfString:@"wordpress.com"].location == NSNotFound) {
                    blogURL = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
                }
                
                //check if the same site already loaded
                if ([self.panelNavigationController.detailViewController isMemberOfClass:[WPWebViewController class]]
                    &&
                    [((WPWebViewController*)self.panelNavigationController.detailViewController).url.absoluteString isEqual:blogURL]
                    ) {
                    if (IS_IPAD) {
                        [self.panelNavigationController showSidebar];
                    } else {
                        [self.panelNavigationController popToRootViewControllerAnimated:NO];
                        [self.panelNavigationController closeSidebar];
                    }
                } else {
                    WPWebViewController *webViewController = [[WPWebViewController alloc] initWithBlog:blog];
                    [self.panelNavigationController setDetailViewController:webViewController closingSidebar:closingSidebar];
                }
                
                if (IS_IPAD) {
//                    [SoundUtil playSwipeSound];
                }
                return;

            case 5:
                [self viewAdminForBlog:blog];
                break;
            default:
                controllerClass = [PostsViewController class];
                break;    
        }
        
        if (IS_IPAD) {
//            [SoundUtil playSwipeSound];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kSelectedBlogChanged 
                                                            object:nil 
                                                          userInfo:[NSDictionary dictionaryWithObject:blog forKey:@"blog"]];
        
        //Check if the controller is already on the screen
        if ([self.panelNavigationController.detailViewController isMemberOfClass:controllerClass] && [self.panelNavigationController.detailViewController respondsToSelector:@selector(setBlog:)]) {
            [self.panelNavigationController.detailViewController performSelector:@selector(setBlog:) withObject:blog];
            if (IS_IPAD) {
                [self.panelNavigationController showSidebar];
            } else if (closingSidebar) {
                [self.panelNavigationController closeSidebar];
            }
            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            return;
        } else {
            detailViewController = (UIViewController *)[[controllerClass alloc] init];
            if ([detailViewController respondsToSelector:@selector(setBlog:)]) {
                [detailViewController performSelector:@selector(setBlog:) withObject:blog];
            }
        }
    }

    self.currentIndexPath = indexPath;
    NSDictionary *dict = @{@"row": @(indexPath.row), @"section":@(indexPath.section)};
    
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kSelectedSidebarIndexDictionary];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (detailViewController) {
        [self.panelNavigationController setDetailViewController:detailViewController closingSidebar:closingSidebar];
    }
}

#pragma mark - Accessor methods

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) return _resultsController;

    NSManagedObjectContext *moc = [[WordPressDataModel sharedDataModel] managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [fetchRequest setPropertiesToFetch:@[@"blogName", @"xmlrpc", @"url"]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:nil
                          cacheName:nil];
    _resultsController.delegate = self;


    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath) {
        _wantedSection = indexPath.section;
    } else {
        _wantedSection = 0;
    }
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    if (self.restoringView && self.currentIndexPath) {
        self.restoringView = NO;
        [[self tableView] selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        return;
    }
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath) {
        if (indexPath.section != _wantedSection || _changingContentForSelectedSection) {
            if (_wantedSection > 0) {
                NSUInteger sec = _wantedSection;
                if (_wantedSection > indexPath.section && indexPath.section > 0) {
                    sec = indexPath.section; // Prevents an out of index error that was being error trapped, thus hiding a crash.
                }
                [self selectBlogWithSection:sec];
            } else {
                [self selectFirstAvailableItem];
            }
            _changingContentForSelectedSection = NO;
        }
    } else {
        [self selectFirstAvailableItem];
    }
    if([[self.resultsController fetchedObjects] count] > 0){
        [self setupQuickPhotoButton];
    } else {
        [self tearDownQuickPhotoButton];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (NSFetchedResultsChangeUpdate == type && newIndexPath != nil) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            WPLog(@"Inserting row %d: %@", newIndexPath.row, anObject);
            NSIndexPath *openIndexPath = [self.tableView indexPathForSelectedRow];
            if (openIndexPath.section == (newIndexPath.row +1)) {
                // We're swapping the content for the currently selected section and need to update accordingly.
                _changingContentForSelectedSection = YES;
            }
            [self insertSectionInfoForBlog:anObject atIndex:newIndexPath.row];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:newIndexPath.row + 1] withRowAnimation:UITableViewRowAnimationFade];
            _wantedSection = newIndexPath.row + 1;
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            WPLog(@"Deleting row %d: %@", indexPath.row, anObject);
            NSIndexPath *openIndexPath = [self.tableView indexPathForSelectedRow];
            if (openIndexPath.section == (newIndexPath.row +1)) {
                // We're swapping the content for the currently selected section and need to update accordingly.
                _changingContentForSelectedSection = YES;
            }
            SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:indexPath.row];
            if (self.openSection == sectionInfo) {
                self.openSection = nil;
                _wantedSection = 0;
            }
            [self.sectionInfoArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.row + 1] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
    }
}

@end
