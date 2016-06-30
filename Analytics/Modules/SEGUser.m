//
//  SEGUser.m
//  Analytics
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGUser.h"
#import "SEGUtils.h"
#import "SEGAnalyticsUtils.h"

NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";

@interface SEGUser ()

@property (nonatomic, strong) NSMutableDictionary *traits;
@property (nonatomic, strong) NSUserDefaults *ud;
@property (nonatomic, strong) NSFileManager *fm;

@end

@implementation SEGUser {
    NSString *_anonymousId;
    NSString *_userId;
}

- (instancetype)init {
    if (self = [super init]) {
        _ud = [NSUserDefaults standardUserDefaults];
        _fm = [NSFileManager defaultManager];
    }
    return self;
}

- (NSString *)anonymousId {
    if (!_anonymousId) {
        _anonymousId = [self.ud valueForKey:SEGAnonymousIdKey]
            ?: [[NSString alloc] initWithContentsOfURL:self.anonymousIDURL encoding:NSUTF8StringEncoding error:NULL];
    }
    if (!_anonymousId) {
        // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
        // identifierForVendor (iOS6 and later, can't be changed on logout),
        // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
        self.anonymousId = [SEGUtils generateUUIDString];
        SEGLog(@"New anonymousId: %@", _anonymousId);
    }
    return _anonymousId;
}

- (void)setAnonymousId:(NSString *)anonymousId {
    _anonymousId = anonymousId;
    [self.ud setValue:anonymousId forKey:SEGAnonymousIdKey];
    [anonymousId writeToURL:self.anonymousIDURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (NSString *)userId {
    if (!_userId) {
        _userId =  [self.ud valueForKey:SEGUserIdKey]
            ?: [[NSString alloc] initWithContentsOfURL:self.userIDURL encoding:NSUTF8StringEncoding error:NULL];
    }
    return _userId;
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    [userId writeToURL:self.userIDURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (NSMutableDictionary *)traits {
    if (!_traits) {
        _traits = [NSMutableDictionary dictionaryWithContentsOfURL:self.traitsURL] ?: [[NSMutableDictionary alloc] init];
    }
    return _traits;
}

- (void)addTraits:(NSDictionary *)traits {
    // Better way around the compiler check here?
    [(NSMutableDictionary *)self.traits addEntriesFromDictionary:traits];
    [[self.traits copy] writeToURL:self.traitsURL atomically:YES];
}

- (void)reset {
    self.userId = nil;
    self.anonymousId = nil;
    self.traits = nil;
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGUserIdKey];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGAnonymousIdKey];
    [[NSFileManager defaultManager] removeItemAtURL:self.userIDURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:self.anonymousIDURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:self.traitsURL error:NULL];
    
    // TODO: Is generation of new ID actually desired?
    self.anonymousId = [SEGUtils generateUUIDString];
}

#pragma mark -

- (NSURL *)userIDURL {
    return SEGAnalyticsURLForFilename(@"segmentio.userId");
}

- (NSURL *)anonymousIDURL {
    return SEGAnalyticsURLForFilename(@"segment.anonymousId");
}

- (NSURL *)traitsURL {
    return SEGAnalyticsURLForFilename(@"segmentio.traits.plist");
}

@end
