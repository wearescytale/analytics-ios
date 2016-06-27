#import <UIKit/UIKit.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGAnalytics.h"
#import "SEGIntegration.h"
#import "UIViewController+SEGScreen.h"
#import "SEGStoreKitTracker.h"
#import "SEGIntegrationsManager.h"
#import "SEGLifecycleTracker.h"
#import "SEGNetworkTransporter.h"
#import "SEGContext.h"
#import "SEGUtils.h"
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
@property (nonatomic, strong) SEGNetworkTransporter *transporter;
@property (nonatomic, strong) SEGContext *ctx;

@property (nonatomic, copy) NSString *anonymousId;
@property (nonatomic, copy) NSString *userId;

@end

NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";
NSString *const SEGQueueKey = @"SEGQueue";
NSString *const SEGTraitsKey = @"SEGTraits";

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
        self.anonymousId = [self getAnonymousId:NO];
        self.userId = [self getUserId];
        
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
            if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGQueueKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGQueueKey];
            }
            if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGTraitsKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGTraitsKey];
            }
        }];
    }
    return self;
}

- (NSString *)getAnonymousId:(BOOL)reset {
    // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
    // identifierForVendor (iOS6 and later, can't be changed on logout),
    // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
    NSURL *url = self.anonymousIDURL;
    NSString *anonymousId = [[NSUserDefaults standardUserDefaults] valueForKey:SEGAnonymousIdKey] ?: [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!anonymousId || reset) {
        anonymousId = [SEGUtils generateUUIDString];
        SEGLog(@"New anonymousId: %@", anonymousId);
        [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:SEGAnonymousIdKey];
        [anonymousId writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    return anonymousId;
}

- (NSString *)getUserId {
    return [[NSUserDefaults standardUserDefaults] valueForKey:SEGUserIdKey] ?: [[NSString alloc] initWithContentsOfURL:self.userIDURL encoding:NSUTF8StringEncoding error:NULL];
}

- (void)saveUserId:(NSString *)userId {
    [self dispatchBackground:^{
        self.userId = userId;
        [self.userId writeToURL:self.userIDURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

- (void)saveAnonymousId:(NSString *)anonymousId {
    [self dispatchBackground:^{
        self.anonymousId = anonymousId;
        [[NSUserDefaults standardUserDefaults] setValue:anonymousId forKey:SEGAnonymousIdKey];
        [self.anonymousId writeToURL:self.anonymousIDURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

- (NSURL *)userIDURL {
    return SEGAnalyticsURLForFilename(@"segmentio.userId");
}

- (NSURL *)anonymousIDURL {
    return SEGAnalyticsURLForFilename(@"segment.anonymousId");
}

- (void)dispatchBackground:(void (^)(void))block {
    seg_dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block {
    seg_dispatch_specific_sync(_serialQueue, block);
}

- (NSString *)description {
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
    [self dispatchBackground:^{
        NSString *anonymousId = [options objectForKey:@"anonymousId"];
        [self saveUserId:userId];
        [self.ctx addTraits:traits];
        if (anonymousId) {
            [self saveAnonymousId:anonymousId];
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

- (void)track:(NSString *)event {
    [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
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

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
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

- (void)group:(NSString *)groupId {
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:groupId forKey:@"groupId"];
    [dictionary setValue:SEGCoerceDictionary(traits) forKey:@"traits"];
    NSDictionary *context = SEGCoerceDictionary([options objectForKey:@"context"]);
    NSDictionary *integrations = [options objectForKey:@"integrations"];
    [self enqueueAction:@"group" dictionary:dictionary context:context integrations:integrations];
    [self.integrations group:groupId traits:traits options:options];
}

- (void)alias:(NSString *)newId {
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:newId forKey:@"userId"];
    [dictionary setValue:self.userId ?: self.anonymousId forKey:@"previousId"];
    NSDictionary *context = SEGCoerceDictionary([options objectForKey:@"context"]);
    NSDictionary *integrations = [options objectForKey:@"integrations"];
    
    [self enqueueAction:@"alias" dictionary:dictionary context:context integrations:integrations];
    [self.integrations alias:newId options:options];
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo {

}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error {

}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSParameterAssert(deviceToken != nil);
    [self.ctx addPushTokenToContext:[SEGUtils convertPushTokenToString:deviceToken]];
    [self.integrations registeredForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
}

- (void)reset {
    [self dispatchBackgroundAndWait:^{
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGUserIdKey];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGAnonymousIdKey];
        [[NSFileManager defaultManager] removeItemAtURL:self.userIDURL error:NULL];
        self.userId = nil;
        [self.ctx reset];
        self.anonymousId = [self getAnonymousId:YES];
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
            [payload setValue:self.userId forKey:@"userId"];
        }
        [payload setValue:self.anonymousId forKey:@"anonymousId"];
        
        [payload setValue:[self integrationsDictionary:integrations] forKey:@"integrations"];
        
        NSDictionary *defaultContext = [self.ctx liveContext];
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
    return @"3.2.4";
}

- (NSDictionary *)bundledIntegrations {
    return [self.integrations.registeredIntegrations copy];
}

@end
