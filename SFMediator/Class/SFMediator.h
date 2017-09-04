//
//  SFMediator.h
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 快速声明一个用来转发协议的类

 @param name 协议定义的名称前缀 例如 Book(协议名称前缀) + ForwardTarget(固定名称)
 @return
 */
#define SFForwardTargetBegin(name) _Pragma("clang diagnostic push")\
_Pragma("clang diagnostic ignored \"-Wprotocol\"")\
@interface name##ForwardTarget : NSObject<name##Protocol>\
@end\
@implementation name##ForwardTarget

#define SFForwardTargetEnd() _Pragma("clang diagnostic pop")\
@end

@interface SFMediatorURLInvokeComponent : NSObject
@property (nonatomic,assign) SEL selector;
@property (nonatomic,copy) NSString *protocolName;
@property (nonatomic,copy) NSDictionary *parameters;
@property (nonatomic,strong) id forwardTarget;
@end

@protocol SFMediatorProtocolParser <NSObject>
/**
 获取指定协议对应的调用对象,默认为协议名称 + Target

 @param protocol 指定的协议
 @return 协议调用对象
 */
- (id)targetFromProtocol:(Protocol*)protocol;
/**
 获取从指定URL中解析得到的调用协议名称,方法的名字以及传入的参数

 @param url 指定的URL
 @return URL解析结果
 */
- (SFMediatorURLInvokeComponent*)targetInvokeComponentFromURL:(NSString*)url;
@end

@interface SFMediator : NSObject
@property (nonatomic,strong) id <SFMediatorProtocolParser> parser;
+ (id)invokeURL:(NSString*)url;
+ (id)invokeTargetWithProtocol:(Protocol*)protocol
                 forwardTarget:(id)forwardTarget;
@end
