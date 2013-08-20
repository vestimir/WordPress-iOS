//
//  BlogSelectorViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlogSelectorViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogsTableViewCell.h"
#import "UIImageView+Gravatar.h"
#import "NSString+XMLExtensions.h" 
#import "WordPressDataModel.h"

@interface BlogSelectorViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation BlogSelectorViewController

- (void)didReceiveMemoryWarning
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    NSError *error = nil;
    [[self resultsController] performFetch:&error];
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BlogCell";
    BlogsTableViewCell *cell = (BlogsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    
    CGRect frame = CGRectMake(8,8,35,35);
    UIImageView* asyncImage = [[UIImageView alloc]
                                            initWithFrame:frame];
    
    if (cell == nil) {
        cell = [[BlogsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell.imageView removeFromSuperview];
    }
    else {
        UIImageView* oldImage = (UIImageView*)[cell.contentView viewWithTag:999];
        [oldImage removeFromSuperview];
    }
    
	asyncImage.tag = 999;
	[asyncImage setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
	[cell.contentView addSubview:asyncImage];
	
    cell.textLabel.text = [blog blogName];
    cell.detailTextLabel.text = [blog displayURL];
    
    if ([blog isEqual:self.selectedBlog]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    self.selectedBlog = blog;
    [self.delegate blogSelectorViewController:self didSelectBlog:blog];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

#pragma mark - Fetched results controller delegate

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) {
        return _resultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
                                        inManagedObjectContext:[WordPressDataModel sharedDataModel].managedObjectContext]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                              initWithFetchRequest:fetchRequest
                              managedObjectContext:[WordPressDataModel sharedDataModel].managedObjectContext
                              sectionNameKeyPath:nil
                              cacheName:nil];
    _resultsController.delegate = self;
    
    sortDescriptor = nil;
    sortDescriptors = nil;
    
    return _resultsController;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
}

@end
