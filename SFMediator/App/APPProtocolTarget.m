//
//  AppProtocolTarget.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "AppProtocolTarget.h"
#import "ViewController.h"
#import "SFMediator.h"

@implementation AppProtocolTarget
@synthesize respondToApplicationDelegate = _respondToApplicationDelegate;

- (UISwitch *)rootSwitch {
    return [UISwitch new];
}

- (id)test:(void (^)(void))a {
    if (a) {
        a();
        NSLog(@"==========%@",a);
    }
    return nil;
}

- (UIViewController *)rootViewControllerWithText:(NSString *)text count:(NSInteger)count number:(CGFloat)number model:(id)model enable:(BOOL)enable {
    ViewController *rootViewController = [ViewController new];
    NSLog(@"[AppProtocolTarget] SEL:%@ text:%@ count:%@ number:%@ model:%@ enable:%@",NSStringFromSelector(_cmd),text,@(count),@(number),model,@(enable));
    return rootViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[AppProtocolTarget] didFinishLaunchingWithOptions");
    return YES;
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame {
    NSLog(@"[AppProtocolTarget] didChangeStatusBarFrame:%@",NSStringFromCGRect(oldStatusBarFrame));
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"[AppProtocolTarget] applicationDidBecomeActive");
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    NSLog(@"[AppProtocolTarget] %@",NSStringFromSelector(_cmd));
    return UIInterfaceOrientationMaskAll;
}

- (NSArray<NSString *> *)ingoreApplicationDelegateSelectorName {
    return @[NSStringFromSelector(@selector(application:supportedInterfaceOrientationsForWindow:)),
             NSStringFromSelector(@selector(application:didChangeStatusBarFrame:))];
}

@end
