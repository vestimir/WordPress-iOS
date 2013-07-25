//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by DX074 on 13-06-27.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughViewController.h"
#import "GeneralWalkthroughView.h"
#import "CreateAccountAndBlogViewController.h"
#import "WPWalkthroughOverlayView.h"
#import "ReachabilityUtils.h"
#import "SVProgressHUD.h"
#import "WordPressApi.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "Blog.h"
#import "Blog+Jetpack.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "NewAddUsersBlogViewController.h"
#import "WPRestNetworkManager.h"
#import "HelpViewController.h"

@interface GeneralWalkthroughViewController () <NetworkRequestDelegate> {
    GeneralWalkthroughView *generalWalkthroughView;
    NSArray *_blogs;
    Blog *_blog;
    
    NSString *_dotComSiteUrl;
    BOOL _userIsDotCom;
    BOOL _blogConnectedToJetpack;
}

@end

@implementation GeneralWalkthroughViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    generalWalkthroughView = [[GeneralWalkthroughView alloc] initWithFrame:self.view.bounds andViewController:self];
    self.view = generalWalkthroughView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Press Methods

- (void)clickedSkipToCreate:(id)sender {
    //[WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount];
    [self showCreateAccountView];
}

- (void)clickedCreateAccount:(UITapGestureRecognizer *)tapGestureRecognizer {
    //[WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedCreateAccount];
    [self showCreateAccountView];
}

- (void)clickedSignIn:(id)sender {
    [self.view endEditing:YES];
    NSLog(@"signIn");
//    if (![ReachabilityUtils isInternetReachable]) {
//        [ReachabilityUtils showAlertNoInternetConnection];
//        return;
//    }
//
//    if (![generalWalkthroughView areFieldsValid]) {
//        [self displayErrorMessages];
//        return;
//    }

    [self signIn];
}

- (void)showCreateAccountView {
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    createAccountViewController.onCreatedUser = ^(NSString *username, NSString *password) {
        generalWalkthroughView.usernameText.text = username;
        generalWalkthroughView.passwordText.text = password;
        //BOOL userIsDotCom = true;
        [self.navigationController popViewControllerAnimated:NO];
        [self showAddUsersBlogsForWPCom];
    };
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)displayErrorMessages {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - View Controller Methods

- (void)signIn {
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = generalWalkthroughView.usernameText.text;
    NSString *password = generalWalkthroughView.passwordText.text;
    NSString *dotComSiteUrl = generalWalkthroughView.siteUrlText.text;
    _dotComSiteUrl = nil;
    
    if ([generalWalkthroughView hasUserOnlyEnteredValuesForDotCom] || [self isUrlWPCom:dotComSiteUrl]) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithoutUrl];
        
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }else{
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithUrl];
        
        void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
            WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];
            
            [api getBlogOptionsWithSuccess:^(id options){
                [SVProgressHUD dismiss];
                
                if ([options objectForKey:@"wordpress.com"] != nil) {
                    NSDictionary *siteUrl = [options dictionaryForKey:@"home_url"];
                    _dotComSiteUrl = [siteUrl objectForKey:@"value"];
                    [self signInForWPComForUsername:username andPassword:password];
                } else {
                    [self signInForSelfHostedForUsername:username password:password options:options andApi:api];
                }
            } failure:^(NSError *error){
                [SVProgressHUD dismiss];
                [self displayRemoteError:error];
            }];
        };
        
        void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
            [self handleGuessXMLRPCURLFailure:error];
        };
        
        [WordPressXMLRPCApi guessXMLRPCURLForSite:dotComSiteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
    }
}

- (void)signInForWPComForUsername:(NSString *)username andPassword:(NSString *)password
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForDotCom];

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to WordPress.com", nil) maskType:SVProgressHUDMaskTypeBlack];

    WPComSignInOperation *signInOp = [[WPComSignInOperation alloc] initWithOwner:self username:username password:password];
    [[WPRestNetworkManager sharedRestClient] enqueueHTTPRequestOperation:signInOp];
}

- (void)signInForSelfHostedForUsername:(NSString *)username password:(NSString *)password options:(NSDictionary *)options andApi:(WordPressXMLRPCApi *)api
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForSelfHosted];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    // TODO: Change this to an operation
    [api getBlogsWithSuccess:^(NSArray *blogs) {
        _blogs = blogs;
        [self handleGetBlogsSuccess:[api.xmlrpc absoluteString]];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    }];
}

