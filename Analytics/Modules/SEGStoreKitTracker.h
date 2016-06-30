#import <Foundation/Foundation.h>
#import "Analytics.h"

@interface SEGStoreKitTracker : NSObject

+ (instancetype)trackTransactionsForAnalytics:(SEGAnalytics *)analytics;

@end