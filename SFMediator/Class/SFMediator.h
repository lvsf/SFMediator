//
//  SFMediator.h
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediatorParserProtocol.h"
#import "SFMediatorError.h"

#define SFMediatorTargetInterface(protocol,name) + (id<protocol>)name;
#define SFMediatorTargetImplementation(protocol_,name) + (id<protocol_>)name {\
return [[SFMediator sharedInstance] invokeTargetFromProtocol:@protocol(protocol_)];}

extern BOOL SFMediatorShouldSwizzleSEL(SEL originalSEL);
extern SEL SFMediatorSwizzleSEL(SEL originalSEL);

@interface SFMediator : NSObject

@property (nonatomic,assign,readonly) NSInteger targetCount;

/**
 注册需要接受UIApplicationDelegate的协议
 */
@property (nonatomic,copy) NSArray<Protocol *> *registerApplicationDelegateProtocols;

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
- (id)invokeTargetFromProtocol:(Protocol *)protocol;

/**
 是否能打开指定URL

 @param url -
 @return -
 */
- (BOOL)canOpenURL:(NSString *)url;

/**
 打开URL

 @param url -
 @return -
 */
- (id)openURL:(NSString *)url;

/**
 自定义路由

 @param route    路由标志
 @param selector 调用方法
 @param protocol 方法所在的协议
 */
- (void)mappedRoute:(NSString *)route toSEL:(SEL)selector atProtocol:(Protocol *)protocol;

/**
 是否能响应指定的自定义路由

 @param route -
 @return -
 */
- (BOOL)canOpenRoute:(NSString *)route;

/**
 响应指定的自定义路由

 @param route              路由标志
 @param parameters         参数
 @param parameterIndexKeys 参数传入顺序
 @return -
 */
- (id)openRoute:(NSString *)route withParameters:(NSDictionary *)parameters parameterIndexKeys:(NSArray<NSString *> *)parameterIndexKeys;

@end
