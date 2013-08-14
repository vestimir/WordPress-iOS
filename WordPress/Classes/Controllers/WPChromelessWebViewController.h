//
//  WPChromelessWebViewController.h
//
//  Created by Eric Johnson on 5/24/12.
//

#import <UIKit/UIKit.h>
#import "WPWebView.h"

@interface WPChromelessWebViewController : UIViewController <WPWebViewDelegate>

@property (nonatomic, strong) NSString *path;
@property (nonatomic, weak, readonly) WPWebView *webView;

- (void)loadPath:(NSString *)aPath;
- (NSURL *)currentURL;

@end
