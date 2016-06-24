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
@property (nonatomic, readonly) NSMutableDictionary *integrations;

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics;

@end

@interface SEGIntegrationsManager (SEGIntegration) <SEGIntegration>

@end
