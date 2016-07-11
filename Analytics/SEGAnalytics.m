#import "SEGDispatchQueue.h"
#import "SEGMigration.h"
#import "SEGContext.h"
#import "SEGUser.h"
#import "SEGNetworkTransporter.h"
#import "SEGIntegrationsManager.h"
#import "SEGStoreKitTracker.h"
#import "SEGScreenTracker.h"
#import "SEGLifecycleTracker.h"
#import "SEGUtils.h"
#import "SEGAnalytics.h"
#import "Analytics.h"

NSString *SEGAnalyticsIntegrationDidStart = @"io.segment.analytics.integration.did.start";

@interface SEGAnalytics ()

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonnull, nonatomic, strong) SEGDispatchQueue *dispatchQueue;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL debugMode;
@property (nonatomic, strong) SEGUser *user;
@property (nonatomic, strong) SEGContext *ctx;
@property (nonatomic, strong) SEGNetworkTransporter *transporter;
@property (nonatomic, strong) SEGLifecycleTracker *lifecycle;
@property (nonatomic, strong) SEGIntegrationsManager *integrations;
@property (nonatomic, strong) SEGStoreKitTracker *storeKitTracker;
@property (nonatomic, strong) SEGScreenTracker *screenTracker;

@end

@implementation SEGAnalytics

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    NSCParameterAssert(configuration != nil);
    
    if (self = [self init]) {
        _enabled = YES;
        _configuration = configuration;
        _dispatchQueue = [[SEGDispatchQueue alloc] initWithLabel:@"com.segment.analytics"];
        _ctx = [[SEGContext alloc] initWithConfiguration:_configuration];
        _user = [[SEGUser alloc] init];
        _transporter = [[SEGNetworkTransporter alloc] initWithWriteKey:configuration.writeKey flushAfter:30];
        // TODO: Not fully initialized yet
        _integrations = [[SEGIntegrationsManager alloc] initWithAnalytics:self];
        _lifecycle = [[SEGLifecycleTracker alloc] initWithAnalytics:self];
        
        if (configuration.recordScreenViews) {
            _screenTracker = [[SEGScreenTracker alloc] initWithAnalytics:self];
        }
        if (configuration.trackInAppPurchases) {
            _storeKitTracker = [[SEGStoreKitTracker alloc] initWithAnalytics:self];
        }
        if (configuration.trackApplicationLifecycleEvents) {
            [self.lifecycle trackApplicationLifecycleEvents];
        }
        // Check for previous queue/track data in NSUserDefaults and remove if present
        [self.dispatchQueue async:^{
            [SEGMigration migrateToLatest];
        }];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(userId.length > 0 || traits.count > 0);
    traits = [SEGUtils coerceDictionary:traits];
    NSString *anonymousId = options[@"anonymousId"];
    NSDictionary *context = [SEGUtils coerceDictionary:options[@"context"]];
    NSDictionary *integrations = options[@"integrations"];
    [self.dispatchQueue async:^{
        self.user.userId = userId;
        [self.user addTraits:traits];
        if (anonymousId) {
            self.user.anonymousId = anonymousId;
        }
    }];
    [self enqueueAction:@"identify"
             dictionary:@{@"traits": traits}
                context:context
           integrations:options];
    [self.integrations identify:userId anonymousId:anonymousId traits:traits context:context integrations:integrations];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(event.length > 0);
    properties = [SEGUtils coerceDictionary:properties];
    NSDictionary *context = [SEGUtils coerceDictionary:options[@"context"]];
    NSDictionary *integrations = options[@"integrations"];
    [self enqueueAction:@"track"
             dictionary:@{@"event": event ?: [NSNull null], @"properties": properties}
                context:context
           integrations:integrations];
    [self.integrations track:event properties:properties context:context integrations:integrations];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(screenTitle.length > 0);
    properties = [SEGUtils coerceDictionary:properties];
    NSDictionary *context = [SEGUtils coerceDictionary:options[@"context"]];
    NSDictionary *integrations = options[@"integrations"];
    [self enqueueAction:@"screen"
             dictionary:@{@"name": screenTitle ?: [NSNull null], @"properties": properties}
                context:context
           integrations:integrations];
    [self.integrations screen:screenTitle properties:properties context:context integrations:integrations];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    traits = [SEGUtils coerceDictionary:traits];
    NSDictionary *context = [SEGUtils coerceDictionary:options[@"context"]];
    NSDictionary *integrations = options[@"integrations"];
    [self enqueueAction:@"group"
             dictionary:@{@"groupId": groupId ?: [NSNull null], @"traits": traits}
                context:context
           integrations:integrations];
    [self.integrations group:groupId traits:traits context:context integrations:integrations];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSString *previousId = self.user.userId ?: self.user.anonymousId;
    NSDictionary *context = [SEGUtils coerceDictionary:options[@"context"]];
    NSDictionary *integrations = options[@"integrations"];
    [self enqueueAction:@"alias"
             dictionary:@{@"userId": newId ?: [NSNull null], @"previousId": previousId}
                context:context
           integrations:integrations];
    [self.integrations alias:newId context:context integrations:integrations];
}

