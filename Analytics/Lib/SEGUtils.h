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

// Async Utils
dispatch_queue_t seg_dispatch_queue_create_specific(const char *label,
                                                    dispatch_queue_attr_t attr);
BOOL seg_dispatch_is_on_specific_queue(dispatch_queue_t queue);
void seg_dispatch_specific(dispatch_queue_t queue, dispatch_block_t block,
                           BOOL waitForCompletion);
void seg_dispatch_specific_async(dispatch_queue_t queue,
                                 dispatch_block_t block);
void seg_dispatch_specific_sync(dispatch_queue_t queue, dispatch_block_t block);

// Logging

void SEGSetShowDebugLogs(BOOL showDebugLogs);
void SEGLog(NSString *format, ...);

// JSON Utils

NSDictionary *SEGCoerceDictionary(NSDictionary *dict);

NSString *SEGIDFA(void);

NSString *SEGEventNameForScreenTitle(NSString *title);