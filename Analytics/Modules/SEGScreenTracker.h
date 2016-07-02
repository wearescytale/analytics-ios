#import <Foundation/Foundation.h>
#import "SEGAnalytics.h"

@interface SEGScreenTracker : NSObject

@property (nonnull, nonatomic, readonly) SEGAnalytics *analytics;

- (instancetype _Nonnull)initWithAnalytics:(SEGAnalytics * _Nonnull)analytics;

@end
