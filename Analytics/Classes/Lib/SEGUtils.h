//
//  SEGUtils.h
//  Analytics
//
//  Created on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGUtils : NSObject

+ (NSString *)generateUUIDString;
+ (NSString *)getDeviceModel;
+ (BOOL)getAdTrackingEnabled;

@end
