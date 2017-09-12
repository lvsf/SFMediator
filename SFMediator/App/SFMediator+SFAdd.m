//
//  SFMediator+SFAdd.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator+SFAdd.h"

SFForwardTargetBegin(App)

- (void)printCurrentDate {
    NSLog(@"date:%@",[NSDate date]);
}

SFForwardTargetEnd()

@implementation SFMediator (SFAdd)

+ (id<AppProtocol>)app {
    return [self invokeTargetWithProtocol:@protocol(AppProtocol) forwardTarget:[AppForwardTarget new]];
}

@end
