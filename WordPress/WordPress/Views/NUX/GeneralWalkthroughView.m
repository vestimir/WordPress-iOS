//
//  GeneralWalkthroughView.m
//  WordPress
//
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXUtility.h"
#import "Constants.h"
#import "NSString+Util.h"

#define kBOTTOM_BAR 20.0
#define kINFO_BUTTON_X_OFFSET 0
#define kINFO_BUTTON_Y_OFFSET 0

CGFloat const GeneralWalkthroughIconVerticalOffset = 77;
CGFloat const GeneralWalkthroughStandardOffset = 16;
CGFloat const GeneralWalkthroughBottomBackgroundHeight = 64;
CGFloat const GeneralWalkthroughMaxTextWidth = 289.0;
CGFloat const GeneralWalkthroughSwipeToContinueTopOffset = 14.0;
CGFloat const GeneralWalkthroughTextFieldWidth = 289.0;
CGFloat const GeneralWalkthroughTextFieldHeight = 40.0;
CGFloat const GeneralWalkthroughSignInButtonWidth = 160.0;
CGFloat const GeneralWalkthroughSignInButtonHeight = 41.0;

@implementation GeneralWalkthroughView {
    //ViewController
    UIViewController *viewController;
    
    //Buttons
    WPNUXSecondaryButton *createAccountButton;
    WPNUXPrimaryButton *signInButton;
    UIButton *infoButton;
    WPNUXMainButton *bigSignInButton;
    
    //Views
    UIView *_mainTextureView;
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    UIView *bottomPanel;
    
    //Helpers
    float viewWidth, viewHeight;
    float heightFromSwipeToContinue;
    NSUInteger previousPageViewed;
    float skipToCreateAccountOriginalX;
    float skipToSignInOriginalX;
    float pageControlOriginalX;
    float bottomPanelOriginalX;
}

@synthesize usernameText = _usernameText;
@synthesize passwordText = _passwordText;
@synthesize siteUrlText = _siteUrlText;

- (id)initWithFrame:(CGRect)frame andViewController:(UIViewController *)controller {
    self = [super initWithFrame:frame];
    if (self) {
        viewController = controller;
        
        if (IS_IPAD) {
            viewWidth = 540;
            viewHeight = 620;    
        } else {
            viewWidth = CGRectGetWidth(frame);
            viewHeight = CGRectGetHeight(frame);
        }
        previousPageViewed = -1;
        
        self.backgroundColor = [WPNUXUtility backgroundColor];
        [self addScrollviewToFrame:frame];
        [self addBackgroundTexture];
        [self initializePage1];
        [self initializePage2];
        [self initializePage3];

    }
    return self;
}

#pragma mark - Private Mehtods

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page {
    return (x + viewWidth*(page-1));
}

- (void)addBackgroundTexture {
    _mainTextureView = [[UIView alloc] initWithFrame:self.bounds];
    _mainTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    [self addSubview:_mainTextureView];
    _mainTextureView.userInteractionEnabled = NO;
}

- (void)addScrollviewToFrame:(CGRect)frame {
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, CGRectGetWidth(frame), CGRectGetHeight(frame)-kBOTTOM_BAR)];
    }
    scrollView.pagingEnabled = YES;
    
    [self addSubview:scrollView];
    
    CGSize scrollViewSize = scrollView.contentSize;
    scrollViewSize.width = viewWidth * 3;
    scrollView.frame = self.bounds;
    scrollView.contentSize = scrollViewSize;
    scrollView.pagingEnabled = true;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = NO;
    [scrollView addGestureRecognizer:gestureRecognizer];
}

