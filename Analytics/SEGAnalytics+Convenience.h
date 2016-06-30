//
//  SEGAnalytics+Convenience.h
//  Analytics
//
//  Created by Tony Xiao on 6/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGAnalytics.h"

#define JSON_DICT NSDictionary<NSString *, id> *

@interface SEGAnalytics (Convenience)

- (void)identify:(NSString * _Nonnull)userId traits:(JSON_DICT _Nullable)traits;
- (void)identify:(NSString * _Nonnull)userId;

- (void)track:(NSString * _Nonnull)event properties:(JSON_DICT _Nullable)properties;
- (void)track:(NSString * _Nonnull)event;

- (void)screen:(NSString * _Nonnull)screenTitle properties:(JSON_DICT _Nullable)properties;
- (void)screen:(NSString * _Nonnull)screenTitle;

- (void)group:(NSString * _Nonnull)groupId traits:(JSON_DICT _Nullable)traits;
- (void)group:(NSString * _Nonnull)groupId;

- (void)alias:(NSString * _Nonnull)newId;

+ (void)identify:(NSString * _Nonnull)userId traits:(JSON_DICT _Nullable)traits;
+ (void)identify:(NSString * _Nonnull)userId;

+ (void)track:(NSString * _Nonnull)event properties:(JSON_DICT _Nullable)properties;
+ (void)track:(NSString * _Nonnull)event;

+ (void)screen:(NSString * _Nonnull)screenTitle properties:(JSON_DICT _Nullable)properties;
+ (void)screen:(NSString * _Nonnull)screenTitle;

+ (void)group:(NSString * _Nonnull)groupId traits:(JSON_DICT _Nullable)traits;
+ (void)group:(NSString * _Nonnull)groupId;

+ (void)alias:(NSString * _Nonnull)newId;

+ (void)flush;
+ (void)reset;

/**
 * Setup the analytics client.
 *
 * @param configuration The configuration used to setup the client.
 */
+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration * _Nonnull)configuration;

/**
 * Same as setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:]
 */
+ (void)setupWithWriteKey:(NSString * _Nonnull)writeKey;

/**
 * Returns the shared analytics client.
 *
 * @see -setupWithConfiguration:
 */
+ (instancetype _Nonnull)sharedAnalytics;

@end
