//
//  SEGNetworkTransporter.m
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSData+GZIP.h"
#import "SEGUtils.h"
#import "SEGHTTPRequest.h"
#import "SEGNetworkTransporter.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGDispatchQueue.h"


NSString *const SEGSegmentDidSendRequestNotification = @"SegmentDidSendRequest";
NSString *const SEGSegmentRequestDidSucceedNotification = @"SegmentRequestDidSucceed";
NSString *const SEGSegmentRequestDidFailNotification = @"SegmentRequestDidFail";

@interface SEGNetworkTransporter ()

@property (nonnull, nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) SEGHTTPRequest *request;
@property (nonnull, nonatomic, strong) NSTimer *flushTimer;
@property (nonnull, nonatomic, strong) dispatch_source_t writeToDiskSource;
@property (nonnull, nonatomic, strong) SEGDispatchQueue *dispatchQueue;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundFlushTaskID;

@end

@implementation SEGNetworkTransporter

- (instancetype)initWithWriteKey:(NSString *)writeKey flushAfter:(NSTimeInterval)flushAfter {
    if (self = [super init]) {
        _apiURL = [NSURL URLWithString:@"https://api.segment.io/v1/import"];
        _writeKey = writeKey;
        _flushAt = 20;
        _batchSize = 100;
        _flushTimer = [NSTimer scheduledTimerWithTimeInterval:flushAfter target:self
                                                     selector:@selector(flushInBackground) userInfo:nil repeats:YES];
        _queue = [NSMutableArray arrayWithContentsOfURL:self.cacheURL] ?: [[NSMutableArray alloc] init];
        _backgroundFlushTaskID = UIBackgroundTaskInvalid;
        _dispatchQueue = [[SEGDispatchQueue alloc] initWithLabel:@"com.segment.transporter"];
        _writeToDiskSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _dispatchQueue.queue);
        
        __weak SEGNetworkTransporter *this = self;
        dispatch_source_set_event_handler(_writeToDiskSource, ^{
            [this writeToDisk];
        });
        dispatch_resume(_writeToDiskSource);
        
        // Flush task when we enter background
        // TODO: Figure
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(flushInBackground)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];
        [nc addObserver:self selector:@selector(applicationWillTerminate)
                   name:UIApplicationWillTerminateNotification object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSURL *)cacheURL {
    return [SEGUtils urlForName:@"segment.transporter.queue" writeKey:self.writeKey extension:@"plist"];
}

- (void)writeToDisk {
    SEGLog(@"Will Write to Disk and Flush queueLength=%ld", self.queue.count);
    @try {
        [[self.queue copy] writeToURL:self.cacheURL atomically:YES];
    } @catch (NSException *exception) {
        SEGLog(@"%@ Error writing payload: %@", self, exception);
    }
}

- (void)setNeedsWriteToDisk {
  dispatch_source_merge_data(self.writeToDiskSource, 1);
}

- (void)notifyOnMainQueue:(NSString *)name userInfo:(id)userInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
        SEGLog(@"sent notification %@", name);
    });
}

- (void)queuePayload:(NSDictionary *)payload {
    [self.dispatchQueue async:^{
        [self.queue addObject:payload];
        [self setNeedsWriteToDisk];
        SEGLog(@"%@ Length is %lu.", self, self.queue.count);
        if (self.request == nil && self.queue.count >= self.flushAt) {
            [self flush:nil];
        }
    }];
}

- (void)flush:(void (^ _Nullable)(NSError * _Nullable error))completion {
    completion = [completion copy];
    [self.dispatchQueue async:^{
        if (self.queue.count == 0) {
            if (completion) {
                completion(nil);
            }

            SEGLog(@"%@ No queued API calls to flush.", self);
            return;
        }
        if (self.request != nil) {
            completion ?: completion(nil);
            SEGLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        NSArray *batch = self.queue.count >= self.batchSize
            ? [self.queue subarrayWithRange:NSMakeRange(0, self.batchSize)] : [self.queue copy];
        
        NSDictionary *payload = @{
            @"sentAt": iso8601FormattedString([NSDate date]),
            @"writeKey": self.writeKey ?: [NSNull null],
            @"batch": batch
        };
        SEGLog(@"%@ Flushing %lu of %lu queued API calls. Payload %@", self, batch.count, self.queue.count, payload);
        
        NSError *error = nil;
        NSData *data = [SEGUtils encodeJSON:payload error:&error];
        if (!data.length) {
            SEGLog(@"No data to send. Returning");
            completion ?: completion(error);
            return;
        }
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.apiURL];
        urlRequest.HTTPMethod = @"POST";
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setHTTPBody:[data seg_gzippedData]];
        
        SEGLog(@"%@ Sending batch API request.", self);
        self.request = [SEGHTTPRequest startWithURLRequest:urlRequest
                                                     completion:^{
            [self.dispatchQueue async:^{
                if (self.request.error) {
                    SEGLog(@"%@ API request had an error: %@", self, self.request.error);
                    [self notifyOnMainQueue:SEGSegmentRequestDidFailNotification userInfo:batch];
                    completion ?: completion(self.request.error);
                    self.request = nil;
                } else {
                    SEGLog(@"%@ API request success 200", self);
                    [self.queue removeObjectsInArray:batch];
                    [self setNeedsWriteToDisk];
                    [self notifyOnMainQueue:SEGSegmentRequestDidSucceedNotification userInfo:batch];
                    self.request = nil;
                    [self flush:completion];
                }
            }];
        }];
        [self notifyOnMainQueue:SEGSegmentDidSendRequestNotification userInfo:batch];
    }];
}

- (void)reset {
    [self.dispatchQueue sync:^{
        [[NSFileManager defaultManager] removeItemAtURL:self.cacheURL error:NULL];
        self.queue = [NSMutableArray array];
        self.request.completion = nil;
        self.request = nil;
    }];
}

- (void)flushInBackground {
    // TODO: This won't work if at the time we enter background we happen to have an inflight request.
    // Figure out better way to accomplish this.
    void (^endBackgroundTask)(void) = ^void(void) {
        if (self.backgroundFlushTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundFlushTaskID];
            self.backgroundFlushTaskID = UIBackgroundTaskInvalid;
        }
    };
    [self.dispatchQueue sync:^{
        endBackgroundTask();
        self.backgroundFlushTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            endBackgroundTask();
        }];
        [self flush:^(NSError * _Nullable error) {
            endBackgroundTask();
        }];
    }];
}

- (void)applicationWillTerminate {
    [self.dispatchQueue sync:^{
        [self writeToDisk];
    }];
}

@end