- (void)initializePage1 {
    CGFloat x,y;
    
    UIImage *infoButtonImage = [UIImage imageNamed:@"btn-about"];
    UIImage *infoButtonImageHighlighted = [UIImage imageNamed:@"btn-about-tap"];
    infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [infoButton setImage:infoButtonImage forState:UIControlStateNormal];
    [infoButton setImage:infoButtonImageHighlighted forState:UIControlStateHighlighted];
    infoButton.frame = CGRectMake(kINFO_BUTTON_X_OFFSET, kINFO_BUTTON_Y_OFFSET, infoButtonImage.size.width, infoButtonImage.size.height);
    
    UIImageView *wpIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-wp"]];
    [scrollView addSubview:wpIcon];
    x = (viewWidth - CGRectGetWidth(wpIcon.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = GeneralWalkthroughIconVerticalOffset;
    wpIcon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(wpIcon.frame), CGRectGetHeight(wpIcon.frame)));
    [scrollView addSubview:infoButton];
    
    UILabel *page1Title = [[UILabel alloc] init];
    page1Title.backgroundColor = [UIColor clearColor];
    page1Title.textAlignment = NSTextAlignmentCenter;
    page1Title.numberOfLines = 0;
    page1Title.lineBreakMode = NSLineBreakByWordWrapping;
    page1Title.font = [WPNUXUtility titleFont];
    page1Title.text = NSLocalizedString(@"Welcome to WordPress", @"NUX First Walkthrough Page 1 Title");
    page1Title.shadowColor = [WPNUXUtility textShadowColor];
    page1Title.shadowOffset = CGSizeMake(0.0, 1.0);
    page1Title.layer.shadowRadius = 2.0;
    page1Title.textColor = [UIColor whiteColor];
    CGSize titleSize = [page1Title.text sizeWithFont:page1Title.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(wpIcon.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    [scrollView addSubview:page1Title];
    
    UIImageView *page1TopSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(page1Title.frame) + GeneralWalkthroughStandardOffset;
    page1TopSeparator.frame = CGRectMake(x, y, viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    [scrollView addSubview:page1TopSeparator];
    
    UILabel *page1Description = [[UILabel alloc] init];
    page1Description.backgroundColor = [UIColor clearColor];
    page1Description.textAlignment = NSTextAlignmentCenter;
    page1Description.numberOfLines = 0;
    page1Description.lineBreakMode = NSLineBreakByWordWrapping;
    page1Description.font = [WPNUXUtility descriptionTextFont];
    page1Description.text = NSLocalizedString(@"Hold the web in the palm of your hand. Full publishing power in a pint-sized package.", @"NUX First Walkthrough Page 1 Description");
    page1Description.shadowColor = [WPNUXUtility textShadowColor];
    page1Description.shadowOffset = CGSizeMake(0.0, 1.0);
    page1Description.layer.shadowRadius = 2.0;
    page1Description.textColor = [WPNUXUtility descriptionTextColor];
    CGSize labelSize = [page1Description.text sizeWithFont:page1Description.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(page1TopSeparator.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    [scrollView addSubview:page1Description];
    
    UIImageView *page1BottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(page1Description.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page1BottomSeparator.frame = CGRectMake(x, y, viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    [scrollView addSubview:page1BottomSeparator];
    
    bottomPanel = [[UIView alloc] init];
    bottomPanel.backgroundColor = [WPNUXUtility bottomPanelBackgroundColor];
    x = 0;
    x = [self adjustX:x forPage:1];
    y = viewHeight - GeneralWalkthroughBottomBackgroundHeight;
    bottomPanel.frame = CGRectMake(x, y, viewWidth, GeneralWalkthroughBottomBackgroundHeight);
    [scrollView addSubview:bottomPanel];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBottomPanel:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [bottomPanel addGestureRecognizer:gestureRecognizer];
    
    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    bottomView.userInteractionEnabled = NO;
    bottomView.frame = bottomPanel.frame;
    [self addSubview:bottomView];
    
    UIView *bottomPanelLine = [[UIView alloc] init];
    bottomPanelLine.backgroundColor = [WPNUXUtility bottomPanelLineColor];
    x = 0;
    y = CGRectGetMinY(bottomPanel.frame);
    bottomPanelLine.frame = CGRectMake(x, y, viewWidth, 1);
    [scrollView addSubview:bottomPanelLine];
    
    // The page control adds a bunch of extra space for padding that messes with our calculations.
    pageControl = [[UIPageControl alloc] init];
    pageControl.numberOfPages = 3;
    [pageControl sizeToFit];
    [WPNUXUtility configurePageControlTintColors:pageControl];
    CGFloat verticalSpaceForPageControl = 15;
    CGSize pageControlSize = [pageControl sizeForNumberOfPages:3];
    x = (viewWidth - pageControlSize.width)/2.0;
    if (IS_IPAD) {
        // UIPageControl seems to add about half it's size in padding on the iPad
        // TODO : Figure out why this is happening
        x += pageControlSize.width/2.0;
    }
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(bottomPanel.frame) - GeneralWalkthroughStandardOffset - CGRectGetHeight(pageControl.frame) + verticalSpaceForPageControl;
    pageControl.frame = CGRectIntegral(CGRectMake(x, y, pageControlSize.width, pageControlSize.height));
    [self addSubview:pageControl];
    
    // Add "SWIPE TO CONTINUE" text
    UILabel *page1SwipeToContinue = [[UILabel alloc] init];
    [page1SwipeToContinue setTextColor:[WPNUXUtility swipeToContinueTextColor]];
    [page1SwipeToContinue setShadowColor:[WPNUXUtility textShadowColor]];
    page1SwipeToContinue.backgroundColor = [UIColor clearColor];
    page1SwipeToContinue.textAlignment = NSTextAlignmentCenter;
    page1SwipeToContinue.numberOfLines = 1;
    page1SwipeToContinue.font = [WPNUXUtility swipeToContinueFont];
    page1SwipeToContinue.text = [NSLocalizedString(@"swipe to continue", nil) uppercaseString];
    [page1SwipeToContinue sizeToFit];
    x = (viewWidth - CGRectGetWidth(page1SwipeToContinue.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(pageControl.frame) - GeneralWalkthroughSwipeToContinueTopOffset - CGRectGetHeight(page1SwipeToContinue.frame) + verticalSpaceForPageControl;
    page1SwipeToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(page1SwipeToContinue.frame), CGRectGetHeight(page1SwipeToContinue.frame)));
    [scrollView addSubview:page1SwipeToContinue];
    
    createAccountButton = [[WPNUXSecondaryButton alloc] init];
    [createAccountButton setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
    [createAccountButton sizeToFit];
    [createAccountButton addTarget:viewController action:@selector(clickedSkipToCreate:) forControlEvents:UIControlEventTouchUpInside];
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(bottomPanel.frame) + GeneralWalkthroughStandardOffset;
    createAccountButton.frame = CGRectMake(x, y, CGRectGetWidth(createAccountButton.frame), CGRectGetHeight(createAccountButton.frame));
    [self addSubview:createAccountButton];
    
    signInButton = [[WPNUXPrimaryButton alloc] init];
    [signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    [signInButton sizeToFit];
    [signInButton addTarget:self action:@selector(clickedSkipToSignIn:) forControlEvents:UIControlEventTouchUpInside];
    x = viewWidth - GeneralWalkthroughStandardOffset - CGRectGetWidth(signInButton.frame);
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(createAccountButton.frame);
    signInButton.frame = CGRectMake(x, y, CGRectGetWidth(signInButton.frame), CGRectGetHeight(signInButton.frame));
    [self addSubview:signInButton];
    
    heightFromSwipeToContinue = viewHeight - CGRectGetMinY(page1SwipeToContinue.frame) - CGRectGetHeight(page1SwipeToContinue.frame);
    NSArray *viewsToCenter = @[wpIcon, page1Title, page1TopSeparator, page1Description, page1BottomSeparator];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:wpIcon andEndingView:page1BottomSeparator forHeight:(viewHeight - heightFromSwipeToContinue)];
    
    skipToCreateAccountOriginalX = CGRectGetMinX(createAccountButton.frame);
    skipToSignInOriginalX = CGRectGetMinX(signInButton.frame);
    pageControlOriginalX = CGRectGetMinX(pageControl.frame);
    bottomPanelOriginalX = CGRectGetMinX(bottomPanel.frame);
}

- (void)initializePage2 {
    CGFloat x,y;
    
    // Add Icon
    UIImageView *page2Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-post"]];
    x = (viewWidth - CGRectGetWidth(page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = GeneralWalkthroughIconVerticalOffset ;
    page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(page2Icon.frame), CGRectGetHeight(page2Icon.frame)));
    [scrollView addSubview:page2Icon];
    
    // Add Title
    UILabel *page2Title = [[UILabel alloc] init];
    page2Title.backgroundColor = [UIColor clearColor];
    page2Title.textAlignment = NSTextAlignmentCenter;
    page2Title.numberOfLines = 0;
    page2Title.lineBreakMode = NSLineBreakByWordWrapping;
    page2Title.font = [WPNUXUtility titleFont];
    page2Title.text = NSLocalizedString(@"Publish whenever inspiration strikes", @"NUX First Walkthrough Page 2 Title");
    page2Title.shadowColor = [WPNUXUtility textShadowColor];
    page2Title.shadowOffset = CGSizeMake(0.0, 1.0);
    page2Title.layer.shadowRadius = 2.0;
    page2Title.textColor = [UIColor whiteColor];
    CGSize titleSize = [page2Title.text sizeWithFont:page2Title.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(page2Icon.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    [scrollView addSubview:page2Title];
    
    // Add Top Separator
    UIImageView *page2TopSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(page2Title.frame) + GeneralWalkthroughStandardOffset;
    page2TopSeparator.frame = CGRectMake(x, y, viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    [scrollView addSubview:page2TopSeparator];
    
    // Add Description
    UILabel *page2Description = [[UILabel alloc] init];
    page2Description.backgroundColor = [UIColor clearColor];
    page2Description.textAlignment = NSTextAlignmentCenter;
    page2Description.numberOfLines = 0;
    page2Description.lineBreakMode = NSLineBreakByWordWrapping;
    page2Description.font = [WPNUXUtility descriptionTextFont];
    page2Description.text = NSLocalizedString(@"Brilliant insight? Hilarious link? Perfect pic? Capture genius as it happens and post in real time.", @"NUX First Walkthrough Page 2 Description");
    page2Description.shadowColor = [WPNUXUtility textShadowColor];
    page2Description.shadowOffset = CGSizeMake(0.0, 1.0);
    page2Description.layer.shadowRadius = 2.0;
    page2Description.textColor = [WPNUXUtility descriptionTextColor];
    CGSize labelSize = [page2Description.text sizeWithFont:page2Description.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(page2TopSeparator.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    [scrollView addSubview:page2Description];
    
    // Add Bottom Separator
    UIImageView *page2BottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(page2Description.frame) + 0.5*GeneralWalkthroughStandardOffset;
    page2BottomSeparator.frame = CGRectMake(x, y, viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    
    NSArray *viewsToCenter = @[page2Icon, page2Title, page2TopSeparator, page2Description, page2BottomSeparator];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:page2Icon andEndingView:page2BottomSeparator forHeight:(viewHeight-heightFromSwipeToContinue)];
    [scrollView addSubview:page2BottomSeparator];
}

- (void)initializePage3 {
    CGFloat x,y;
    
    // Add Icon
    UIImageView *page3Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-wp"]];
    x = (viewWidth - CGRectGetWidth(page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = GeneralWalkthroughIconVerticalOffset;
    page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(page3Icon.frame), CGRectGetHeight(page3Icon.frame)));
    [scrollView addSubview:page3Icon];
    
    // Add Username
    self.usernameText = [[WPWalkthroughTextField alloc] init];
    self.usernameText.backgroundColor = [UIColor whiteColor];
    self.usernameText.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 3 Username Placeholder");
    self.usernameText.font = [WPNUXUtility textFieldFont];
    self.usernameText.adjustsFontSizeToFitWidth = true;
    self.usernameText.delegate = self;
    self.usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(page3Icon.frame) + GeneralWalkthroughStandardOffset;
    self.usernameText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));
    [scrollView addSubview:self.usernameText];
    
    // Add Password
    self.passwordText = [[WPWalkthroughTextField alloc] init];
    self.passwordText.backgroundColor = [UIColor whiteColor];
    self.passwordText.placeholder = NSLocalizedString(@"Password", nil);
    self.passwordText.font = [WPNUXUtility textFieldFont];
    self.passwordText.delegate = self;
    self.passwordText.secureTextEntry = YES;
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(self.usernameText.frame) + 0.5*GeneralWalkthroughStandardOffset;
    self.passwordText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));
    [scrollView addSubview:self.passwordText];
    
    // Add Site Url
    self.siteUrlText = [[WPWalkthroughTextField alloc] init];
    self.siteUrlText.backgroundColor = [UIColor whiteColor];
    self.siteUrlText.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 3 Site Address Placeholder");
    self.siteUrlText.font = [WPNUXUtility textFieldFont];
    self.siteUrlText.adjustsFontSizeToFitWidth = true;
    self.siteUrlText.delegate = self;
    self.siteUrlText.keyboardType = UIKeyboardTypeURL;
    self.siteUrlText.returnKeyType = UIReturnKeyGo;
    self.siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
    self.siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(self.passwordText.frame) + 0.5*GeneralWalkthroughStandardOffset;
    self.siteUrlText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));
    [scrollView addSubview:self.siteUrlText];
    
    // Add Sign In Button
    bigSignInButton = [[WPNUXMainButton alloc] init];
    [bigSignInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    [bigSignInButton addTarget:viewController action:@selector(clickedSignIn:) forControlEvents:UIControlEventTouchUpInside];
    bigSignInButton.enabled = NO;
    x = (viewWidth - GeneralWalkthroughSignInButtonWidth) / 2.0;;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(self.siteUrlText.frame) + GeneralWalkthroughStandardOffset;
    bigSignInButton.frame = CGRectMake(x, y, GeneralWalkthroughSignInButtonWidth, GeneralWalkthroughSignInButtonHeight);
    [scrollView addSubview:bigSignInButton];
    
    // Add Create Account Text
    UILabel *createAccountLabel = [[UILabel alloc] init];
    createAccountLabel.numberOfLines = 2;
    createAccountLabel.lineBreakMode = NSLineBreakByWordWrapping;
    createAccountLabel.textAlignment = NSTextAlignmentCenter;
    createAccountLabel.backgroundColor = [UIColor clearColor];
    createAccountLabel.textColor = [UIColor whiteColor];
    createAccountLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    createAccountLabel.text = NSLocalizedString(@"Don't have an account? Create one!", @"NUX First Walkthrough Page 3 Create Account Label");
    createAccountLabel.shadowColor = [UIColor blackColor];
    createAccountLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBottomPanel:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    createAccountLabel.userInteractionEnabled = YES;
    [createAccountLabel addGestureRecognizer:tapGestureRecognizer];
    CGSize createAccountLabelSize = [createAccountLabel.text sizeWithFont:createAccountLabel.font constrainedToSize:CGSizeMake(viewWidth - 2*GeneralWalkthroughStandardOffset, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (viewWidth - createAccountLabelSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = viewHeight - GeneralWalkthroughBottomBackgroundHeight + (GeneralWalkthroughBottomBackgroundHeight - createAccountLabelSize.height)/2.0;
    createAccountLabel.frame = CGRectIntegral(CGRectMake(x, y, createAccountLabelSize.width, createAccountLabelSize.height));
    [scrollView addSubview:createAccountLabel];
    
    NSArray *viewsToCenter = @[page3Icon, self.usernameText, self.passwordText, self.siteUrlText, bigSignInButton];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:page3Icon andEndingView:bigSignInButton forHeight:(viewHeight-heightFromSwipeToContinue)];

}

- (void)clickedBackground:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self endEditing:YES];
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    NSUInteger pageViewed = ceil(aScrollView.contentOffset.x/viewWidth) + 1;
    
    if (pageViewed != previousPageViewed) {
        [self flagPageViewed:pageViewed];
    }
    [self moveStickyControlsForContentOffset:aScrollView.contentOffset];
}

- (void)moveStickyControlsForContentOffset:(CGPoint)contentOffset {

    // We only want the sign in, create account and help buttons to drag along until we hit the sign in screen
    if (contentOffset.x > viewWidth) {
        // If the user is editing the sign in page and then swipes over, dismiss keyboard
        [self endEditing:YES];
        
        CGRect skipToCreateAccountFrame = createAccountButton.frame;
        skipToCreateAccountFrame.origin.x = skipToCreateAccountOriginalX - contentOffset.x + viewWidth;
        createAccountButton.frame = skipToCreateAccountFrame;
        
        CGRect skipToSignInFrame = signInButton.frame;
        skipToSignInFrame.origin.x = skipToSignInOriginalX - contentOffset.x + viewWidth;
        signInButton.frame = skipToSignInFrame;
        
        CGRect pageControlFrame = pageControl.frame;
        pageControlFrame.origin.x = pageControlOriginalX - contentOffset.x + viewWidth;
        pageControl.frame = pageControlFrame;
    }
    
    CGRect bottomPanelFrame = bottomPanel.frame;
    bottomPanelFrame.origin.x = bottomPanelOriginalX + contentOffset.x;
    bottomPanel.frame = bottomPanelFrame;
    
}

- (void)flagPageViewed:(NSUInteger)pageViewed {
    previousPageViewed = pageViewed;
    pageControl.currentPage = pageViewed - 1;
    // We do this so we don't keep flagging events if the user goes back and forth on pages
//    if (pageViewed == 2 && !_viewedPage2) {
//        _viewedPage2 = true;
//        [WPMobileStats x:StatsEventNUXFirstWalkthroughViewedPage2];
//    } else if (pageViewed == 3 && !_viewedPage3) {
//        _viewedPage3 = true;
//        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughViewedPage3];
//    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameText) {
        [self.passwordText becomeFirstResponder];
    } else if (textField == self.passwordText) {
        [self.siteUrlText becomeFirstResponder];
    } else if (textField == self.siteUrlText) {
        if (bigSignInButton.enabled) {
            if ([viewController respondsToSelector:@selector(clickedSignIn:)]) {
                [viewController performSelector:@selector(clickedSignIn:) withObject:nil];
            }
        }
    }
    
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    bigSignInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    bigSignInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == self.usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == self.passwordText) {
        isPasswordFilled = updatedStringHasContent;
    }
    bigSignInButton.enabled = isUsernameFilled && isPasswordFilled;
    
    return YES;
}

#pragma mark - Validators

- (BOOL)areFieldsValid
{
    if ([self areSelfHostedFieldsFilled]) {
        return [self isUrlValid];
    } else {
        return [self areDotComFieldsFilled];
    }
}

- (BOOL)isUsernameFilled {
    return [[self.usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled {
    return [[self.passwordText.text trim] length] != 0;
}

- (BOOL)areDotComFieldsFilled {
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)areSelfHostedFieldsFilled {
    return [self areDotComFieldsFilled] && [[self.siteUrlText.text trim] length] != 0;
}

- (BOOL)hasUserOnlyEnteredValuesForDotCom {
    return [self areDotComFieldsFilled] && ![self areSelfHostedFieldsFilled];
}

- (BOOL)areFieldsFilled {
    return [[self.usernameText.text trim] length] != 0 && [[self.passwordText.text trim] length] != 0 && [[self.siteUrlText.text trim] length] != 0;
}

- (BOOL)isUrlValid {
    NSURL *siteURL = [NSURL URLWithString:self.siteUrlText.text];
    return siteURL != nil;
}

#pragma mark - Button Selectors

- (void)clickedSkipToSignIn:(id)sender{
    NSLog(@"clickedSkipToSignIn");
    [UIView animateWithDuration:0.3 animations:^{
        scrollView.contentOffset = CGPointMake(viewWidth*2, 0);
    } completion:^(BOOL finished){
    }];
}

- (void)clickedBottomPanel:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"clickedBottomPanel");
    if (previousPageViewed == 3 && [viewController respondsToSelector:@selector(clickedCreateAccount:)]) {
        [viewController performSelector:@selector(clickedCreateAccount:) withObject:nil];
    }
}

@end
