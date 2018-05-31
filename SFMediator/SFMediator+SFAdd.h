//
//  SFMediator+SFAdd.h
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import "AppProtocol.h"
#import "CommonProtocol.h"
#import "UserProtocol.h"

@interface SFMediator (SFAdd)
SFMediatorRegisterProtocol_H(AppProtocol)
SFMediatorRegisterProtocol_H(CommonProtocol)
SFMediatorRegisterProtocol_H(UserProtocol)
@end
