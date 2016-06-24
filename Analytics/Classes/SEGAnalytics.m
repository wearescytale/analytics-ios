#import <UIKit/UIKit.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGAnalytics.h"
#import "SEGIntegrationFactory.h"
#import "SEGIntegration.h"
#import "SEGSegmentIntegrationFactory.h"
#import "UIViewController+SEGScreen.h"
#import "SEGStoreKitTracker.h"
#import "SEGIntegrationsManager.h"
#import "SEGLifecycleTracker.h"
#import <objc/runtime.h>

static SEGAnalytics *__sharedInstance = nil;
NSString *SEGAnalyticsIntegrationDidStart = @"io.segment.analytics.integration.did.start";


@interface SEGAnalytics ()

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) SEGStoreKitTracker *storeKitTracker;
@property (nonatomic, strong) SEGIntegrationsManager *integrations;
@property (nonatomic, strong) SEGLifecycleTracker *lifecycle;

@end


@implementation SEGAnalytics

+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    NSCParameterAssert(configuration != nil);
    
    if (self = [self init]) {
        _configuration = configuration;
        _enabled = YES;
        _serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        
        if (configuration.recordScreenViews) {
            [UIViewController seg_swizzleViewDidAppear];
        }
        if (configuration.trackInAppPurchases) {
            _storeKitTracker = [SEGStoreKitTracker trackTransactionsForAnalytics:self];
        }
        // TODO: Not fully initialized yet
        _integrations = [[SEGIntegrationsManager alloc] initWithAnalytics:self];
        _lifecycle = [[SEGLifecycleTracker alloc] initWithAnalytics:self];
        if (configuration.trackApplicationLifecycleEvents) {
            [self.lifecycle trackApplicationLifecycleEvents];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    NSCParameterAssert(userId.length > 0 || traits.count > 0);
    
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:userId
                                                                 anonymousId:[options objectForKey:@"anonymousId"]
                                                                      traits:SEGCoerceDictionary(traits)
                                                                     context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                                integrations:[options objectForKey:@"integrations"]];
    [self.integrations identify:payload];
}

- (void)track:(NSString *)event {
    [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSCParameterAssert(event.length > 0);
    
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:event
                                                           properties:SEGCoerceDictionary(properties)
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];
    [self.integrations track:payload];
}

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSCParameterAssert(screenTitle.length > 0);
    
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:screenTitle
                                                            properties:SEGCoerceDictionary(properties)
                                                               context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                          integrations:[options objectForKey:@"integrations"]];
    [self.integrations screen:payload];
}

- (void)group:(NSString *)groupId {
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:groupId
                                                                 traits:SEGCoerceDictionary(traits)
                                                                context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                           integrations:[options objectForKey:@"integrations"]];
    
    [self.integrations group:payload];
}

- (void)alias:(NSString *)newId {
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
    SEGAliasPayload *payload = [[SEGAliasPayload alloc] initWithNewId:newId
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];
    [self.integrations alias:payload];
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo {

}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error {

}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSParameterAssert(deviceToken != nil);

}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
}

- (void)reset {
    [self.integrations reset];
}

- (void)flush {
    [self.integrations flush];
}

- (void)enable {
    _enabled = YES;
}

- (void)disable {
    _enabled = NO;
}

#pragma mark - Class Methods

+ (instancetype)sharedAnalytics {
    NSCParameterAssert(__sharedInstance != nil);
    return __sharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs {
    SEGSetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version {
    return @"3.2.4";
}

- (NSDictionary *)bundledIntegrations {
    return [self.integrations.registeredIntegrations copy];
}

@end
