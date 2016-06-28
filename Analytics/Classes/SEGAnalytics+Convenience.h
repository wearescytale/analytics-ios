//
//  SEGAnalytics+Convenience.h
//  Analytics
//
//  Created by Tony Xiao on 6/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGAnalytics.h"

@interface SEGAnalytics (Convenience)

- (void)identify:(NSString * _Nonnull)userId traits:(NSDictionary * _Nullable)traits;
- (void)identify:(NSString * _Nonnull)userId;

- (void)track:(NSString * _Nonnull)event properties:(NSDictionary * _Nullable)properties;
- (void)track:(NSString * _Nonnull)event;

- (void)screen:(NSString * _Nonnull)screenTitle properties:(NSDictionary * _Nullable)properties;
- (void)screen:(NSString * _Nonnull)screenTitle;

- (void)group:(NSString * _Nonnull)groupId traits:(NSDictionary * _Nullable)traits;
- (void)group:(NSString * _Nonnull)groupId;

- (void)alias:(NSString * _Nonnull)newId;

+ (void)setupWithWriteKey:(NSString * _Nonnull)writeKey;

@end
