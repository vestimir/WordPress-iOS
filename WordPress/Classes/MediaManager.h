#import <Foundation/Foundation.h>

@interface MediaManager : NSObject

+ (MediaManager*)sharedInstance;

+ (void)cleanUnusedFiles;
+ (void)setWordPressDirectory;

@end
