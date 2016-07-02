//
//  SEGNetworkTransporter.h
//  Analytics
//
//  Created by Tony Xiao on 6/24/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGNetworkTransporter : NSObject

@property (nonnull, nonatomic, strong) NSURL *apiURL;
@property (nonnull, nonatomic, strong) NSString *writeKey;
@property (nonatomic, assign) NSInteger flushAt;
@property (nonatomic, assign) NSInteger batchSize;
@property (nonnull, nonatomic, readonly) NSURL *cacheURL;

- (instancetype _Nonnull)initWithWriteKey:(NSString * _Nonnull)writeKey flushAfter:(NSTimeInterval)flushAfter;

- (void)queuePayload:(NSDictionary * _Nonnull)payload;
- (void)flush:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)reset;

@end
