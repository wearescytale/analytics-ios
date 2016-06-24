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
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGNetworkTransporter.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGSegmentIntegration.h"

@interface SEGNetworkTransporter ()

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSDictionary *context;
@property (nonatomic, strong) NSArray *batch;
@property (nonatomic, strong) SEGAnalyticsRequest *request;
@property (nonatomic, assign) UIBackgroundTaskIdentifier flushTaskID;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation SEGNetworkTransporter

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        _apiURL = [NSURL URLWithString:@"https://api.segment.io/v1/import"];
        _flushTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(flush) userInfo:nil repeats:YES];
        _serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        _flushTaskID = UIBackgroundTaskInvalid;
        // Refresh setings upon entering foreground
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(flushInBackground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dispatchBackground:(void (^)(void))block {
    seg_dispatch_specific_async(self.serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block {
    seg_dispatch_specific_sync(self.serialQueue, block);
}

- (void)beginBackgroundTask {
    [self endBackgroundTask];
    
    self.flushTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [self dispatchBackgroundAndWait:^{
        if (self.flushTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.flushTaskID];
            self.flushTaskID = UIBackgroundTaskInvalid;
        }
    }];
}

- (NSURL *)queueURL {
    return SEGAnalyticsURLForFilename(@"segmentio.queue.plist");
}

- (void)queuePayload:(NSDictionary *)payload {
    @try {
        [self.queue addObject:payload];
        [[self.queue copy] writeToURL:[self queueURL] atomically:YES];
        [self flushQueueByLength];
        
    } @catch (NSException *exception) {
        SEGLog(@"%@ Error writing payload: %@", self, exception);
    }
}

- (void)flushInBackground {
    [self beginBackgroundTask];
    [self flush];
}

- (void)flush {
    [self flushWithMaxSize:self.maxBatchSize];
}

- (void)flushWithMaxSize:(NSUInteger)maxBatchSize {
    [self dispatchBackground:^{
        if ([self.queue count] == 0) {
            SEGLog(@"%@ No queued API calls to flush.", self);
            return;
        } else if (self.request != nil) {
            SEGLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        } else if ([self.queue count] >= maxBatchSize) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, maxBatchSize)];
        } else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }
        
        SEGLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)self.batch.count, (unsigned long)self.queue.count);
        
        NSMutableDictionary *payloadDictionary = [[NSMutableDictionary alloc] init];
        [payloadDictionary setObject:self.configuration.writeKey forKey:@"writeKey"];
        [payloadDictionary setObject:iso8601FormattedString([NSDate date]) forKey:@"sentAt"];
        [payloadDictionary setObject:self.context forKey:@"context"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        SEGLog(@"Flushing payload %@", payloadDictionary);
        
        NSError *error = nil;
        NSException *exception = nil;
        NSData *payload = nil;
        @try {
            payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary options:0 error:&error];
        }
        @catch (NSException *exc) {
            exception = exc;
        }
        if (error || exception) {
            SEGLog(@"%@ Error serializing JSON: %@", self, error);
        } else {
            [self sendData:payload];
        }
    }];
}

- (void)flushQueueByLength {
    [self dispatchBackground:^{
        SEGLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);
        if (self.request == nil && [self.queue count] >= self.configuration.flushAt) {
            [self flush];
        }
    }];
}

- (void)sendData:(NSData *)data {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.apiURL];
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[data seg_gzippedData]];
    
    SEGLog(@"%@ Sending batch API request.", self);
    self.request = [SEGAnalyticsRequest startWithURLRequest:urlRequest
                                                 completion:^{
        [self dispatchBackground:^{
            if (self.request.error) {
                SEGLog(@"%@ API request had an error: %@", self, self.request.error);
                [self notifyForName:SEGSegmentRequestDidFailNotification userInfo:self.batch];
            } else {
                SEGLog(@"%@ API request success 200", self);
                [self.queue removeObjectsInArray:self.batch];
                [[self.queue copy] writeToURL:[self queueURL] atomically:YES];
                [self notifyForName:SEGSegmentRequestDidSucceedNotification userInfo:self.batch];
            }

            self.batch = nil;
            self.request = nil;
            [self endBackgroundTask];
        }];
    }];
    [self notifyForName:SEGSegmentDidSendRequestNotification userInfo:self.batch];
}

- (void)notifyForName:(NSString *)name userInfo:(id)userInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
        SEGLog(@"sent notification %@", name);
    });
}

- (void)reset {
    [self dispatchBackgroundAndWait:^{
        [[NSFileManager defaultManager] removeItemAtURL:self.queueURL error:NULL];
        self.queue = [NSMutableArray array];
        self.request.completion = nil;
        self.request = nil;
    }];
}

- (NSUInteger)maxBatchSize {
    return 100;
}

@end
