//
//  SEGIntegrationsManager.m
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGIntegrationsManager.h"
#import "SEGIntegration.h"

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

typedef void (^IntegrationBlock)(NSString * _Nonnull key, id<SEGIntegration> _Nonnull integration);

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
        
        // Refresh setings upon entering foreground
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshSettings)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self refreshSettings];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        [self updateIntegrationsWithSettings:settings[@"integrations"] callback:nil];
    });
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)projectSettings callback:(void (^)(void))block {
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
        if (block) { block(); }
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
            for (NSString *key in self.integrations) {
                block(key, self.integrations[key]);
            }
        }
        [self.messageQueue removeAllObjects];
    }
}

- (void)eachIntegration:(IntegrationBlock _Nonnull)block {
    for (NSString *key in self.integrations) {
        if (self.initialized) {
            block(key, self.integrations[key]);
        } else {
            [self.messageQueue addObject:[block copy]];
        }
    }
}

- (BOOL)isIntegration:(NSString *)key enabledInOptions:(NSDictionary *)options forSelector:(SEL)selector {
    if (![self.integrations[@"key"] respondsToSelector:selector]) {
        return NO;
    }
    if (options[key]) {
        return [options[key] boolValue];
    } else if (options[@"All"]) {
        return [options[@"All"] boolValue];
    } else if (options[@"all"]) {
        return [options[@"all"] boolValue];
    }
    return YES;
}

- (BOOL)isTrackEvent:(NSString *)event enabledForIntegration:(NSString *)key inPlan:(NSDictionary *)plan {
    // TODO: Implement tracking plan filtering for events sent to Segment as well
    if (plan[@"track"][event]) {
        return [plan[@"track"][event][@"enabled"] boolValue];
    }
    return YES;
}

@end

@implementation SEGIntegrationsManager (SEGIntegration)

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:userId
                                                                 anonymousId:[options objectForKey:@"anonymousId"]
                                                                      traits:SEGCoerceDictionary(traits)
                                                                     context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                                integrations:[options objectForKey:@"integrations"]];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(identify:)]) {
            [integration identify:payload];
        }
    }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:event
                                                           properties:SEGCoerceDictionary(properties)
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(track:)]) {
            if ([self isTrackEvent:payload.event enabledForIntegration:key inPlan:self.cachedSettings[@"plan"]]) {
                [integration track:payload];
            }
        }
    }];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:screenTitle
                                                            properties:SEGCoerceDictionary(properties)
                                                               context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                          integrations:[options objectForKey:@"integrations"]];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(screen:)]) {
            // TODO: Respect the tracking plan here
            [integration screen:payload];
        }
    }];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:groupId
                                                                 traits:SEGCoerceDictionary(traits)
                                                                context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                           integrations:[options objectForKey:@"integrations"]];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(group:)]) {
            // TODO: Respect the tracking plan here
            [integration group:payload];
        }
    }];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
    SEGAliasPayload *payload = [[SEGAliasPayload alloc] initWithNewId:newId
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(alias:)]) {
            // TODO: Respect the tracking plan here
            [integration alias:payload];
        }
    }];
}

- (void)reset {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(reset)]) {
            [integration reset];
        }
    }];
}

// TODO: Implement me
- (void)flush {}
- (void)receivedRemoteNotification:(NSDictionary *)userInfo {}
- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error {}
- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {}
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {}
- (void)applicationDidEnterBackground {}
- (void)applicationWillEnterForeground {}
- (void)applicationWillTerminate {}
- (void)applicationWillResignActive {}
- (void)applicationDidBecomeActive {}

@end