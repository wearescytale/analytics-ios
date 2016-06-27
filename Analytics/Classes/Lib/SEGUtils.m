//
//  SEGUtils.m
//  Analytics
//
//  Created on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <sys/sysctl.h>
#import "SEGUtils.h"

@implementation SEGUtils

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
