//
//  SFMediatorParserProtocol.h
//  SFMediator
//
//  Created by YunSL on 2018/4/12.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "SFMediatorError.h"

@protocol SFMediatorParserProtocol <NSObject>

/**
 可远程响应的URL协议名
 
 @return URL协议名
 */
@property (nonatomic,copy) NSArray<NSString *> *invocationRecognizedURLSchemes;

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
- (id)invocationParametersFromURL:(NSURL *)URL;

/**
 解析调用方法参数

 @param parameters         参数
 @param parameterIndexKeys 参数key值传入顺序
 @return -
 */
- (id)invocationParametersFromParameters:(NSDictionary *)parameters parameterIndexKeys:(NSArray<NSString *> *)parameterIndexKeys;

/**
 解析调用对象

 @param protocolName -
 @return -
 */
- (NSString *)invocationTargetClassNameFromProtocolName:(NSString *)protocolName;

/**
 设置参数

 @param invocation -
 @param parameters -
 */
- (void)invocation:(NSInvocation *)invocation setArgumentWithParameters:(id)parameters;

/**
 调用和返回

 @param invocation 方法对象
 @return 返回值
 */
- (id)invoke:(NSInvocation *)invocation;

/**
 调用失败

 @param error -
 */
- (void)invokeFailureWithError:(SFMediatorError *)error;

@end
