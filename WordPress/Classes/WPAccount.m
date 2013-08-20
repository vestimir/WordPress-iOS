/*
 * WPAccount.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPAccount.h"
#import "Blog.h"
#import "Note.h"
#import "NSString+XMLExtensions.h"
#import "WordPressDataModel.h"
#import "NotificationsManager.h"
#import "WordPressComApi.h"

#import <SFHFKeychainUtils/SFHFKeychainUtils.h>

NSString *const WordPressComApiDidLoginNotification = @"WordPressComApiDidLogin";
NSString *const WordPressComApiDidLogoutNotification = @"WordPressComApiDidLogout";

static NSString * const DefaultDotcomAccountDefaultsKey = @"AccountDefaultDotcom";
static NSString * const DotcomXmlrpcKey = @"https://wordpress.com/xmlrpc.php";
static WPAccount *__defaultDotcomAccount = nil;
NSString * const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";

@interface WPAccount ()
@property (nonatomic, retain) NSString *xmlrpc;
@property (nonatomic, retain) NSString *username;
@property (nonatomic) BOOL isWpcom;
@end

@implementation WPAccount

@dynamic xmlrpc;
@dynamic username;
@dynamic isWpcom;
@dynamic blogs;
@dynamic jetpackBlogs;
@synthesize isWpComAuthenticated;

#pragma mark - Default WordPress.com account

+ (WPAccount *)defaultWordPressComAccount {
    if (__defaultDotcomAccount) {
        return __defaultDotcomAccount;
    }
    NSManagedObjectContext *context = [[WordPressDataModel sharedDataModel] managedObjectContext];

    NSURL *accountURL = [[NSUserDefaults standardUserDefaults] URLForKey:DefaultDotcomAccountDefaultsKey];
    if (!accountURL) {
        return nil;
    }
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:accountURL];
    if (!objectID) {
        return nil;
    }

    WPAccount *account = (WPAccount *)[context existingObjectWithID:objectID error:nil];
    if (account) {
        __defaultDotcomAccount = account;
    } else {
        // The stored Account reference is invalid, so let's remove it to avoid wasting time querying for it
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    }

    return __defaultDotcomAccount;
}

+ (void)setDefaultWordPressComAccount:(WPAccount *)account {
    NSAssert(account.isWpcom, @"account should be a wordpress.com account");
    __defaultDotcomAccount = account;
    // When the account object hasn't been saved yet, its objectID is temporary
    // If we store a reference to that objectID it will be invalid the next time we launch
    if ([[account objectID] isTemporaryID]) {
        [account.managedObjectContext obtainPermanentIDsForObjects:@[account] error:nil];
    }
    NSURL *accountURL = [[account objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:accountURL forKey:DefaultDotcomAccountDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:account];
}

+ (void)removeDefaultWordPressComAccount {    
    [SFHFKeychainUtils deleteItemForUsername:__defaultDotcomAccount.username andServiceName:WordPressComApiOauthServiceName error:nil];
    [SFHFKeychainUtils deleteItemForUsername:__defaultDotcomAccount.username andServiceName:__defaultDotcomAccount.xmlrpc error:nil];
    
    [[WordPressComApi sharedApi] cancelAllHTTPOperationsWithMethod:nil path:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    __defaultDotcomAccount = nil;
    
    // TODO: Form a relationship for Account and Note so Notes are deleted when the account is deleted
    // - Posts/Pages/etc already have this
    // Remove all notifications
    [Note removeAllNotesWithContext:[[WordPressDataModel sharedDataModel] managedObjectContext]];
    
    // Remove the token from Preferences, otherwise the token is never sent to the server on the next login
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
    [NotificationsManager unregisterForRemotePushNotifications];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountDefaultsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_blogs"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_user_id"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_prefered_blog_id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Remove authorization header and cookies for the current instance of the API
    [[WordPressComApi sharedApi] removeCurrentAuthorization];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
}

- (void)prepareForDeletion {
    // Invoked automatically by the Core Data framework when the receiver is about to be deleted.
    if (__defaultDotcomAccount == self) {
        [WPAccount removeDefaultWordPressComAccount];
    }
}

#pragma mark - Account creation

+ (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username andPassword:(NSString *)password {
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:DotcomXmlrpcKey username:username andPassword:password];
    account.isWpcom = YES;
    if (__defaultDotcomAccount == nil) {
        [self setDefaultWordPressComAccount:account];
    }
    return account;
}

+ (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc username:(NSString *)username andPassword:(NSString *)password {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@ AND username like %@", xmlrpc, username]];
    [request setIncludesPendingChanges:YES];
    NSManagedObjectContext *context = [[WordPressDataModel sharedDataModel] managedObjectContext];
    NSArray *results = [context executeFetchRequest:request error:nil];
    WPAccount *account = nil;
    if ([results count] > 0) {
        account = [results objectAtIndex:0];
    } else {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
        account.xmlrpc = xmlrpc;
        account.username = username;
    }
    account.password = password;
    return account;
}

#pragma mark - Blog creation

- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo {
    NSString *blogUrl = [self stripBlogUrl:blogInfo[@"url"]];
    NSSet *foundBlogs = [self.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"displayURL like %@", blogUrl]];
    if ([foundBlogs count]) {
        return [foundBlogs anyObject];
    }
    
    Blog *blog = [Blog createFromDictionary:blogInfo inContext:self.managedObjectContext];
    blog.account = self;
    return blog;
}

- (NSString*)stripBlogUrl:(NSString*)originalUrl {
    NSString *blogUrl = [originalUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blogUrl hasSuffix:@"/"]) {
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
	}
    return [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - Custom accessors

- (NSString *)password {
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:self.xmlrpc error:nil];
}

- (void)setPassword:(NSString *)password {
    if (password) {
        [SFHFKeychainUtils storeUsername:self.username
                             andPassword:password
                          forServiceName:self.xmlrpc
                          updateExisting:YES
                                   error:nil];
    }
}

- (NSString *)authToken {
    return [SFHFKeychainUtils getPasswordForUsername:self.username andServiceName:WordPressComApiOauthServiceName error:nil];
}

- (void)setAuthToken:(NSString *)authToken {
    [SFHFKeychainUtils storeUsername:self.username
                         andPassword:authToken
                      forServiceName:WordPressComApiOauthServiceName
                      updateExisting:YES
                               error:nil];
}

@end

@implementation WPAccount (WordPressComApi)

+ (void)signInWithUsername:(NSString *)username password:(NSString *)password
                   success:(void (^)())success failure:(void (^)(NSError *))failure {
    [[WordPressComApi sharedApi] signInWithUsername:username password:password success:^(NSString *token){
        if (token == nil) {
            NSString *localizedDescription = NSLocalizedString(@"Error authenticating", @"");
            NSError *error = [NSError errorWithDomain:WordPressComApiErrorDomain code:WordPressComApiErrorNoAccessToken userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
            if (failure) failure(error);
            return;
        }
        
        WPAccount *account = [self createOrUpdateWordPressComAccountWithUsername:username andPassword:password];
        account.authToken = token;
        
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:@"WordPress.com" updateExisting:YES error:&error];
        [SFHFKeychainUtils storeUsername:username andPassword:token forServiceName:WordPressComApiOauthServiceName updateExisting:YES error:&error];
        if (error) {
            if (failure) failure(error);
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"wpcom_username_preference"];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            account.isWpComAuthenticated = YES;
            [NotificationsManager registerForRemotePushNotifications];
            [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:username];
            if (success) success();
        }
    } failure:failure];
}

// TODO Do we need this? Only called from one place
- (void)refreshTokenWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[WordPressComApi sharedApi] signInWithUsername:self.username password:self.password success:^(NSString *token) {
        self.authToken = token;
        self.isWpComAuthenticated = YES;
        [SFHFKeychainUtils storeUsername:self.username andPassword:self.password forServiceName:@"WordPress.com" updateExisting:YES error:nil];
        [SFHFKeychainUtils storeUsername:self.username andPassword:token forServiceName:WordPressComApiOauthServiceName updateExisting:YES error:nil];
        if (success) success();
    } failure:^(NSError *error) {
        self.isWpComAuthenticated = NO;
        self.authToken = nil;
        if (failure) failure(error);
    }];
}

@end
