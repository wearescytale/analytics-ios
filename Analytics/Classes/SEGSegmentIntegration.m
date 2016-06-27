#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "SEGUtils.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGSegmentIntegration.h"
#import "SEGBluetooth.h"
#import "SEGReachability.h"
#import "SEGLocation.h"
#import "NSData+GZIP.h"
#import "SEGContext.h"
#import "SEGNetworkTransporter.h"

NSString *const SEGSegmentDidSendRequestNotification = @"SegmentDidSendRequest";
NSString *const SEGSegmentRequestDidSucceedNotification = @"SegmentRequestDidSucceed";
NSString *const SEGSegmentRequestDidFailNotification = @"SegmentRequestDidFail";

NSString *const SEGAdvertisingClassIdentifier = @"ASIdentifierManager";
NSString *const SEGADClientClass = @"ADClient";

NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";
NSString *const SEGQueueKey = @"SEGQueue";
NSString *const SEGTraitsKey = @"SEGTraits";

@interface SEGSegmentIntegration ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) SEGAnalytics *analytics;
@property (nonatomic, assign) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) SEGNetworkTransporter *transporter;
@property (nonatomic, strong) SEGContext *ctx;

@end


@implementation SEGSegmentIntegration

- (id)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        self.configuration = [analytics configuration];
        _ctx = [[SEGContext alloc] initWithConfiguration:_configuration];
        _transporter = [[SEGNetworkTransporter alloc] initWithConfiguration:_configuration];
        self.anonymousId = [self getAnonymousId:NO];
        self.userId = [self getUserId];
        self.serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        self.analytics = analytics;
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

- (void)dispatchBackground:(void (^)(void))block {
    seg_dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block {
    seg_dispatch_specific_sync(_serialQueue, block);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, self.configuration.writeKey];
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

#pragma mark - Analytics API

- (void)identify:(SEGIdentifyPayload *)payload {
    [self dispatchBackground:^{
        [self saveUserId:payload.userId];
        [self.ctx addTraits:payload.traits];
        if (payload.anonymousId) {
            [self saveAnonymousId:payload.anonymousId];
        }
    }];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.traits forKey:@"traits"];
    
    [self enqueueAction:@"identify" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)track:(SEGTrackPayload *)payload {
    SEGLog(@"segment integration received payload %@", payload);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.event forKey:@"event"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [self enqueueAction:@"track" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)screen:(SEGScreenPayload *)payload {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.name forKey:@"name"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    
    [self enqueueAction:@"screen" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)group:(SEGGroupPayload *)payload {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.groupId forKey:@"groupId"];
    [dictionary setValue:payload.traits forKey:@"traits"];
    
    [self enqueueAction:@"group" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)alias:(SEGAliasPayload *)payload {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.theNewId forKey:@"userId"];
    [dictionary setValue:self.userId ?: self.anonymousId forKey:@"previousId"];
    
    [self enqueueAction:@"alias" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSCParameterAssert(deviceToken != nil);
    [self.ctx addPushTokenToContext:[SEGUtils convertPushTokenToString:deviceToken]];
}

#pragma mark - Queueing

- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations {
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (NSString *integration in self.analytics.bundledIntegrations) {
        dict[integration] = @NO;
    }
    return [dict copy];
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)payload context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
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

- (void)flush {
    [self.transporter flush];
}

- (void)reset {
    [self dispatchBackgroundAndWait:^{
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGUserIdKey];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGAnonymousIdKey];
        [[NSFileManager defaultManager] removeItemAtURL:self.userIDURL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:self.traitsURL error:NULL];
        self.userId = nil;
        [self.ctx reset];
        self.anonymousId = [self getAnonymousId:YES];
        [self.transporter reset];
    }];
}

#pragma mark - Private

- (NSURL *)userIDURL {
    return SEGAnalyticsURLForFilename(@"segmentio.userId");
}

- (NSURL *)anonymousIDURL {
    return SEGAnalyticsURLForFilename(@"segment.anonymousId");
}

- (NSURL *)traitsURL {
    return SEGAnalyticsURLForFilename(@"segmentio.traits.plist");
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

@end