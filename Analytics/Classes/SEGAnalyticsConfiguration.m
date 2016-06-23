//
//  SEGAnalyticsConfiguration.m
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGAnalyticsConfiguration.h"
#import "SEGSegmentIntegrationFactory.h"

@interface SEGAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;

@end


@implementation SEGAnalyticsConfiguration

- (instancetype)initWithWriteKey:(NSString *)writeKey {
    if (self = [self init]) {
        self.writeKey = writeKey;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.flushAt = 20;
        _factories = [NSMutableArray array];
        [_factories addObject:[SEGSegmentIntegrationFactory instance]];
    }
    return self;
}

- (void)use:(id<SEGIntegrationFactory>)factory {
    [self.factories addObject:factory];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self dictionaryWithValuesForKeys:@[ @"writeKey", @"shouldUseLocationServices", @"flushAt" ]]];
}

#pragma mark - Class Methods

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey {
    return [[SEGAnalyticsConfiguration alloc] initWithWriteKey:writeKey];
}

@end
