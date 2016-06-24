//
//  SEGIntegrationsManager.m
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGIntegrationsManager.h"
#import "SEGIntegrationFactory.h"

@interface SEGIntegrationsManager ()

@property (nonatomic, strong) NSDictionary *cachedSettings;
@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) SEGAnalyticsRequest *settingsRequest;
@property (nonatomic, strong) NSArray *factories;
@property (nonatomic, strong) NSMutableDictionary *integrations;
@property (nonatomic, strong) NSMutableDictionary *registeredIntegrations;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic) volatile BOOL initialized;

@end

typedef void (^IntegrationBlock)(id<SEGIntegration> integration);

@implementation SEGIntegrationsManager

@synthesize cachedSettings = _cachedSettings;

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        _analytics = analytics;
        _configuration = analytics.configuration;
        _factories = [self.configuration.factories copy];
        _integrations = [NSMutableDictionary dictionaryWithCapacity:self.factories.count];
        _registeredIntegrations = [NSMutableDictionary dictionaryWithCapacity:self.factories.count];
        _messageQueue = [[NSMutableArray alloc] init];
        _serialQueue = seg_dispatch_queue_create_specific("com.segment.analytics.integrations", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSURL *)settingsURL {
    return SEGAnalyticsURLForFilename(@"analytics.settings.v2.plist");
}


- (NSDictionary *)cachedSettings {
    if (!_cachedSettings)
        _cachedSettings = [[NSDictionary alloc] initWithContentsOfURL:[self settingsURL]] ?: @{};
    return _cachedSettings;
}

- (void)setCachedSettings:(NSDictionary *)settings {
    _cachedSettings = [settings copy];
    NSURL *settingsURL = [self settingsURL];
    if (!_cachedSettings) {
        // [@{} writeToURL:settingsURL atomically:YES];
        return;
    }
    [_cachedSettings writeToURL:settingsURL atomically:YES];
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self updateIntegrationsWithSettings:settings[@"integrations"]];
    });
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)projectSettings {
    for (id<SEGIntegrationFactory> factory in self.factories) {
        NSString *key = [factory key];
        NSDictionary *integrationSettings = [projectSettings objectForKey:key];
        if (integrationSettings) {
            id<SEGIntegration> integration = [factory createWithSettings:integrationSettings forAnalytics:self.analytics];
            if (integration != nil) {
                self.integrations[key] = integration;
                self.registeredIntegrations[key] = @NO;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SEGAnalyticsIntegrationDidStart object:key userInfo:nil];
        } else {
            SEGLog(@"No settings for %@. Skipping.", key);
        }
    }
    
    seg_dispatch_specific_async(_serialQueue, ^{
        [self flushMessageQueue];
        self.initialized = true;
    });
}

- (void)refreshSettings {
    if (self.settingsRequest) {
        return;
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:
        [NSString stringWithFormat:@"https://cdn.segment.com/v1/projects/%@/settings", self.configuration.writeKey]]];
    urlRequest.HTTPMethod = @"GET";
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    SEGLog(@"%@ Sending API settings request: %@", self, urlRequest);
    
    self.settingsRequest = [SEGAnalyticsRequest startWithURLRequest:urlRequest
                                                     completion:^{
        seg_dispatch_specific_async(self.serialQueue, ^{
            SEGLog(@"%@ Received API settings response: %@", self, self.settingsRequest.responseJSON);

            if (self.settingsRequest.error == nil) {
                [self setCachedSettings:self.settingsRequest.responseJSON];
            }
            self.settingsRequest = nil;
        });
    }];
}

- (void)flushMessageQueue {
    if (self.messageQueue.count > 0) {
        for (IntegrationBlock block in self.messageQueue) {
            for (id<SEGIntegration> integration in self.integrations.allValues) {
                block(integration);
            }
        }
        [self.messageQueue removeAllObjects];
    }
}

- (void)eachIntegration:(IntegrationBlock _Nonnull)block {
    for (id<SEGIntegration> integration in self.integrations.allValues) {
        if (self.initialized) {
            block(integration);
        } else {
            [self.messageQueue addObject:[block copy]];
        }
    }
}

@end

@implementation SEGIntegrationsManager (SEGIntegration)

- (void)identify:(SEGIdentifyPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration identify:payload];
    }];
}

- (void)track:(SEGTrackPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration track:payload];
    }];
}

- (void)screen:(SEGScreenPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration screen:payload];
    }];
}

- (void)group:(SEGGroupPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration group:payload];
    }];
}

- (void)alias:(SEGAliasPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration alias:payload];
    }];
}

- (void)reset {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration reset];
    }];
}

- (void)flush {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration flush];
    }];
}

@end