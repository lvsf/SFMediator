//
//  UIApplication+SFMediator.h
//  SFProject
//
//  Created by YunSL on 2018/3/23.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFApplicationMultipleProxy.h"

@interface UIApplication (SFMediator)
@property (nonatomic,strong,readonly) SFApplicationMultipleProxy<UIApplicationDelegate> *lv_multipleProxy;
@end
