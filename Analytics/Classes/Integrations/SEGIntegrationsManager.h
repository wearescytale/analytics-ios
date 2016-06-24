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
@property (nonatomic, strong) NSDictionary *integrationsByKey;
@property (nonatomic, strong) NSDictionary *settings;

@end

@interface SEGIntegrationsManager (SEGIntegration) <SEGIntegration>

@end