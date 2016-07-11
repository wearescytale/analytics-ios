//
//  SEGAdSupport.h
//  Analytics
//
//  Created by Tony Xiao on 7/2/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEGAdSupport : NSObject

// AdSupport
+ (BOOL)adSupportFrameworkLinked;
+ (BOOL)getAdTrackingEnabled;
+ (NSString * _Nullable)getIdentifierForAdvertiser;

// iAd
+ (BOOL)isReferredByIAd;

@end
