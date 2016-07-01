//
//  SEGDispatchQueue.h
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGDispatchQueue : NSObject

- (instancetype _Nonnull)initWithLabel:(NSString * _Nonnull)label;

- (BOOL)isCurrentQueue;
- (void)dispatch:(dispatch_block_t _Nonnull)block waitForCompletion:(BOOL)waitForCompletion;
- (void)async:(dispatch_block_t _Nonnull)block;
- (void)sync:(dispatch_block_t _Nonnull)block;

@end
