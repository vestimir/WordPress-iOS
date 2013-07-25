#import "UpdateChecker.h"
#import "NSString+Helpers.h"
#import "UIDevice+WordPressIdentifier.h"
#import "Blog.h"
#import "WordPressDataModel.h"
#import <UIDeviceIdentifier/UIDeviceHardware.h>

static NSString *const STATS_LAST_UPDATED_DATE = @"statsDate";

@implementation UpdateChecker

+ (void)checkForUpdateAndSendDeviceStats {
    if (NO) { // Switch this to YES to debug stats/update check
        [UpdateChecker sendDeviceInfoAndCheckForUpgrade];
        return;
    }
	//check if statsDate exists in user defaults, if not, add it and run stats since this is obviously the first time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//[defaults setObject:nil forKey:STATS_LAST_UPDATED_DATE];  // Uncomment this line to force stats.
	if (![defaults objectForKey:STATS_LAST_UPDATED_DATE]){
		NSDate *theDate = [NSDate date];
		[defaults setObject:theDate forKey:STATS_LAST_UPDATED_DATE];
		[UpdateChecker sendDeviceInfoAndCheckForUpgrade];
	} else {
		//if statsDate existed, check if it's 7 days since last stats run, if it is > 7 days, run stats
		NSDate *statsDate = [defaults objectForKey:STATS_LAST_UPDATED_DATE];
		NSDate *today = [NSDate date];
		NSTimeInterval difference = [today timeIntervalSinceDate:statsDate];
		NSTimeInterval statsInterval = 7 * 24 * 60 * 60; //number of seconds in 30 days
		if (difference > statsInterval) //if it's been more than 7 days since last stats run
		{
            // WARNING: for some reason, if runStats is called in a background thread
            // NSURLConnection doesn't launch and stats are not sent
            // Don't change this or be really sure it's working
			[UpdateChecker sendDeviceInfoAndCheckForUpgrade];
		}
	}
}

+ (void)sendDeviceInfoAndCheckForUpgrade {
    //generate and post the stats data
	/*
	 - device_uuid – A unique identifier to the iPhone/iPod that the app is installed on.
	 - app_version – the version number of the WP iPhone app
	 - language – language setting for the device. What does that look like? Is it EN or English?
	 - os_version – the version of the iPhone/iPod OS for the device
	 - num_blogs – number of blogs configured in the WP iPhone app
	 - device_model - kind of device on which the WP iPhone app is installed
	 */
	
	NSString *deviceModel = [[UIDeviceHardware platform] stringByUrlEncoding];
	NSString *deviceuuid = [[UIDevice currentDevice] wordpressIdentifier];
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *appversion = [[info objectForKey:@"CFBundleVersion"] stringByUrlEncoding];
	NSLocale *locale = [NSLocale currentLocale];
	NSString *language = [[locale objectForKey: NSLocaleIdentifier] stringByUrlEncoding];
	NSString *osversion = [[[UIDevice currentDevice] systemVersion] stringByUrlEncoding];
	NSNumber *blogCount = @([Blog countWithContext:[[WordPressDataModel sharedDataModel] managedObjectContext]]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.wordpress.org/iphoneapp/update-check/1.0/"]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:30.0];
	
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	
	[postBody appendData:[[NSString stringWithFormat:@"device_uuid=%@&app_version=%@&language=%@&os_version=%@&num_blogs=%@&device_model=%@",
						   deviceuuid,
						   appversion,
						   language,
						   osversion,
						   blogCount,
						   deviceModel] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:postBody];
	
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData *responseObject) {
        NSString *statsDataString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        statsDataString = [[statsDataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
        NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        if ([statsDataString compare:appversion options:NSNumericSearch] > 0) {
            NSLog(@"There's a new version: %@", statsDataString);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update Available", @"Popup title to highlight a new version of the app being available.")
                                                            message:NSLocalizedString(@"A new version of WordPress for iOS is now available", @"Generic popup message to highlight a new version of the app being available.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss button label.")
                                                  otherButtonTitles:NSLocalizedString(@"Update Now", @"Popup 'update' button to highlight a new version of the app being available. The button takes you to the app store on the device, and should be actionable."), nil];
            alert.tag = 102;
            [alert show];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle: [error localizedDescription]
                                   message: [error localizedFailureReason]
                                   delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label (shown in popups).")
                                   otherButtonTitles:nil];
        [errorAlert show];
    }];
    
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:STATS_LAST_UPDATED_DATE];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
