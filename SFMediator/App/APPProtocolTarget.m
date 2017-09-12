//
//  AppProtocolTarget.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "APPProtocolTarget.h"
#import "ViewController.h"

@implementation AppProtocolTarget

- (UIViewController *)rootViewControllerWithText:(NSString *)text count:(NSInteger)count number:(CGFloat)number model:(id)model enable:(BOOL)enable {
    ViewController *rootViewController = [ViewController new];
    NSLog(@"SEL:%@ text:%@ count:%@ number:%@ model:%@ enable:%@",NSStringFromSelector(_cmd),text,@(count),@(number),model,@(enable));
    return rootViewController;
}

@end