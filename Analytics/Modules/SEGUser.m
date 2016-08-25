//
//  SEGUser.m
//  Analytics
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGUser.h"
#import "SEGUser+Internal.h"
#import "SEGUtils.h"

NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";

NSString *const kSEGAnonymousIdFilename = @"segment.anonymousId";
NSString *const kSEGUserIdFilename = @"segmentio.userId";
NSString *const kSEGTraitsFilename = @"segmentio.traits.plist";

@interface SEGUser ()

@property (nonatomic, strong) NSMutableDictionary *traits;
@property (nonatomic, strong) NSUserDefaults *ud;
@property (nonatomic, strong) NSFileManager *fm;
@property (nonnull, nonatomic, readonly) id<SEGStorage>storage;

@end

@implementation SEGUser {
    NSString *_anonymousId;
    NSString *_userId;
}

- (NSString *)anonymousId {
    if (!_anonymousId) {
        _anonymousId = [self.ud valueForKey:SEGAnonymousIdKey] ?: [self.storage stringForKey:kSEGAnonymousIdFilename];
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
    [self.storage setString:anonymousId forKey:kSEGAnonymousIdFilename];
}

- (NSString *)userId {
    if (!_userId) {
        _userId =  [self.ud valueForKey:SEGUserIdKey] ?: [self.storage stringForKey:kSEGUserIdFilename];
    }
    return _userId;
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    [self.ud setValue:userId forKey:SEGUserIdKey];
    [self.storage setString:userId forKey:kSEGUserIdFilename];
}

- (NSMutableDictionary *)traits {
    if (!_traits) {
        _traits = [[self.storage dictionaryForKey:kSEGTraitsFilename] mutableCopy];
    }
    return _traits;
}

@end

@implementation SEGUser (Internal)

- (instancetype)initWithStorage:(id<SEGStorage>)storage {
    if (self = [super init]) {
        _ud = [NSUserDefaults standardUserDefaults];
        _fm = [NSFileManager defaultManager];
        _storage = storage;
    }
    return self;
}

- (void)addTraits:(NSDictionary *)traits {
    // Better way around the compiler check here?
    [(NSMutableDictionary *)self.traits addEntriesFromDictionary:traits];
    [self.storage setDictionary:[self.traits copy] forKey:@"segmentio.traits.plist"];
}

- (void)reset {
    self.userId = nil;
    self.anonymousId = nil;
    self.traits = nil;
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGUserIdKey];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:SEGAnonymousIdKey];
    [self.storage removeKey:kSEGAnonymousIdFilename];
    [self.storage removeKey:kSEGUserIdFilename];
    [self.storage removeKey:kSEGTraitsFilename];
    
    // TODO: Is generation of new ID actually desired?
    self.anonymousId = [SEGUtils generateUUIDString];
}

@end
