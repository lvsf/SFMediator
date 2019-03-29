//
//  SFMediator+Demo.m
//  SFMediator
//
//  Created by YunSL on 2019/3/29.
//  Copyright © 2019年 YunSL. All rights reserved.
//

#import "SFMediator+Demo.h"

@implementation SFMediator (Demo)

SFMediatorTargetImplementation(CommonProtocol, common)
SFMediatorTargetImplementation(AppProtocol, app)
SFMediatorTargetImplementation(UserProtocol, user)

@end
