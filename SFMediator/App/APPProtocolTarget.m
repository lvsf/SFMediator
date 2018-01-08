//
//  AppProtocolTarget.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "AppProtocolTarget.h"
#import "ViewController.h"

@implementation AppProtocolTarget

- (UISwitch *)rootSwitch {
    return [UISwitch new];
}

- (UIViewController *)rootViewControllerWithText:(NSString *)text count:(NSInteger)count number:(CGFloat)number model:(id)model enable:(BOOL)enable {
    ViewController *rootViewController = [ViewController new];
    NSLog(@"SEL:%@ text:%@ count:%@ number:%@ model:%@ enable:%@",NSStringFromSelector(_cmd),text,@(count),@(number),model,@(enable));
    return rootViewController;
}

@end
