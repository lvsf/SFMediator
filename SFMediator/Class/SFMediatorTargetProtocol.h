//
//  SFMediatorTargetProtocol.h
//  QuanYou
//
//  Created by YunSL on 2018/8/11.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol SFMediatorTargetProtocol <UIApplicationDelegate>
@property (nonatomic,assign) BOOL respondToApplicationDelegate;
@optional
//不主动响应的UIApplicationDelegate方法以方便手动处理决定返回结果
- (NSArray<NSString *> *)ingoreApplicationDelegateSelectorName;
@end
