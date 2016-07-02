//
//  SEGLifecycleTracker.m
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

//@import UIKit;
#import <UIKit/UIKit.h>
#import "SEGUtils.h"
#import "SEGLifecycleTracker.h"
#import "Analytics.h"

static NSString *const SEGVersionKey = @"SEGVersionKey";
static NSString *const SEGBuildKey = @"SEGBuildKey";

@interface SEGLifecycleTracker ()

@property (nullable, nonatomic, weak) SEGAnalytics *analytics;

@end

@implementation SEGLifecycleTracker

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        _analytics = analytics;
        [self setupNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.analytics];
}

- (void)setupNotification:(NSString *)name selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:self.analytics selector:selector name:name object:nil];
}

- (void)setupNotifications {
    [self setupNotification:UIApplicationDidFinishLaunchingNotification selector:@selector(applicationDidFinishLaunching:)];
    [self setupNotification:UIApplicationWillEnterForegroundNotification selector:@selector(applicationWillEnterForeground)];
    [self setupNotification:UIApplicationDidBecomeActiveNotification selector:@selector(applicationDidBecomeActive)];
    [self setupNotification:UIApplicationWillResignActiveNotification selector:@selector(applicationWillResignActive)];
    [self setupNotification:UIApplicationDidEnterBackgroundNotification selector:@selector(applicationDidEnterBackground)];
    [self setupNotification:UIApplicationWillTerminateNotification selector:@selector(applicationWillTerminate)];
}

- (void)trackApplicationLifecycleEvents {
    NSString *previousVersion = [[NSUserDefaults standardUserDefaults] stringForKey:SEGVersionKey];
    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    
    NSInteger previousBuild = [[NSUserDefaults standardUserDefaults] integerForKey:SEGBuildKey];
    NSInteger currentBuild = [[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] integerValue];
    
    if (!previousVersion) {
        [self.analytics track:@"Application Installed" properties:@{
            @"version" : currentVersion,
            @"build" : @(currentBuild)
        }];
    } else if (currentBuild != previousBuild) {
        [self.analytics track:@"Application Updated" properties:@{
            @"previous_version" : previousVersion,
            @"previous_build" : @(previousBuild),
            @"version" : currentVersion,
            @"build" : @(currentBuild)
        }];
    }
    [self.analytics track:@"Application Opened" properties:@{
        @"version" : currentVersion,
        @"build" : @(currentBuild)
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:SEGVersionKey];
    [[NSUserDefaults standardUserDefaults] setInteger:currentBuild forKey:SEGBuildKey];
}

@end
