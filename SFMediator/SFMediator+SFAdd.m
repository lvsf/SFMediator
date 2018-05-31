//
//  SFMediator+SFAdd.m
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator+SFAdd.h"

@interface User_F : NSObject<UserProtocol>
@end
@implementation User_F

- (UIViewController *)vc_home {
    return [UIViewController new];
}

@end

@implementation SFMediator (SFAdd)
SFMediatorRegisterProtocol_M(AppProtocol)
SFMediatorRegisterProtocol_M(CommonProtocol)
SFMediatorRegisterProtocol_F_M([User_F new],UserProtocol)
@end
