//
//  SEGContext.h
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEGAnalyticsConfiguration;
@interface SEGContext : NSObject

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) NSString *pushToken;

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration;

- (NSDictionary *)staticContext;
- (NSDictionary *)contextForTraits:(NSDictionary *)traits;

@end
