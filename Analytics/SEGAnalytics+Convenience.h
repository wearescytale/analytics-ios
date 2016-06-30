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

- (instancetype _Nonnull)initWithWriteKey:(NSString * _Nonnull)writeKey;

- (void)identify:(NSString * _Nonnull)userId traits:(JSON_DICT _Nullable)traits;
- (void)identify:(NSString * _Nonnull)userId;

- (void)track:(NSString * _Nonnull)event properties:(JSON_DICT _Nullable)properties;
- (void)track:(NSString * _Nonnull)event;

- (void)screen:(NSString * _Nonnull)screenTitle properties:(JSON_DICT _Nullable)properties;
- (void)screen:(NSString * _Nonnull)screenTitle;

- (void)group:(NSString * _Nonnull)groupId traits:(JSON_DICT _Nullable)traits;
- (void)group:(NSString * _Nonnull)groupId;

- (void)alias:(NSString * _Nonnull)newId;

/* 
 The following class methods simply call equivalent instance methods on `[SEGAnalytics sharedAnalytics]`
 So once you do `[SEGAnalytics setupWithWriteKey:@"YOUR_SEGMENT_WRITE_KEY"];`
 You can write `[SEGAnalytics track:@"Item Purchased"]`
 Which is just a shorthand for `[[SEGAnalytics sharedAnalytics] track:@"Item Purchased"]`
 If you are using Segment from swift, we recommend simply creating a global Analytics singleton
 ```
 let Analytics = SEGAnalytics(writeKey: "YOUR_SEGMENT_WRITE_KEY")
 
 // elsewhere in your app
 func doSomething() {
    Analytics.track("Item Purchased")
 }
 ```
 */

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
+ (instancetype _Null_unspecified)sharedAnalytics;

@end
