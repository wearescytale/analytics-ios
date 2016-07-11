//
//  SEGUser.h
//  Analytics
//
//  Created by Tony Xiao on 6/27/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGUser : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *anonymousId;
@property (nonatomic, readonly) NSDictionary *traits;

@end
