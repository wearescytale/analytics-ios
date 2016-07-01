//
//  SEGDispatchQueue.m
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGDispatchQueue.h"

@interface SEGDispatchQueue ()

@property (nonnull, nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SEGDispatchQueue

- (instancetype)initWithLabel:(NSString *)label {
    if (self = [super init]) {
        _queue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_queue, (__bridge const void *)_queue,
                                    (__bridge void *)_queue, NULL);
    }
    return self;
}

- (BOOL)isCurrentQueue {
    return dispatch_get_specific((__bridge const void *)self.queue) != NULL;
}

- (void)dispatch:(dispatch_block_t)block waitForCompletion:(BOOL)waitForCompletion {
    if (dispatch_get_specific((__bridge const void *)self.queue)) {
        block();
    } else if (waitForCompletion) {
        dispatch_sync(self.queue, block);
    } else {
        dispatch_async(self.queue, block);
    }
}

- (void)async:(dispatch_block_t)block {
    [self dispatch:block waitForCompletion:NO];
}

- (void)sync:(dispatch_block_t)block {
    [self dispatch:block waitForCompletion:YES];
}

@end