#pragma mark - Error handler methods

- (void)displayRemoteError:(NSError *)error {
    NSString *message = [error localizedDescription];
    if ([error code] == 400) {
        message = NSLocalizedString(@"Please update your credentials and try again.", nil);
    }
    
    if ([[message trim] length] == 0) {
        message = NSLocalizedString(@"Sign in failed. Please try again.", nil);
    }
    
    if ([error code] == 405) {
        [self displayErrorMessageForXMLRPC:message];
    } else {
        if ([error code] == NSURLErrorBadURL) {
            [self displayErrorMessageForBadUrl:message];
        } else {
            [self displayGenericErrorMessage:message];
        }
    }
}

- (void)displayGenericErrorMessage:(NSString *)message {
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_description": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)handleGuessXMLRPCURLFailure:(NSError *)error
{
    [SVProgressHUD dismiss];
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        [self displayRemoteError:nil];
    //} else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
        //[self displayRemoteError:error];
    } else if([error.domain isEqual:AFNetworkingErrorDomain]) {
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", nil), [error localizedDescription]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  str, NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
        [self displayRemoteError:err];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil), NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
        [self displayRemoteError:err];
    }
}

- (void)displayErrorMessageForXMLRPC:(NSString *)message {
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.rightButtonText = NSLocalizedString(@"Enable Now", nil);
    overlayView.button1CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedEnableXMLRPCServices];
        
        [overlayView dismiss];
        
        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rng = [regex rangeOfFirstMatchInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (rng.location == NSNotFound) {
            path = [self getSiteUrl];
            path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
            path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
        } else {
            path = [message substringWithRange:rng];
        }
        
        //        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        //        [webViewController setUrl:[NSURL URLWithString:path]];
        //        [webViewController setUsername:_usernameText.text];
        //        [webViewController setPassword:_passwordText.text];
        //        webViewController.shouldScrollToBottom = YES;
        //        [self.navigationController setNavigationBarHidden:NO animated:NO];
        //        [self.navigationController pushViewController:webViewController animated:NO];
    };
    [self.view addSubview:overlayView];
}

