//
//  SEGMigration.m
//  Analytics
//
//  Created by Tony Xiao on 6/26/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGMigration.h"

NSString *const SEGQueueKey = @"SEGQueue";
NSString *const SEGTraitsKey = @"SEGTraits";

@implementation SEGMigration

+ (void)migrateToLatest {
    // TODO: Migrate local files over
//    return SEGAnalyticsURLForFilename(@"segmentio.queue.plist");
    // Check for previous queue/track data in NSUserDefaults and remove if present
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGQueueKey]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGQueueKey];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGTraitsKey]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGTraitsKey];
    }

}

@end
