//
//  SEGLifecycleTracker.m
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

//@import UIKit;
#import <UIKit/UIKit.h>
#import "SEGAnalyticsUtils.h"
#import "SEGLifecycleTracker.h"
#import "SEGAnalytics.h"

static NSString *const SEGVersionKey = @"SEGVersionKey";
static NSString *const SEGBuildKey = @"SEGBuildKey";

@interface SEGLifecycleTracker ()

@property (nullable, nonatomic, weak) SEGAnalytics *analytics;

@end

@implementation SEGLifecycleTracker

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        _analytics = analytics;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        // Pass through for application state change events
        for (NSString *name in @[ UIApplicationDidEnterBackgroundNotification,
                                  UIApplicationDidFinishLaunchingNotification,
                                  UIApplicationWillEnterForegroundNotification,
                                  UIApplicationWillTerminateNotification,
                                  UIApplicationWillResignActiveNotification,
                                  UIApplicationDidBecomeActiveNotification ]) {
            [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleAppStateNotification:(NSNotification *)note {
    SEGLog(@"Application state change notification: %@", note.name);
//    static NSDictionary *selectorMapping;
//    static dispatch_once_t selectorMappingOnce;
//    dispatch_once(&selectorMappingOnce, ^{
//        selectorMapping = @{
//        UIApplicationDidFinishLaunchingNotification:
//            NSStringFromSelector(@selector(applicationDidFinishLaunching:)),
//        UIApplicationDidEnterBackgroundNotification:
//            NSStringFromSelector(@selector(applicationDidEnterBackground)),
//        UIApplicationWillEnterForegroundNotification:
//            NSStringFromSelector(@selector(applicationWillEnterForeground)),
//        UIApplicationWillTerminateNotification:
//            NSStringFromSelector(@selector(applicationWillTerminate)),
//        UIApplicationWillResignActiveNotification:
//            NSStringFromSelector(@selector(applicationWillResignActive)),
//        UIApplicationDidBecomeActiveNotification:
//            NSStringFromSelector(@selector(applicationDidBecomeActive))
//        };
//    });
}


- (void)trackApplicationLaunch {
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
