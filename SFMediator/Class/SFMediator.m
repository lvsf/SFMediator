//
//  SFMediator.m
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import <objc/runtime.h>

static inline NSURL* SFURLPraser(NSString *url) {
    NSString *encodeURL = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [NSURL URLWithString:encodeURL];
    return URL;
}

@implementation SFMediatorURLInvokeComponent @end

@interface SFMediatorDefaultParser : NSObject<SFMediatorProtocolParser>
@end

@implementation SFMediatorDefaultParser

- (NSString *)targetURLSchemeForInvoke {
    return @"demo";
}

- (SFMediatorURLInvokeComponent *)targetInvokeComponentFromURL:(NSURL *)URL {
    SFMediatorURLInvokeComponent *component = [SFMediatorURLInvokeComponent new];
    component.scheme = URL.scheme;
    component.protocolName = [URL.host stringByAppendingString:@"Protocol"];
    component.selector = NSSelectorFromString([URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""]);
    component.parameters = ({
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSMutableArray *values = [NSMutableArray new];
        NSString *query = URL.query;
        if (query.length > 0) {
            NSArray *components = [query componentsSeparatedByString:@"&"];
            [components enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *elements = [obj componentsSeparatedByString:@"="];
                if (elements.count == 2) {
                    id value = elements.lastObject;
                    if ([value isKindOfClass:[NSString class]]) {
                        NSString *string = (NSString*)value;
                        if (string.length == 0) {
                            value = [NSNull null];
                        }
                        else if ([SFMediator canInvokeURL:string]) {
                            value = [SFMediator invokeURL:string];
                            value = value?:[NSNull null];
                        }
                    }
                    [params setObject:value
                               forKey:elements.firstObject];
                    [values addObject:value];
                }
            }];
        }
        component.parameterValues = values.copy;
        params;
    });
    return component;
}

- (id)targetFromProtocol:(Protocol *)protocol {
    NSString *targetName = [[[NSString alloc] initWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding] stringByAppendingString:@"Target"];
    id target = nil;
    if ([NSClassFromString(targetName) respondsToSelector:@selector(new)]) {
        target = [NSClassFromString(targetName) new];
    }
    return target;
}

@end

@interface SFMediatorItem : NSObject
@property (nonatomic,strong) id protocoltarget;
@property (nonatomic,strong) id protocolForwardTarget;
@property (nonatomic,copy) NSString *protocolName;
@end

@implementation SFMediatorItem

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if ([self.protocoltarget respondsToSelector:aSelector]) {
        signature = [self.protocoltarget methodSignatureForSelector:aSelector];
    }
    else if ([self.protocolForwardTarget respondsToSelector:aSelector]) {
        NSLog(@"protocol:%@ 转发未实现的方法[%@] => %@",self.protocolName,NSStringFromSelector(aSelector), NSStringFromClass([self.protocolForwardTarget class]));
        signature = [self.protocolForwardTarget methodSignatureForSelector:aSelector];
    }
    else {
        NSLog(@"protocol:%@ 抛弃未实现的方法[%@]",self.protocolName,NSStringFromSelector(aSelector));
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.protocoltarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocoltarget];
    } else if ([self.protocolForwardTarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocolForwardTarget];
    } else {
    }
}

@end

@interface SFMediator()
@property (nonatomic,strong) NSMutableDictionary *mediatorItems;
@end

@implementation SFMediator

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (BOOL)canInvokeURL:(NSString *)url {
    SFMediator *manager = [self sharedInstance];
    NSURL *URL = SFURLPraser(url);
    BOOL can = NO;
    if (URL) {
        if ([URL.scheme isEqualToString:[manager.parser targetURLSchemeForInvoke]]) {
            if (URL.path.length > 0) {
                can = YES;
            }
        }
    }
    return can;
}

+ (id)invokeURL:(NSString *)url {
    if ([self canInvokeURL:url]) {
        id returnValue = nil;
        SFMediator *manager = [self sharedInstance];
        SFMediatorURLInvokeComponent *component = [manager.parser targetInvokeComponentFromURL:SFURLPraser(url)];
        SFMediatorItem *mediatorItem = [self invokeTargetWithProtocol:objc_getProtocol(component.protocolName.UTF8String) forwardTarget:component.forwardTarget];
        NSMethodSignature *signature = [mediatorItem methodSignatureForSelector:component.selector];
        if (mediatorItem && signature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:mediatorItem];
            [invocation setSelector:component.selector];
            [component.parameterValues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //此处应该封装一个协议用来处理URL获取的参数类型到OC类型的转换
                const char *argumentType = [invocation.methodSignature getArgumentTypeAtIndex:idx + 2];
                if (strcmp(argumentType, @encode(NSInteger)) == 0) {
                    NSInteger argument = [obj integerValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                else if (strcmp(argumentType, @encode(float)) == 0) {
                    float argument = [obj floatValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                else if (strcmp(argumentType, @encode(double)) == 0) {
                    double argument = [obj doubleValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                else if (strcmp(argumentType, @encode(BOOL)) == 0) {
                    BOOL argument = [obj boolValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                else {
                    id argument = obj;
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
            }];
            //暂时处理返回为void,BOOL,NSInteger,CGFloat,CGSize,CGRect,CGPoint的调用,其他视为返回NSObject对象处理
            const char *returnType = [invocation.methodSignature methodReturnType];
            if (strcmp(returnType, @encode(void)) == 0) {
                [invocation invoke];
                returnValue = nil;
            } else if (strcmp(returnType, @encode(BOOL)) == 0) {
                BOOL result = NO;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = @(result);
            } else if (strcmp(returnType, @encode(NSInteger)) == 0) {
                NSInteger result = 0;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = @(result);
            } else if (strcmp(returnType, @encode(CGFloat)) == 0) {
                CGFloat result = 0.0;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = @(result);
            } else if (strcmp(returnType, @encode(CGSize)) == 0) {
                CGSize result = CGSizeZero;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = [NSValue valueWithCGSize:result];
            } else if (strcmp(returnType, @encode(CGRect)) == 0) {
                CGRect result = CGRectZero;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = [NSValue valueWithCGRect:result];
            } else if (strcmp(returnType, @encode(CGPoint)) == 0) {
                CGPoint result = CGPointZero;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = [NSValue valueWithCGPoint:result];
            } else {
                __autoreleasing NSObject *result = nil;
                [invocation invoke];
                [invocation getReturnValue:&result];
                returnValue = result;
            }
        }
        return returnValue;
    }
    else {
        return nil;
    }
}

+ (id)invokeTargetWithProtocol:(Protocol *)protocol forwardTarget:(id)forwardTarget {
    SFMediator *manager = [self sharedInstance];
    SFMediatorItem *mediatorItem = nil;
    NSString *protocolName = [[NSString alloc] initWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding];
    if (protocolName.length > 0) {
        mediatorItem = [manager.mediatorItems objectForKey:protocolName];
        if (mediatorItem == nil) {
            mediatorItem = [SFMediatorItem new];
            mediatorItem.protocolName = protocolName;
            mediatorItem.protocolForwardTarget = forwardTarget;
            mediatorItem.protocoltarget = [manager.parser targetFromProtocol:protocol];
            [manager.mediatorItems setObject:mediatorItem forKey:protocolName];
        }
    }
    return mediatorItem;
}

- (NSMutableDictionary *)mediatorItems {
    return _mediatorItems?:({
        _mediatorItems = [NSMutableDictionary new];
        _mediatorItems;
    });
}

- (id<SFMediatorProtocolParser>)parser {
    return _parser?:({
        _parser = [SFMediatorDefaultParser new];
        _parser;
    });
}

@end

