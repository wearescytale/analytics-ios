//
//  SEGUser.h
//  Analytics
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGUser.h"
#import "SEGStorage.h"

@interface SEGUser (Internal)

- (instancetype)initWithStorage:(id<SEGStorage>)storage;

- (void)addTraits:(NSDictionary *)traits;
- (void)reset;

@end
