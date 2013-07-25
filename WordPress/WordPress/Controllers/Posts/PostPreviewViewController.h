#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@class EditPostViewController;

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate> {
    UIView *loadingView;

	NSMutableData *receivedData;
}

@property (nonatomic, weak) EditPostViewController *postDetailViewController;
@property (weak, readonly) UIWebView *webView;

- (id)initWithPost:(AbstractPost *)aPost;

- (void)refreshWebView;

@end
