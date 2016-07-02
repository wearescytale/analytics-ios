//
//  SEGIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGIntegration.h"

@class SEGAnalytics;

@interface SEGIntegrationsManager : NSObject

@property (nonatomic, weak) SEGAnalytics *analytics;
@property (nonatomic, readonly) NSDictionary *cachedSettings;
@property (nonatomic, readonly) NSDictionary *integrations;

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics;

@end

@interface SEGIntegrationsManager (SEGIntegration)

- (void)identify:(NSString *)userId anonymousId:(NSString *)anonymousId traits:(NSDictionary *)traits context:(NSDictionary *)context integrations:(NSDictionary *)integrations;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context integrations:(NSDictionary *)integrations;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context integrations:(NSDictionary *)integrations;
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits context:(NSDictionary *)context integrations:(NSDictionary *)integrations;
- (void)alias:(NSString *)newId context:(NSDictionary *)context integrations:(NSDictionary *)integrations;

// Reset is invoked when the user logs out, and any data saved about the user should be cleared.
- (void)reset;

// Flush is invoked when any queued events should be uploaded.
- (void)flush;

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
