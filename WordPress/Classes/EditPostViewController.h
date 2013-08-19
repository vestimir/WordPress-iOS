#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EditorKeyboardToolbar.h"
#import "PostPreviewViewController.h"
#import "PostMediaViewController.h"

@class PostSettingsViewController;

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)

extern NSString *const EditPostViewControllerDidAutosaveNotification;
extern NSString *const EditPostViewControllerAutosaveDidFailNotification;

@class AbstractPost;

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
	EditPostViewControllerModeNewPost,
	EditPostViewControllerModeEditPost
};

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, UIPopoverControllerDelegate,EditorKeyboardToolbarDelegate>

@property(nonatomic, strong) NSString *statsPrefix;
@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, strong) PostMediaViewController *postMediaViewController;
@property (nonatomic, strong) PostPreviewViewController *postPreviewViewController;
@property (nonatomic, assign) EditPostViewControllerMode editMode;
@property (nonatomic, strong) AbstractPost *apost;
@property (readonly) BOOL hasChanges;

@property (nonatomic, strong) IBOutlet UIButton *hasLocation;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *photoButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *movieButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *settingsButton;

- (id)initWithPost:(AbstractPost *)aPost;
- (BOOL)autosaveRemoteWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)refreshButtons;
- (IBAction)switchToEdit;
- (IBAction)switchToSettings;
- (IBAction)switchToMedia;
- (IBAction)switchToPreview;
- (CGRect)normalTextFrame;

@end