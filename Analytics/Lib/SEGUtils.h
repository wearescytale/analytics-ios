//
//  SEGUtils.h
//  Analytics
//
//  Created on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGUtils : NSObject

+ (NSData * _Nullable)encodeJSON:(id _Nonnull)jsonObject error:(NSError * __autoreleasing _Nullable * _Nullable)error;
+ (NSURL * _Nonnull)urlForName:(NSString * _Nonnull)name writeKey:(NSString * _Nonnull)writeKey extension:(NSString * _Nonnull)extension;
+ (NSString * _Nonnull)convertPushTokenToString:(NSData * _Nonnull)pushToken;
+ (NSString * _Nonnull)generateUUIDString;
+ (NSString * _Nonnull)getDeviceModel;
+ (BOOL)getAdTrackingEnabled;

@end


NSURL *SEGAnalyticsURLForFilename(NSString *filename);

// Date Utils
NSString *iso8601FormattedString(NSDate *date);

// Logging

void SEGSetShowDebugLogs(BOOL showDebugLogs);
void SEGLog(NSString *format, ...);

// JSON Utils

NSDictionary *SEGCoerceDictionary(NSDictionary *dict);

NSString *SEGIDFA(void);

NSString *SEGEventNameForScreenTitle(NSString *title);