//
//  SFMediator+Demo.h
//  SFMediator
//
//  Created by YunSL on 2019/3/29.
//  Copyright © 2019年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import "CommonProtocol.h"
#import "AppProtocol.h"
#import "UserProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SFMediator (Demo)
SFMediatorTargetInterface(CommonProtocol, common)
SFMediatorTargetInterface(AppProtocol, app)
SFMediatorTargetInterface(UserProtocol, user)
@end

NS_ASSUME_NONNULL_END
