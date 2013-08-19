//
//  CommentsViewControllers.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import "WPTableViewController.h"
#import "Blog.h"
#import "ReplyToCommentViewController.h"
#import "PanelNavigationController.h"

@protocol CommentsTableViewDelegate<UITableViewDelegate>
- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@class CommentViewController;

@interface CommentsViewController : WPTableViewController <ReplyToCommentViewControllerDelegate, UIAccelerometerDelegate, CommentsTableViewDelegate, DetailViewDelegate>

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;
- (IBAction)replyToSelectedComment:(id)sender;

#pragma mark -
#pragma mark Comment navigation

- (BOOL)hasPreviousComment;
- (BOOL)hasNextComment;
- (void)showPreviousComment;
- (void)showNextComment;

@end
