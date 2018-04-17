//
//  SFMediator.h
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediatorParserProtocol.h"
#import "SFMediatorTargetProtocol.h"

#define SFMediatorRegisterTarget(x) \
+ (void)load {\
    [SFMediator invokeTargetWithProtocol:x forwardTarget:nil];\
}

@interface SFMediator : NSObject

/**
 解析对象
 */
@property (nonatomic,strong) id <SFMediatorParserProtocol> parser;

/**
 单例对象

 @return -
 */
+ (instancetype)sharedInstance;

/**
 是否能打开URL

 @param url -
 @return -
 */
+ (BOOL)canOpenURL:(NSString *)url;

/**
 打开URL//远程调用

 @param url -
 @return -
 */
+ (id)openURL:(NSString *)url;

/**
 获取调用对象//本地调用

 @param protocol       协议对象
 @param forwardTarget  转发对象
 @return -
 */
+ (id)invokeTargetWithProtocol:(Protocol *)protocol
                 forwardTarget:(id)forwardTarget;
@end
