//
//  SEGIntegrationsManager.m
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGIntegrationsManager.h"

@implementation SEGIntegrationsManager

- (void)eachIntegration:(void (^_Nonnull)(id<SEGIntegration> integration))block {
    for (id<SEGIntegration> integration in self.integrationsByKey.allValues) {
        block(integration);
    }
}

@end

@implementation SEGIntegrationsManager (SEGIntegration)

- (void)identify:(SEGIdentifyPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration identify:payload];
    }];
}

- (void)track:(SEGTrackPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration track:payload];
    }];
}

- (void)screen:(SEGScreenPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration screen:payload];
    }];
}

- (void)group:(SEGGroupPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration group:payload];
    }];
}

- (void)alias:(SEGAliasPayload *)payload {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration alias:payload];
    }];
}

- (void)reset {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration reset];
    }];
}

- (void)flush {
    [self eachIntegration:^(id<SEGIntegration> integration) {
        [integration flush];
    }];
}

@end