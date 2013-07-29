
#import "PanelNavigationController.h"

@class AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) PanelNavigationController *panelNavigationController;


+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

//- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
//- (void)showNotificationErrorAlert:(NSNotification *)notification;

@end
