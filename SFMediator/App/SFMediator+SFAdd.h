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

@interface SFMediator (SFAdd)
+ (id<AppProtocol>)app;
+ (id<CommonProtocol>)common;
@end
