//
//  WordPressComApi.h
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AFHTTPClient.h>
#import <Availability.h>

typedef void (^WordPressComApiRestSuccessResponseBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WordPressComApiRestSuccessFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef NS_ENUM(NSUInteger, WordPressComApiError) {
    WordPressComApiErrorJSON,
    WordPressComApiErrorNoAccessToken,
    WordPressComApiErrorLoginFailed,
    WordPressComApiErrorInvalidToken,
    WordPressComApiErrorAuthorizationRequired,
};

typedef NS_ENUM(NSUInteger, WordPressComApiBlogVisibility) {
    WordPressComApiBlogVisibilityPublic = 0,
    WordPressComApiComBlogVisibilityPrivate = 1,
    WordPressComApiBlogVisibilityHidden = 2,
};

extern NSString *const WordPressComApiErrorDomain;
extern NSString *const WordPressComApiErrorCodeKey;
extern NSString *const WordPressComApiErrorMessageKey;
extern NSString *const WordPressComApiOauthServiceName;

@interface WordPressComApi : AFHTTPClient

+ (WordPressComApi *)sharedApi;

- (void)removeCurrentAuthorization;

///-------------------------
/// @name Account management
///-------------------------

- (void)signInWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure;
- (void)validateWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)createWPComAccountWithEmail:(NSString *)email andUsername:(NSString *)username andPassword:(NSString *)password success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;
- (void)validateWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId success:(void (^)(id))success failure:(void (^)(NSError *))failure;
- (void)createWPComBlogWithUrl:(NSString *)blogUrl andBlogTitle:(NSString *)blogTitle andLanguageId:(NSNumber *)languageId andBlogVisibility:(WordPressComApiBlogVisibility)visibility success:(void (^)(id))success failure:(void (^)(NSError *))failure;


///--------------------
/// @name Notifications
///--------------------

// Register
// Unregister

- (void)saveNotificationSettingsForUsername:(NSString *)username
                                   password:(NSString*)password
                                deviceToken:(NSString*)token
                       notificationSettings:(NSDictionary*)notificationPreferences
                                    success:(void (^)())success
                                    failure:(void (^)(NSError *error))failure;

- (void)fetchNotificationSettingsWithUsername:(NSString*)username
                                     password:(NSString*)password
                                  deviceToken:(NSString*)token
                                      success:(void (^)(NSDictionary *notificationSettings))success
                                      failure:(void (^)(NSError *error))failure;

/*
 * Queries the REST Api for unread notes and determines if the user has
 * seen them using the response's last_seen_time timestamp.
 *
 * TODO Determine if user has seen them via last_seen_time via server.
 */

- (void)fetchUnseenNotificationsWithSuccess:(void(^)(NSArray *unseenNotes))success failure:(void (^)(NSError *error))failure;

- (void)checkNotificationsSuccess:(WordPressComApiRestSuccessResponseBlock)success
                          failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsBefore:(NSNumber *)timestamp
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsSince:(NSNumber *)timestamp
                      success:(WordPressComApiRestSuccessResponseBlock)success
                      failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)getNotificationsWithParameters:(NSDictionary *)parameters
                               success:(WordPressComApiRestSuccessResponseBlock)success
                               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)refreshNotifications:(NSArray *)notes
                      fields:(NSString *)fields
                     success:(WordPressComApiRestSuccessResponseBlock)success
                     failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)markNoteAsRead:(NSString *)noteID
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)updateNoteLastSeenTime:(NSNumber *)timestamp
                       success:(WordPressComApiRestSuccessResponseBlock)success
                       failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)followBlog:(NSUInteger)blogID isFollowing:(bool)following
           success:(WordPressComApiRestSuccessResponseBlock)success
           failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)moderateComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withStatus:(NSString *)commentStatus
                success:(WordPressComApiRestSuccessResponseBlock)success
                failure:(WordPressComApiRestSuccessFailureBlock)failure;

- (void)replyToComment:(NSUInteger)blogID forCommentID:(NSUInteger)commentID withReply:(NSString *)reply
               success:(WordPressComApiRestSuccessResponseBlock)success
               failure:(WordPressComApiRestSuccessFailureBlock)failure;

///-----------------
/// @name OAuth info
///-----------------

+ (NSString *)WordPressAppId;
+ (NSString *)WordPressAppSecret;


+ (void)setupSingleSignOn;

@end
