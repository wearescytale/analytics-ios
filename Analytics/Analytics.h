//
//  Analytics.h
//  Analytics
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

/*
 The following two extern variables are disabled for now because Analytics.h can be used as static lib as well which would 
 not have the FOUNDATION_EXPORT variables be properly defined
//! Project version number for Analytics.
FOUNDATION_EXPORT double AnalyticsVersionNumber;

//! Project version string for Analytics.
FOUNDATION_EXPORT const unsigned char AnalyticsVersionString[];
*/
// In this header, you should import all the public headers of your framework using statements like #import <Analytics/PublicHeader.h>

#import "SEGAnalytics.h"
#import "SEGAnalytics+Convenience.h"
#import "SEGAnalyticsConfiguration.h"