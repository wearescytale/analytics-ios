//
//  Analytics.h
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

#define JSON_DICTIONARY NSDictionary<NSString *, id> *

@class SEGAnalyticsConfiguration;

@interface Analytics : NSObject

@property (nonnull, nonatomic, readonly) SEGAnalyticsConfiguration *config;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL debugMode;

// User identity management

@property (nonnull, nonatomic, readonly) NSString *anonymousId;
@property (nullable, nonatomic, readonly) NSString *userId;


- (void)identify:(NSString * _Nonnull)userId traits:(JSON_DICTIONARY _Nullable)traits;
- (void)alias:(NSString * _Nonnull)newId;

- (void)track:(NSString * _Nonnull)event properties:(JSON_DICTIONARY _Nullable)traits;
- (void)group:(NSString * _Nonnull)name properties:(JSON_DICTIONARY _Nullable)traits;

- (void)reset;
- (void)flush;

@end
