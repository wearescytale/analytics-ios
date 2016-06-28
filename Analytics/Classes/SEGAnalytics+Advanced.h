//
//  SEGAnalytics+Advanced.h
//  Analytics
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGAnalytics.h"

/*
 * Typically one would use the automatic tracking mode. However if for some reason you would like to avoid method swizzling
 * used by automatic tracking mode, you can disable via SEGAnalyticsConfiguration, but then it would be your responsibility
 * to ensure the following methods are correctly called manually
 */

@interface SEGAnalytics (Advanced)

// Callbacks for notifications changes.
// ------------------------------------
- (void)receivedRemoteNotification:(NSDictionary *)userInfo;
- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo;

// Callbacks for app state changes
// -------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end
