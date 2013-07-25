//
//  SignInOperation.m
//  WordPress
//
//  Created by DX074 on 13-06-28.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPComSignInOperation.h"
#import "WordPressComApi.h"
#import <SFHFKeychainUtils.h>
#import "PushManager.h"
#import "UserAgent.h"
#import "WordPressComApi.h"

static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1/";
static NSString *const WordPressComApiOauthBaseUrl = @"https://public-api.wordpress.com/oauth2";
static NSString *const WordPressComApiOauthServiceName = @"public-api.wordpress.com";
static NSString *const WordPressComApiOauthRedirectUrl = @"http://wordpress.com/";
static NSString *const WordPressComApiNotificationFields = @"id,type,unread,body,subject,timestamp";
static NSString *const WordPressComApiUnseenNotesNotification = @"WordPressComUnseenNotes";
static NSString *const WordPressComApiNotesUserInfoKey = @"notes";
static NSString *const WordPressComApiUnseenNoteCountInfoKey = @"note_count";
static NSString *const WordPressComApiLoginUrl = @"https://wordpress.com/wp-login.php";

@interface WPComSignInOperation ()

@property (nonatomic, weak) id<NetworkRequestDelegate> owner;
@property (nonatomic) NSString *username, *password;

@end

@implementation WPComSignInOperation

- (id)initWithOwner:(id<NetworkRequestDelegate>)owner username:(NSString*)username password:(NSString*)password {
    self = [super initWithOwner:owner request:[[WordPressComApi sharedApi] signInWithUsername:username password:password]];
    if (self) {
        self.username = username;
        self.password = password;
    }
    return self;
}

- (void)requestComplete:(id)responseData {
    /*
     responseObject should look like:
     {
     "access_token": "YOUR_API_TOKEN",
     "blog_id": "blog id",
     "blog_url": "blog url",
     "token_type": "bearer"
     }
     */
    NSString *accessToken;
    
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
    
    if ([responseObject respondsToSelector:@selector(objectForKey:)]) {
        accessToken = [responseObject objectForKey:@"access_token"];
    }
    if (accessToken == nil) {
        //WPFLog(@"No access token found on OAuth response: %@", responseObject);
        //FIXME: this error message is crappy. Understand the posible reasons why responseObject is not what we expected and return a proper error
        NSString *localizedDescription = NSLocalizedString(@"Error authenticating", @"");
        NSError *error = [NSError errorWithDomain:WordPressComApiErrorDomain code:WordPressComApiErrorNoAccessToken userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
        [self requestFailed:error];
        return;
    }
//    self.authToken = accessToken;
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:self.username andPassword:self.password forServiceName:@"WordPress.com" updateExisting:YES error:&error];
    if (error) {
        [self requestFailed:error];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"wpcom_username_preference"];
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//            [WordPressAppDelegate sharedWordPressApplicationDelegate].isWPcomAuthenticated = YES;
        [PushManager registerForRemotePushNotifications];
        [[NSNotificationCenter defaultCenter] postNotificationName:WordPressComApiDidLoginNotification object:self.username];
    }
}

- (void)requestFailed:(NSError*)error {
    NSLog(@"Request failed with error %@", error);
}

@end
