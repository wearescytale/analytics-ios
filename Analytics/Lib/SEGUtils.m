//
//  SEGUtils.m
//  Analytics
//
//  Created on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <sys/sysctl.h>
#import "SEGAnalyticsUtils.h"
#import "SEGUtils.h"

@implementation SEGUtils

+ (NSError *)errorFromException:(NSException *)exception {
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    [info setValue:exception.name forKey:@"ExceptionName"];
    [info setValue:exception.reason forKey:@"ExceptionReason"];
    [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
    [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
    [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
    
    return [[NSError alloc] initWithDomain:@"NSException" code:0 userInfo:info];
}

+ (NSData *)encodeJSON:(id)jsonObject error:(NSError *__autoreleasing *)error {
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:error];
    } @catch (NSException *exc) {
        *error = [self errorFromException:exc];
    }
    if (error) {
        SEGLog(@"Error serializing JSON: %@", error);
    }
    return data;
}

+ (NSURL * _Nonnull)urlForName:(NSString * _Nonnull)name writeKey:(NSString * _Nonnull)writeKey extension:(NSString * _Nonnull)extension {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportPath = [paths firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:supportPath
                                              isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:supportPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            SEGLog(@"error: %@", error.localizedDescription);
        }
    }
    NSString *filename = [NSString stringWithFormat:@"%@-%@.%@", name, writeKey, extension];
    return [[NSURL alloc] initFileURLWithPath:[supportPath stringByAppendingPathComponent:filename]];
}

+ (NSString *)convertPushTokenToString:(NSData *)pushToken {
    const unsigned char *buffer = (const unsigned char *)[pushToken bytes];
    if (!buffer) {
        return nil;
    }
    NSMutableString *token = [NSMutableString stringWithCapacity:(pushToken.length * 2)];
    for (NSUInteger i = 0; i < pushToken.length; i++) {
        [token appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    return token;
}

+ (NSString *)generateUUIDString {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return UUIDString;
}

+ (NSString *)getDeviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char result[size];
    sysctlbyname("hw.machine", result, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    return results;
}

+ (BOOL)getAdTrackingEnabled {
    BOOL result = NO;
    Class advertisingManager = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    id sharedManager = ((id (*)(id, SEL))[advertisingManager methodForSelector:sharedManagerSelector])(advertisingManager, sharedManagerSelector);
    SEL adTrackingEnabledSEL = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
    result = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:adTrackingEnabledSEL])(sharedManager, adTrackingEnabledSEL);
    return result;
}

@end
