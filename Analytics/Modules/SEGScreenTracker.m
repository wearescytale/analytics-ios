#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Analytics.h"
#import "SEGUtils.h"
#import "SEGScreenTracker.h"

static NSString *SEGViewDidAppearNotification = @"SEGViewDidAppearNotification";

@interface UIViewController (SEGScreenTracker)
@end

@implementation UIViewController (SEGScreenTracker)

- (void)seg_viewDidAppear:(BOOL)animated {
    [self seg_viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEGViewDidAppearNotification object:self];
}

@end

@interface SEGScreenTracker ()

@property (nonnull, nonatomic, strong) SEGAnalytics *analytics;

- (void)handleViewDidAppear:(NSNotification *)notification;

@end

@implementation SEGScreenTracker

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        _analytics = analytics;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleViewDidAppear:)
                                                     name:SEGViewDidAppearNotification
                                                   object:nil];
        [[self class] swizzleViewDidAppearIfNeeded];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleViewDidAppear:(NSNotification *)notification {
    UIViewController *top = [self topViewController];
    if (!top) {
        return;
    }
    
    NSString *name = [top title];
    if (name.length == 0) {
        name = [[[top class] description] stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
        // Class name could be just "ViewController".
        if (name.length == 0) {
            SEGLog(@"Could not infer screen name.");
            name = @"Unknown";
        }
    }
    [[SEGAnalytics sharedAnalytics] screen:name properties:nil options:nil];
}

- (UIViewController *)topViewController {
    UIViewController *root = [UIApplication sharedApplication].delegate.window.rootViewController;
    return [self topViewController:root];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

+ (void)swizzleViewDidAppearIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [UIViewController class];
        
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(seg_viewDidAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

@end
