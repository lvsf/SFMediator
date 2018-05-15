//
//  SFMediatorParserProtocol.h
//  SFMediator
//
//  Created by YunSL on 2018/4/12.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@protocol SFMediatorParserProtocol <NSObject>
/**
 可远程响应的URL协议名
 
 @return URL协议名
 */
@property (nonatomic,copy) NSArray<NSString *> *invocationURLSchemes;

/**
 解析调用协议名
 
 @param URL -
 @return -
 */
- (NSString *)invocationProtocolNameFromURL:(NSURL *)URL;

/**
 解析调用方法名

 @param URL -
 @return -
 */
- (SEL)invocationSelectorFromURL:(NSURL *)URL;

/**
 解析调用方法参数

 @param URL -
 @return -
 */
- (id)invocationParameterFromURL:(NSURL *)URL;

/**
 解析调用对象

 @param protocolName -
 @return -
 */
- (id)invocationTargetFromProtocolName:(NSString *)protocolName;

/**
 设置调用参数
 
 @param invocation 方法调用
 @param parameter  传入参数
 */
- (void)invocation:(NSInvocation *)invocation setArgumentWithParameter:(id)parameter;

/**
 调用和返回
 
 @param invocation 方法调用
 @return           返回值
 */
- (id)invocationGetReturnValue:(NSInvocation *)invocation;

@end
