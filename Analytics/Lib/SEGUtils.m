//
//  SEGUtils.m
//  Analytics
//
//  Created on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <sys/sysctl.h>
#import "SEGUtils.h"

// Logging
static BOOL kAnalyticsLoggerShowLogs = NO;

void SEGSetShowDebugLogs(BOOL showDebugLogs) {
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void SEGLog(NSString *format, ...) {
    if (!kAnalyticsLoggerShowLogs)
        return;
    
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

@implementation SEGUtils

+ (NSError *)_errorFromException:(NSException *)exception {
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    [info setValue:exception.name forKey:@"ExceptionName"];
    [info setValue:exception.reason forKey:@"ExceptionReason"];
    [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
    [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
    [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
    
    return [[NSError alloc] initWithDomain:@"NSException" code:0 userInfo:info];
}

+ (id)_coerceJSONObject:(id)obj {
    // if the object is a NSString, NSNumber or NSNull
    // then we're good
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id i in obj)
            [array addObject:[self _coerceJSONObject:i]];
        return array;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in obj) {
            if (![key isKindOfClass:[NSString class]])
                SEGLog(@"warning: dictionary keys should be strings. got: %@. coercing "
                       @"to: %@",
                       [key class], [key description]);
            dict[key.description] = [self _coerceJSONObject:obj[key]];
        }
        return dict;
    }
    
    if ([obj isKindOfClass:[NSDate class]])
        return [self formatISO8601:obj];
    
    if ([obj isKindOfClass:[NSURL class]])
        return [obj absoluteString];
    
    // default to sending the object's description
    SEGLog(@"warning: dictionary values should be valid json types. got: %@. "
           @"coercing to: %@",
           [obj class], [obj description]);
    return [obj description];
}

+ (NSDictionary *)coerceDictionary:(NSDictionary *)dict {
    // make sure that a new dictionary exists even if the input is null
    dict = dict ?: @{};
    // assert that the proper types are in the dictionary
    assert([dict isKindOfClass:[NSDictionary class]]);
    for (id key in dict) {
        assert([key isKindOfClass:[NSString class]]);
        id value = dict[key];
        assert([value isKindOfClass:[NSString class]] ||
               [value isKindOfClass:[NSNumber class]] ||
               [value isKindOfClass:[NSNull class]] ||
               [value isKindOfClass:[NSArray class]] ||
               [value isKindOfClass:[NSDictionary class]] ||
               [value isKindOfClass:[NSDate class]] ||
               [value isKindOfClass:[NSURL class]]);
    }
    
    // coerce urls, and dates to the proper format
    return [self _coerceJSONObject:dict];
}

+ (NSData *)encodeJSON:(id)jsonObject error:(NSError *__autoreleasing *)error {
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:error];
    } @catch (NSException *exc) {
        *error = [self _errorFromException:exc];
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

+ (NSString *)formatISO8601:(NSDate *)date {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    });
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)getDeviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char result[size];
    sysctlbyname("hw.machine", result, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    return results;
}

@end

NSURL *SEGAnalyticsURLForFilename(NSString *filename) {
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
    return [[NSURL alloc] initFileURLWithPath:[supportPath stringByAppendingPathComponent:filename]];
}
