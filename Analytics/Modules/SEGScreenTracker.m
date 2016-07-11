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
    UIViewController *top = [self topViewController] ?: [self topViewController:notification.object];
    if (!top) {
        return;
    }
    NSString *name = [top title] ?: [self inferScreenTitle:top];
    [self.analytics screen:name properties:nil options:nil];
}

- (NSString *)inferScreenTitle:(UIViewController *)vc {
    NSString *className = [[vc class] description];
    if ([className isEqualToString:@"ViewController"]) {
        return @"ViewController";
    } else if ([className containsString:@"ViewController"]) {
        return [className stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
    } else if ([className containsString:@"Controller"]) {
        return [className stringByReplacingOccurrencesOfString:@"Controller" withString:@""];
    }
    SEGLog(@"Could not infer screen name. Try specifying a title for %@", vc);
    return @"Unknown";
}

- (UIViewController *)topViewController {
    UIViewController *root = [UIApplication sharedApplication].delegate.window.rootViewController;
    return [self topViewController:root];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        if ([rootViewController isKindOfClass:[UITabBarController class]]) {
            return [self topViewController:[(UITabBarController *)rootViewController selectedViewController]];
        }
        if ([rootViewController isKindOfClass:[UINavigationController class]]) {
            return [self topViewController:[(UINavigationController *)rootViewController topViewController]];
        }
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
