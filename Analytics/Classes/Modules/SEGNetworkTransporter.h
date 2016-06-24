//
//  SEGNetworkTransporter.h
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEGAnalyticsConfiguration;
@interface SEGNetworkTransporter : NSObject

@property (nonatomic, strong) NSURL *apiURL;

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration;

@end
