//
//  SFMediator.h
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediatorParserProtocol.h"
#import "SFMediatorTargetProtocol.h"
#import "SFMediatorError.h"

static inline BOOL SFMediatorShouldSwizzleSEL(SEL originalSEL) {
    return [NSStringFromSelector(originalSEL) hasPrefix:@"application"];
}

static inline SEL SFMediatorSwizzleSEL(SEL originalSEL) {
    return NSSelectorFromString([NSString stringWithFormat:@"sf_mediator_%@",NSStringFromSelector(originalSEL)]);
};


@interface SFMediator : NSObject

/**
 是否接管ApplicationDelegate代理方法
 */
@property (nonatomic,assign) BOOL takeoverApplicationDelegate;

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
 是否需要处理UIApplicationDelegate代理方法
 
 @return -
 */
+ (BOOL)takeoverApplicationDelegateByTargets;

/**
 是否能打开指定URL

 @param url -
 @return -
 */
+ (BOOL)canOpenURL:(NSString *)url;

/**
 打开URL

 @param url -
 @return -
 */
+ (id)openURL:(NSString *)url;

/**
 是否能调用到指定方法
 
 @param selector -
 @return -
 */
+ (BOOL)respondsToSelectorByTargets:(SEL)selector;

/**
 获取调用对象

 @param protocol       协议对象
 @return -
 */
+ (id)invokeTargetWithProtocol:(Protocol *)protocol;

@end
