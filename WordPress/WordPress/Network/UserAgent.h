/*
 * Manages the user agent
 */

@interface UserAgent : NSObject

+ (void)setupAppUserAgent;
+ (void)useDefaultUserAgent;
+ (void)useAppUserAgent;
+ (NSString*)appUserAgent;
+ (NSString*)defaultUserAgent;

@end
