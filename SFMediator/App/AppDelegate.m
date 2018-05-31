//
//  AppDelegate.m
//  SFMediator
//
//  Created by YunSL on 17/9/4.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SFMediator+SFAdd.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

+ (void)load {
    [SFMediator sharedInstance].takeoverApplicationDelegate = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
    [self.window setRootViewController:[ViewController new]];
    
    //配置SFMediator
    [SFMediator sharedInstance].parser.invocationURLSchemes = @[@"demo"];

    //本地调用,为了方便调用和参数检验项目依赖于各组件对应的协议,协议根据需求由开发者和使用者共同维护或者只由某一方维护
    [[SFMediator _AppProtocol] rootViewControllerWithText:@"root" count:10 number:3.1415926 model:[UISwitch new] enable:YES];

    //本地调用已声明但开发方尚未实现的方法
    [[SFMediator _AppProtocol] printCurrentDate];
    
    //本地调用,指定转发对象
    [[SFMediator _UserProtocol] vc_home];
    
    //远程调用,为了不定义各种参数key,暂时按严格的顺序传递和获取参数
    NSString *switchUrl = @"demo://app/rootSwitch";
    NSString *url = [NSString stringWithFormat:@"demo://app/rootViewControllerWithText:count:number:model:enable:?t=root&c=10&n=3.1415926&m=%@&e=1",switchUrl];
    [SFMediator openURL:url];
    
    //远程调用,参数为空
    [SFMediator openURL:@"demo://app/test:?a="];
    
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions");
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

//- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame  {
//    NSLog(@"[AppDelegate] didChangeStatusBarFrame");
//}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"[AppDelegate] applicationDidBecomeActive");
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