- (void)reset {
    if (!self.enabled) { return; }
    [self.dispatchQueue sync:^{
        [self.user reset];
        [self.transporter reset];
        [self.integrations reset];
    }];
}

- (void)flush {
    [self.dispatchQueue async:^{
        [self.transporter flush:nil];
        [self.integrations flush];
    }];
}

- (void)enable {
    _enabled = YES;
}

- (void)disable {
    _enabled = NO;
}

#pragma mark - Helpers

- (void)enqueueAction:(NSString *)action dictionary:(NSDictionary *)origPayload context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [origPayload mutableCopy];
    payload[@"type"] = action;
    payload[@"timestamp"] = [SEGUtils formatISO8601:[NSDate date]];
    payload[@"messageId"] = [SEGUtils generateUUIDString];
    
    [self.dispatchQueue async:^{
        // attach userId and anonymousId inside the dispatch_async in case
        // they've changed (see identify function)
        
        // Do not override the userId for an 'alias' action. This value is set in [alias:] already.
        if (![action isEqualToString:@"alias"]) {
            [payload setValue:self.user.userId forKey:@"userId"];
        }
        [payload setValue:self.user.anonymousId forKey:@"anonymousId"];
        
        NSMutableDictionary *combinedIntegrations = [integrations ?: @{} mutableCopy];
        for (NSString *integration in self.integrations.integrations) {
            combinedIntegrations[integration] = @NO;
        }
        [payload setValue:combinedIntegrations forKey:@"integrations"];
        
        NSMutableDictionary *combinedContext = [[self.ctx contextForTraits:self.user.traits] mutableCopy];
        [combinedContext addEntriesFromDictionary:context];
        [payload setValue:combinedContext forKey:@"context"];
        
        NSDictionary *finalPayload = payload;
        if ([self.delegate respondsToSelector:@selector(analytics:newPayloadForPayload:)]) {
            finalPayload = [self.delegate analytics:self newPayloadForPayload:payload];
        }
        SEGLog(@"%@ Enqueueing action: %@", self, finalPayload);
        [self.transporter queuePayload:finalPayload];
    }];
    if (self.debugMode) {
        [self flush];
    }
}

#pragma mark - Class Methods

+ (void)debug:(BOOL)showDebugLogs {
    [SEGAnalytics sharedAnalytics].debugMode = showDebugLogs;
    SEGSetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version {
    return @"3.3.0";
}

@end

@implementation SEGAnalytics (Advanced)

- (void)receivedRemoteNotification:(NSDictionary *)userInfo {
    if (!self.enabled) { return; }
    [self.integrations receivedRemoteNotification:userInfo];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (!self.enabled) { return; }
    [self.integrations failedToRegisterForRemoteNotificationsWithError:error];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (!self.enabled) { return; }
    NSParameterAssert(deviceToken != nil);
    self.ctx.pushToken = [SEGUtils convertPushTokenToString:deviceToken];
    [self.integrations registeredForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if (!self.enabled) { return; }
    [self.integrations handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if (!self.enabled) { return; }
    [self.integrations applicationDidFinishLaunching:notification];
}

- (void)applicationWillEnterForeground {
    if (!self.enabled) { return; }
    [self.integrations applicationWillEnterForeground];
}

- (void)applicationDidBecomeActive {
    if (!self.enabled) { return; }
    [self.integrations applicationDidBecomeActive];
}

- (void)applicationWillResignActive {
    if (!self.enabled) { return; }
    [self.integrations applicationWillResignActive];
}

- (void)applicationDidEnterBackground {
    if (!self.enabled) { return; }
    [self.integrations applicationDidEnterBackground];
}

- (void)applicationWillTerminate {
    if (!self.enabled) { return; }
    [self.integrations applicationWillTerminate];
}

@end
