//
//  SEGAnalytics+Convenience.m
//  Analytics
//
//  Created by Tony Xiao on 6/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGAnalytics+Convenience.h"

static SEGAnalytics *__sharedAnalytics = nil;

@implementation SEGAnalytics (Convenience)

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits options:nil];
}

- (void)track:(NSString *)event {
    [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties options:nil];
}

- (void)group:(NSString *)groupId {
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    [self group:groupId traits:traits options:nil];
}

- (void)alias:(NSString *)newId {
    [self alias:newId options:nil];
}

+ (void)identify:(NSString *)userId {
    [[self sharedAnalytics] identify:userId traits:nil options:nil];
}

+ (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [[self sharedAnalytics] identify:userId traits:traits options:nil];
}

+ (void)track:(NSString *)event {
    [[self sharedAnalytics] track:event properties:nil options:nil];
}

+ (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [[self sharedAnalytics] track:event properties:properties options:nil];
}

+ (void)screen:(NSString *)screenTitle {
    [[self sharedAnalytics] screen:screenTitle properties:nil options:nil];
}

+ (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [[self sharedAnalytics] screen:screenTitle properties:properties options:nil];
}

+ (void)group:(NSString *)groupId {
    [[self sharedAnalytics] group:groupId traits:nil options:nil];
}

+ (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    [[self sharedAnalytics] group:groupId traits:traits options:nil];
}

+ (void)alias:(NSString *)newId {
    [[self sharedAnalytics] alias:newId options:nil];
}

+ (void)flush {
    [[self sharedAnalytics] flush];
}

+ (void)reset {
    [[self sharedAnalytics] reset];
}

+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedAnalytics = [[self alloc] initWithConfiguration:configuration];
    });
}

+ (void)setupWithWriteKey:(NSString *)writeKey {
    [self setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:writeKey]];
}

+ (instancetype)sharedAnalytics {
    NSCParameterAssert(__sharedAnalytics != nil);
    return __sharedAnalytics;
}

@end