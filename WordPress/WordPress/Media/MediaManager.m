#import "MediaManager.h"
#import "FileLogger.h"
#import "WordPressDataModel.h"
#import "Media.h"

@interface MediaManager ()

@end

@implementation MediaManager

+ (instancetype)sharedInstance {
    static MediaManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MediaManager alloc] init];
    });
    return instance;
}

+ (void)cleanUnusedFiles {
    // Clean media files asynchronously
    // dispatch_async feels a bit faster than performSelectorOnBackground:
    // and we're trying to launch the app as fast as possible
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [[MediaManager sharedInstance] performCleanUnusedFiles];
    });
}

- (void)performCleanUnusedFiles {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSMutableArray *mediaToKeep = [NSMutableArray array];

    NSError *error = nil;
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:[WordPressDataModel sharedDataModel].persistentStoreCoordinator];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL AND remoteStatusNumber <> %@", @(MediaRemoteStatusSync)];
    [fetchRequest setPredicate:predicate];
    NSArray *mediaObjectsToKeep = [context executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        WPFLog(@"Error cleaning up tmp files: %@", [error localizedDescription]);
    }
    //get a references to media files linked in a post
    NSLog(@"%i media items to check for cleanup", [mediaObjectsToKeep count]);
    for (Media *media in mediaObjectsToKeep) {
        [mediaToKeep addObject:media.localURL];
    }

    //searches for jpg files within the app temp file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contentsOfDir = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];

    NSError *regexpError = NULL;
    NSRegularExpression *jpeg = [NSRegularExpression regularExpressionWithPattern:@".jpg$" options:NSRegularExpressionCaseInsensitive error:&regexpError];

    for (NSString *currentPath in contentsOfDir) {
        if([jpeg numberOfMatchesInString:currentPath options:0 range:NSMakeRange(0, [currentPath length])] > 0) {
            NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];
            
            BOOL keep = NO;
            //if the file is not referenced in any post we can delete it
            for (NSString *currentMediaToKeepPath in mediaToKeep) {
                if([currentMediaToKeepPath isEqualToString:filepath]) {
                    keep = YES;
                    break;
                }
            }
            
            if(keep == NO) {
                [fileManager removeItemAtPath:filepath error:NULL];
            }
        }
    }
}

+ (void)setWordPressDirectory {
    // Set current directory for WordPress app
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];

	BOOL isDir;
	if (![fileManager fileExistsAtPath:currentDirectoryPath isDirectory:&isDir] || !isDir) {
		[fileManager createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	}

	[fileManager changeCurrentDirectoryPath:currentDirectoryPath];
}

@end
