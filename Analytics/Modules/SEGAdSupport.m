//
//  SEGAdSupport.m
//  Analytics
//
//  Created by Tony Xiao on 7/2/16.
//  Copyright © 2016 Segment. All rights reserved.
//

//#import <AdSupport/AdSupport.h>
#import "SEGAdSupport.h"

static NSString *const SEGAdvertisingClassIdentifier = @"ASIdentifierManager";
static NSString *const SEGADClientClass = @"ADClient";

@implementation SEGAdSupport

#pragma mark - Ad Support

+ (id _Nullable)_sharedASIdentifierManager {
    Class identifierManager = NSClassFromString(SEGAdvertisingClassIdentifier);
    if (identifierManager) {
        SEL selector = NSSelectorFromString(@"sharedManager");
        IMP method = [identifierManager methodForSelector:selector];
        return ((id (*)(id, SEL))method)(identifierManager, selector);
    }
    return nil;
}

+ (BOOL)adSupportFrameworkLinked {
    return [self _sharedASIdentifierManager] != nil;
}

+ (NSString *)getIdentifierForAdvertiser {
    id manager = [self _sharedASIdentifierManager];
    if (manager) {
        SEL selector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID * (*)(id, SEL))[manager methodForSelector:selector])(manager, selector);
        return [uuid UUIDString];
    }
    return nil;
}

+ (BOOL)getAdTrackingEnabled {
    id manager = [self _sharedASIdentifierManager];
    if (manager) {
        SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        return ((BOOL (*)(id, SEL))[manager methodForSelector:selector])(manager, selector);
    }
    return NO;
}


#pragma mark - iAd

+ (id _Nullable)_sharedAdClient {
    Class adClient = NSClassFromString(SEGADClientClass);
    if (adClient) {
        SEL selector = NSSelectorFromString(@"sharedClient");
        IMP method = [adClient methodForSelector:selector];
        return ((id (*)(id, SEL))method)(adClient, selector);
    }
    return nil;
}

+ (BOOL)isReferredByIAd {
    __block BOOL isReferredByIAd = NO;
    id adClient = [self _sharedAdClient];
    if (adClient) {
        SEL selector = NSSelectorFromString(@"determineAppInstallationAttributionWithCompletionHandler:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [adClient performSelector:selector withObject:^(BOOL iad) {
            isReferredByIAd = iad;
        }];
#pragma clang diagnostic pop
    }
    return isReferredByIAd;
}

@end
