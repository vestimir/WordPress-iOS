#import <Foundation/Foundation.h>

@interface WordPressDataModel : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (WordPressDataModel*)sharedDataModel;
+ (void)initializeCoreData;

- (void)saveContext;

@end
