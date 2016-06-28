#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGIntegration.h"
#import "UIViewController+SEGScreen.h"
#import "SEGStoreKitTracker.h"
#import "SEGIntegrationsManager.h"
#import "SEGLifecycleTracker.h"
#import "SEGNetworkTransporter.h"
#import "SEGContext.h"
#import "SEGMigration.h"
#import "SEGUtils.h"
#import "SEGUser.h"
#import "Analytics.h"

static SEGAnalytics *__sharedInstance = nil;
NSString *SEGAnalyticsIntegrationDidStart = @"io.segment.analytics.integration.did.start";
NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";

@interface SEGAnalytics ()

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) SEGUser *user;
@property (nonatomic, strong) SEGContext *ctx;
@property (nonatomic, strong) SEGNetworkTransporter *transporter;
@property (nonatomic, strong) SEGLifecycleTracker *lifecycle;
@property (nonatomic, strong) SEGIntegrationsManager *integrations;
@property (nonatomic, strong) SEGStoreKitTracker *storeKitTracker;

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
        _ctx = [[SEGContext alloc] initWithConfiguration:_configuration];
        _user = [[SEGUser alloc] init];
        
        _transporter = [[SEGNetworkTransporter alloc] initWithConfiguration:_configuration];
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
        // Check for previous queue/track data in NSUserDefaults and remove if present
        [self dispatchBackground:^{
            [SEGMigration migrateToLatest];
        }];
    }
    return self;
}

- (void)dispatchBackground:(void (^)(void))block {
    seg_dispatch_specific_async(self.serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block {
    seg_dispatch_specific_sync(self.serialQueue, block);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(userId.length > 0 || traits.count > 0);
    [self dispatchBackground:^{
        NSString *anonymousId = [options objectForKey:@"anonymousId"];
        self.user.userId = userId;
        [self.user addTraits:traits];
        if (anonymousId) {
            self.user.anonymousId = anonymousId;
        }
    }];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:traits forKey:@"traits"];
    [self enqueueAction:@"identify"
             dictionary:@{@"traits": SEGCoerceDictionary(traits)}
                context:SEGCoerceDictionary([options objectForKey:@"context"])
           integrations:[options objectForKey:@"integrations"]];
    [self.integrations identify:userId traits:traits options:options];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(event.length > 0);
    [self enqueueAction:@"track"
             dictionary:@{
                          @"event": event,
                          @"properties": SEGCoerceDictionary(properties)
                          }
                context:SEGCoerceDictionary([options objectForKey:@"context"])
           integrations:[options objectForKey:@"integrations"]];
    [self.integrations track:event properties:properties options:options];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSCParameterAssert(screenTitle.length > 0);
    [self enqueueAction:@"screen"
             dictionary:@{
                          @"name": screenTitle,
                          @"properties": SEGCoerceDictionary(properties)
                          }
                context:SEGCoerceDictionary([options objectForKey:@"context"])
           integrations:[options objectForKey:@"integrations"]];
    [self.integrations screen:screenTitle properties:properties options:options];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:groupId forKey:@"groupId"];
    [dictionary setValue:SEGCoerceDictionary(traits) forKey:@"traits"];
    NSDictionary *context = SEGCoerceDictionary([options objectForKey:@"context"]);
    NSDictionary *integrations = [options objectForKey:@"integrations"];
    [self enqueueAction:@"group" dictionary:dictionary context:context integrations:integrations];
    [self.integrations group:groupId traits:traits options:options];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
    if (!self.enabled) { return; }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:newId forKey:@"userId"];
    [dictionary setValue:self.user.userId ?: self.user.anonymousId forKey:@"previousId"];
    NSDictionary *context = SEGCoerceDictionary([options objectForKey:@"context"]);
    NSDictionary *integrations = [options objectForKey:@"integrations"];
    
    [self enqueueAction:@"alias" dictionary:dictionary context:context integrations:integrations];
    [self.integrations alias:newId options:options];
}

- (void)reset {
    if (!self.enabled) { return; }
    [self dispatchBackgroundAndWait:^{
        [self.user reset];
        [self.transporter reset];
        [self.integrations reset];
    }];
}

- (void)flush {
    [self.transporter flush];
    [self.integrations flush];
}

- (void)enable {
    _enabled = YES;
}

- (void)disable {
    _enabled = NO;
}

#pragma mark - Helpers

- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations {
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (NSString *integration in self.bundledIntegrations) {
        dict[integration] = @NO;
    }
    return [dict copy];
}

- (void)enqueueAction:(NSString *)action dictionary:(NSDictionary *)origPayload context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [origPayload mutableCopy];
    payload[@"type"] = action;
    payload[@"timestamp"] = iso8601FormattedString([NSDate date]);
    payload[@"messageId"] = [SEGUtils generateUUIDString];
    
    [self dispatchBackground:^{
        // attach userId and anonymousId inside the dispatch_async in case
        // they've changed (see identify function)
        
        // Do not override the userId for an 'alias' action. This value is set in [alias:] already.
        if (![action isEqualToString:@"alias"]) {
            [payload setValue:self.user.userId forKey:@"userId"];
        }
        [payload setValue:self.user.anonymousId forKey:@"anonymousId"];
        
        [payload setValue:[self integrationsDictionary:integrations] forKey:@"integrations"];
        
        NSDictionary *defaultContext = [self.ctx contextForTraits:self.user.traits];
        NSDictionary *customContext = context;
        NSMutableDictionary *context = [NSMutableDictionary dictionaryWithCapacity:customContext.count + defaultContext.count];
        [context addEntriesFromDictionary:defaultContext];
        [context addEntriesFromDictionary:customContext]; // let the custom context override ours
        [payload setValue:[context copy] forKey:@"context"];
        
        SEGLog(@"%@ Enqueueing action: %@", self, payload);
        [self.transporter queuePayload:payload];
    }];
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
    return @"3.3.0";
}

- (NSDictionary *)bundledIntegrations {
    return [self.integrations.registeredIntegrations copy];
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
    [self.ctx addPushTokenToContext:[SEGUtils convertPushTokenToString:deviceToken]];
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
