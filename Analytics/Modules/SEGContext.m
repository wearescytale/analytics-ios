//
//  SEGContext.m
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGContext.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "SEGUtils.h"
#import "SEGAnalytics.h"
#import "SEGHTTPRequest.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGBluetooth.h"
#import "SEGReachability.h"
#import "SEGAdSupport.h"
#import "SEGLocation.h"

@interface SEGContext ()

@property (nonatomic, strong) SEGBluetooth *bluetooth;
@property (nonatomic, strong) SEGReachability *reachability;
@property (nonatomic, strong) SEGLocation *location;

@end

@implementation SEGContext

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        _bluetooth = [[SEGBluetooth alloc] init];
        _reachability = [SEGReachability reachabilityWithHostname:@"google.com"];
        [_reachability startNotifier];
    }
    return self;
}


/*
 * There is an iOS bug that causes instances of the CTTelephonyNetworkInfo class to
 * sometimes get notifications after they have been deallocated.
 * Instead of instantiating, using, and releasing instances you * must instead retain
 * and never release them to work around the bug.
 *
 * Ref: http://stackoverflow.com/questions/14238586/coretelephony-crash
 */

static CTTelephonyNetworkInfo *_telephonyNetworkInfo;

- (NSDictionary *)staticContext {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"library"] = @{
        @"name" : @"analytics-ios",
        @"version" : [SEGAnalytics version]
    };

    NSMutableDictionary *infoDictionary = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoDictionary addEntriesFromDictionary:[[NSBundle mainBundle] localizedInfoDictionary]];
    if (infoDictionary.count) {
        dict[@"app"] = @{
            @"name" : infoDictionary[@"CFBundleDisplayName"] ?: @"",
            @"version" : infoDictionary[@"CFBundleShortVersionString"] ?: @"",
            @"build" : infoDictionary[@"CFBundleVersion"] ?: @"",
            @"namespace" : [[NSBundle mainBundle] bundleIdentifier] ?: @"",
        };
    }
    
    UIDevice *device = [UIDevice currentDevice];
    
    dict[@"device"] = ({
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"manufacturer"] = @"Apple";
        dict[@"model"] = [SEGUtils getDeviceModel];
        dict[@"id"] = [[device identifierForVendor] UUIDString];
        if ([SEGAdSupport adSupportFrameworkLinked]) {
            dict[@"adTrackingEnabled"] = @([SEGAdSupport getAdTrackingEnabled]);
        }
        if (self.configuration.enableAdvertisingTracking) {
            NSString *idfa = [SEGAdSupport getIdentifierForAdvertiser];
            if (idfa.length) dict[@"advertisingId"] = idfa;
        }
        // TODO: This is not exactly static...
        if (self.pushToken) {
            dict[@"token"] = self.pushToken;
        }
        dict;
    });
    
    dict[@"os"] = @{
        @"name" : device.systemName,
        @"version" : device.systemVersion
    };
    
    static dispatch_once_t networkInfoOnceToken;
    dispatch_once(&networkInfoOnceToken, ^{
        _telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    
    CTCarrier *carrier = [_telephonyNetworkInfo subscriberCellularProvider];
    if (carrier.carrierName.length)
        dict[@"network"] = @{ @"carrier" : carrier.carrierName };
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    dict[@"screen"] = @{
        @"width" : @(screenSize.width),
        @"height" : @(screenSize.height)
    };
    
    if ([SEGAdSupport isReferredByIAd]) {
        dict[@"referrer"] = @{ @"type" : @"iad" };
    }
    return dict;
}

- (NSDictionary *)contextForTraits:(NSDictionary *)traits {
    NSMutableDictionary *context = [[self staticContext] mutableCopy];
    
    context[@"locale"] = [NSString stringWithFormat:@"%@-%@",
                          [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode],
                          [NSLocale.currentLocale objectForKey:NSLocaleCountryCode]];
    
    context[@"timezone"] = [[NSTimeZone localTimeZone] name];
    
    context[@"network"] = ({
        NSMutableDictionary *network = [[NSMutableDictionary alloc] init];
        
        if (self.bluetooth.hasKnownState)
            network[@"bluetooth"] = @(self.bluetooth.isEnabled);
        
        if (self.reachability.isReachable) {
            network[@"wifi"] = @(self.reachability.isReachableViaWiFi);
            network[@"cellular"] = @(self.reachability.isReachableViaWWAN);
        }
        
        network;
    });
    
    self.location = !self.location ? [self.configuration shouldUseLocationServices] ? [SEGLocation new] : nil : self.location;
    [self.location startUpdatingLocation];
    if (self.location.hasKnownLocation)
        context[@"location"] = self.location.locationDictionary;
    
    context[@"traits"] = ({
        NSMutableDictionary *mutableTraits = [[NSMutableDictionary alloc] initWithDictionary:traits];
        
        if (self.location.hasKnownLocation)
            mutableTraits[@"address"] = self.location.addressDictionary;
        
        mutableTraits;
    });
    
    return [context copy];
}

@end
