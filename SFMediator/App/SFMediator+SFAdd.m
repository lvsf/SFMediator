//
//  SFMediator+SFAdd.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator+SFAdd.h"

@implementation SFMediator (SFAdd)

+ (id<AppProtocol>)app {
    return [self invokeTargetWithProtocol:@protocol(AppProtocol)
                            forwardTarget:nil];
}

+ (id<CommonProtocol>)common {
    return [self invokeTargetWithProtocol:@protocol(CommonProtocol)
                            forwardTarget:nil];
}

@end
