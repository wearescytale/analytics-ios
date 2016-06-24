//
//  SEGLifecycleTracker.h
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEGAnalytics;
@interface SEGLifecycleTracker : NSObject

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics;
- (void)trackApplicationLifecycleEvents;

@end