- (void)displayErrorMessageForBadUrl:(NSString *)message {
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        //        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        //        webViewController.url = [NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"];
        //        [self.navigationController setNavigationBarHidden:NO animated:NO];
        //        [self.navigationController pushViewController:webViewController animated:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)handleGetBlogsSuccess:(NSString *)xmlRPCUrl {
    if ([_blogs count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install,
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([_blogs count] > 1) {
            subsite = [[_blogs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlRPCUrl]] lastObject];
        }
        
        if (subsite == nil) {
            subsite = [_blogs objectAtIndex:0];
        }
        
        if ([_blogs count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            [SVProgressHUD dismiss];
            [self showAddUsersBlogsForSelfHosted:xmlRPCUrl];
        } else {
            [self createBlogWithXmlRpc:xmlRPCUrl andBlogDetails:subsite];
            [self synchronizeNewlyAddedBlog];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", nil)}];
        [self displayRemoteError:error];
    }
}


- (BOOL)isUrlWPCom:(NSString *)url {
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:0 range:NSMakeRange(0, [[url trim] length])];
    
    return [result count] != 0;
}

- (NewAddUsersBlogViewController *)addUsersBlogViewController
{
    NewAddUsersBlogViewController *vc = [[NewAddUsersBlogViewController alloc] init];
    vc.username = generalWalkthroughView.usernameText.text;
    vc.password = generalWalkthroughView.passwordText.text;

    vc.blogAdditionCompleted = ^(NewAddUsersBlogViewController * viewController){
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onNoBlogsLoaded = ^(NewAddUsersBlogViewController *viewController) {
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onErrorLoading = ^(NewAddUsersBlogViewController *viewController, NSError *error) {
        WPFLog(@"There was an error loading blogs after sign in");
        [self.navigationController popViewControllerAnimated:YES];
        [self displayGenericErrorMessage:[error localizedDescription]];
    };
    
    return vc;
}

- (void)showAddUsersBlogsForWPCom {
    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController];
    
    NSString *siteUrl = [generalWalkthroughView.siteUrlText.text trim];
    if ([siteUrl length] != 0) {
        vc.siteUrl = siteUrl;
    } else if ([_dotComSiteUrl length] != 0) {
        vc.siteUrl = _dotComSiteUrl;
    }
    
    vc.isWPCom = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAddUsersBlogsForSelfHosted:(NSString *)xmlRPCUrl
{
//    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController];
//    vc.isWPCom = NO;
//    vc.xmlRPCUrl = xmlRPCUrl;
//    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlRPCUrl andBlogDetails:(NSDictionary *)blogDetails
{
    NSParameterAssert(blogDetails != nil);
    
    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlRPCUrl username:generalWalkthroughView.usernameText.text andPassword:generalWalkthroughView.passwordText.text];
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:xmlRPCUrl forKey:@"xmlrpc"];
    
    _blog = [account findOrCreateBlogFromDictionary:newBlog];
    [_blog dataSave];
    
}

- (void)synchronizeNewlyAddedBlog {
    [SVProgressHUD setStatus:NSLocalizedString(@"Synchronizing Blog", nil)];
    void (^successBlock)() = ^{
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
        [SVProgressHUD dismiss];
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack];
        if ([_blog hasJetpack]) {
            [self showJetpackAuthentication];
        } else {
            [self showCompletionWalkthrough];
        }
    };
    void (^failureBlock)(NSError*) = ^(NSError * error) {
        [SVProgressHUD dismiss];
    };
    [_blog syncBlogWithSuccess:successBlock failure:failureBlock];
}

- (NSString *)getSiteUrl {
    NSURL *siteURL = [NSURL URLWithString:generalWalkthroughView.siteUrlText.text];
    NSString *url = [siteURL absoluteString];
    
    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if ([self isUrlWPCom:url]) {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"https://%@", url];
        } else {
            if ([url rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [url length])];
            }
        }
    } else {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
    }
    
    NSRegularExpression *wplogin = [NSRegularExpression regularExpressionWithPattern:@"/wp-login.php$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *wpadmin = [NSRegularExpression regularExpressionWithPattern:@"/wp-admin/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *trailingslash = [NSRegularExpression regularExpressionWithPattern:@"/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    url = [wplogin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [wpadmin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [trailingslash stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    
    return url;
}


- (void)showHelpViewController:(BOOL)animated {
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    helpViewController.isBlogSetup = YES;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:helpViewController animated:animated];
}

- (WPWalkthroughOverlayView *)baseLoginErrorOverlayView:(NSString *)message {
    WPWalkthroughOverlayView *overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode;
    overlayView.overlayTitle = NSLocalizedString(@"Sorry, we can't log you in.", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    overlayView.leftButtonText = NSLocalizedString(@"Need Help?", nil);
    overlayView.rightButtonText = NSLocalizedString(@"OK", nil);
    overlayView.singleTapCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    return overlayView;
}

- (void)showJetpackAuthentication
{
    [SVProgressHUD dismiss];
//    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:_blog];
//    jetpackSettingsViewController.canBeSkipped = YES;
//    [jetpackSettingsViewController setCompletionBlock:^(BOOL didAuthenticate) {
//        _blogConnectedToJetpack = didAuthenticate;
//        
//        if (_blogConnectedToJetpack) {
//            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserConnectedToJetpack];
//        } else {
//            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSkippedConnectingToJetpack];
//        }
//        
//        [self.navigationController popViewControllerAnimated:NO];
//        [self showCompletionWalkthrough];
//    }];
//    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}

- (void)showCompletionWalkthrough {
    LoginCompletedWalkthroughViewController *loginCompletedViewController = [[LoginCompletedWalkthroughViewController alloc] init];
    loginCompletedViewController.showsExtraWalkthroughPages = _userIsDotCom || _blogConnectedToJetpack;
    [self.navigationController pushViewController:loginCompletedViewController animated:YES];
}

#pragma mark NetworkRequestDelegate

- (void)loginCompleted {
    _userIsDotCom = true;
    [self showAddUsersBlogsForWPCom];
}

- (void)networkRequestComplete:(NSOperation*)operation {
    [SVProgressHUD dismiss];
    
    if ([operation isKindOfClass:[WPComSignInOperation class]]) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForDotCom];
        
        [self loginCompleted];
    }
}

- (void)networkRequestFailed:(NSError *)error {
    [SVProgressHUD dismiss];
    [self displayRemoteError:error];
}

@end
