//
//  SFMediator.m
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import "SFMediatorParser.h"

typedef NS_ENUM(NSInteger,SFMediatorErrorCode) {
    SFMediatorErrorCodeNotRecognizeScheme = 1,
    SFMediatorErrorCodeNotRecognizeProtocolName = 2,
    SFMediatorErrorCodeNotRecognizeSelector = 3,
    SFMediatorErrorCodeInvalidInvocationTarget = 4
};

static inline NSURL *SFURLParser(NSString *url) {
    NSString *encodeURL = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [NSURL URLWithString:encodeURL];
    return URL;
}

static inline NSError *SFMediatorError(NSInteger code,NSString *message) {
    return [NSError errorWithDomain:@"SFMediatorError" code:code userInfo:@{NSLocalizedDescriptionKey:message?:@""}];
}

static inline void SFMediatorLog(NSString *message) {
#ifdef DEBUG
    NSLog(@"[SFMediator] %@",message);
#endif
};

#pragma mark - SFMediatorItem/调用对象
@interface SFMediatorItem : NSObject
@property (nonatomic,copy) NSString *protocolName;
@property (nonatomic,strong) id protocoltarget;
@property (nonatomic,strong) id protocolForwardTarget;
@property (nonatomic,copy) void (^throwError)(NSError *error);
@end

@implementation SFMediatorItem

- (void)throwErrorForInvocation:(NSInvocation *)anInvocation {
    if (self.throwError) {
        self.throwError(SFMediatorError(SFMediatorErrorCodeNotRecognizeSelector, [NSString stringWithFormat:@"无法响应的方法[%@ %@]",self.protocolName,NSStringFromSelector(anInvocation.selector)]));
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.protocoltarget respondsToSelector:aSelector]) {
        return self.protocoltarget;
    }
    if ([self.protocolForwardTarget respondsToSelector:aSelector]) {
        return self.protocolForwardTarget;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSMethodSignature *signature = anInvocation.methodSignature;
    id value = objc_getAssociatedObject(signature, @selector(throwErrorForInvocation:));
    if (value && [value isEqualToString:NSStringFromSelector(@selector(throwErrorForInvocation:))]) {
        [self throwErrorForInvocation:anInvocation];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature == nil) {
        signature = [self methodSignatureForSelector:@selector(throwErrorForInvocation:)];
        objc_setAssociatedObject(signature, @selector(throwErrorForInvocation:), NSStringFromSelector(@selector(throwErrorForInvocation:)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return signature;
}

@end

#pragma mark - SFMediator
@interface SFMediator()<UIApplicationDelegate>
@property (nonatomic,strong) NSMutableDictionary<NSString *,SFMediatorItem *> *mediatorItems;
@property (nonatomic,strong) NSMutableDictionary<NSString *,id> *mediatorTargets;
@end

@implementation SFMediator

#pragma mark - public
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

+ (BOOL)canInvokeSelector:(SEL)selector {
    __block BOOL invoke = NO;
    [[SFMediator sharedInstance].mediatorItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SFMediatorItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.protocoltarget respondsToSelector:selector] ||
            [obj.protocolForwardTarget respondsToSelector:selector]) {
            invoke = YES;
            *stop = YES;
        }
    }];
    return invoke;
}

+ (BOOL)canOpenURL:(NSString *)url {
    NSError *error = [self p_canOpenURL:SFURLParser(url)];
    return !error;
}

+ (id)openURL:(NSString *)url {
    NSURL *URL = SFURLParser(url);
    NSError *error = [self p_canOpenURL:URL];
    if (error) {
        [self p_failureWithError:error];
        return nil;
    }
    SFMediator *manager = [SFMediator sharedInstance];
    NSString *protocolName = [manager.parser invocationProtocolNameFromURL:URL];
    id target = manager.mediatorTargets[protocolName];
    SEL selector = [manager.parser invocationSelectorFromURL:URL];
    id parameter = [manager.parser invocationParameterFromURL:URL];
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    [manager.parser invocation:invocation setArgumentWithParameter:parameter];
    id returnValue = [manager.parser invocationGetReturnValue:invocation];
    SFMediatorLog([NSString stringWithFormat:@"open success URL:%@ \nparameter:%@ \nreturnValue:%@",url,parameter,returnValue]);
    return returnValue;
}

+ (id)invokeTargetWithProtocol:(Protocol *)protocol forwardTarget:(id)forwardTarget {
    if (!protocol) {
        [self p_failureWithError:SFMediatorError(SFMediatorErrorCodeNotRecognizeProtocolName, [NSString stringWithFormat:@"无法响应的protocol:%@",protocol])];
        return nil;
    }
    NSString *protocolName = [NSString stringWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding];
    id target = [self p_invokeTargetWithProtocolName:protocolName];
    if (target == nil && forwardTarget == nil) {
        [self p_failureWithError:SFMediatorError(SFMediatorErrorCodeInvalidInvocationTarget, [NSString stringWithFormat:@"无法获取到正确的响应对象:%@",protocolName])];
        return nil;
    }
    return [self p_invokeTargetItemWithProtocolName:protocolName target:target forwardTarget:forwardTarget];
}

#pragma mark - private
+ (NSError *)p_canOpenURL:(NSURL *)URL {
    SFMediator *manager = [SFMediator sharedInstance];
    if (!URL.scheme || ![manager.parser.invocationURLSchemes containsObject:URL.scheme]) {
        return SFMediatorError(SFMediatorErrorCodeNotRecognizeScheme, [NSString stringWithFormat:@"无法响应的scheme:%@",URL.scheme]);
    }
    NSString *protocolName = [manager.parser invocationProtocolNameFromURL:URL];
    if (!protocolName || !objc_getProtocol(protocolName.UTF8String)) {
        return SFMediatorError(SFMediatorErrorCodeNotRecognizeProtocolName, [NSString stringWithFormat:@"无法响应的protocol:%@",URL.scheme]);
    }
    id target = [self p_invokeTargetWithProtocolName:protocolName];
    if (target == nil) {
        return SFMediatorError(SFMediatorErrorCodeInvalidInvocationTarget, [NSString stringWithFormat:@"无法获取到正确的响应对象:%@",protocolName]);
    }
    SEL selecotr = [manager.parser invocationSelectorFromURL:URL];
    if (![target respondsToSelector:selecotr]) {
        return SFMediatorError(SFMediatorErrorCodeNotRecognizeSelector, [NSString stringWithFormat:@"无法响应的方法[%@ %@]",target,NSStringFromSelector(selecotr)]);
    }
    return nil;
}

+ (id)p_invokeTargetWithProtocolName:(NSString *)protocolName {
    SFMediator *manager = [SFMediator sharedInstance];
    id target = manager.mediatorTargets[protocolName];
    if (target == nil) {
        NSString *targetClassName = [manager.parser invocationTargetClassNameFromProtocolName:protocolName];
        if ([NSClassFromString(targetClassName) respondsToSelector:@selector(new)]) {
            target = [NSClassFromString(targetClassName) new];
            manager.mediatorTargets[protocolName] = target;
        }
    }
    return target;
}

+ (id)p_invokeTargetItemWithProtocolName:(NSString *)protocolName target:(id)target forwardTarget:(id)forwardTarget {
    SFMediator *manager = [SFMediator sharedInstance];
    SFMediatorItem *mediatorItem = manager.mediatorItems[protocolName];
    if (mediatorItem == nil) {
        __weak typeof(self) wself = self;
        mediatorItem = [SFMediatorItem new];
        mediatorItem.protocolName = protocolName;
        mediatorItem.protocoltarget = target;
        mediatorItem.protocolForwardTarget = forwardTarget;
        mediatorItem.throwError = ^(NSError *error) {
            [wself p_failureWithError:error];
        };
        manager.mediatorItems[protocolName] = mediatorItem;
    }
    return mediatorItem;
}

+ (void)p_failureWithError:(NSError *)error {
    if ([[SFMediator sharedInstance].parser respondsToSelector:@selector(invocationFailureWithProtocolName:selectorName:error:)]) {
        [[SFMediator sharedInstance].parser invocationFailureWithProtocolName:nil selectorName:nil error:error];
    }
}

#pragma mark - UIApplicationDelegate方法转发处理
- (NSMethodSignature *)sf_mediator_methodSignatureForSelector:(SEL)aSelector {
    __block NSMethodSignature *methodSignature = [[SFMediator sharedInstance] sf_mediator_methodSignatureForSelector:aSelector];
    if (SFMediatorShouldSwizzleSEL(aSelector)) {
        if (methodSignature == nil) {
            [[SFMediator sharedInstance].mediatorItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SFMediatorItem * _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj.protocoltarget respondsToSelector:aSelector]) {
                    methodSignature = [obj.protocoltarget methodSignatureForSelector:aSelector];
                    *stop = YES;
                }
            }];
        }
    }
    return methodSignature;
}

- (void)sf_mediator_forwardInvocation:(NSInvocation *)anInvocation {
    if (SFMediatorShouldSwizzleSEL(anInvocation.selector)) {
        SEL tempSEL = anInvocation.selector;
        if ([self respondsToSelector:anInvocation.selector]) {
            [anInvocation setSelector:SFMediatorSwizzleSEL(anInvocation.selector)];
            [anInvocation invokeWithTarget:self];
        }
        [anInvocation setSelector:tempSEL];
        [[SFMediator sharedInstance].mediatorItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SFMediatorItem * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj.protocoltarget respondsToSelector:anInvocation.selector]) {
                [anInvocation invokeWithTarget:obj.protocoltarget];
            }
        }];
    }
    else {
        [[SFMediator sharedInstance] sf_mediator_forwardInvocation:anInvocation];
    }
}

#pragma mark - APP启动
- (BOOL)sf_mediator_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self sf_mediator_application:application didFinishLaunchingWithOptions:launchOptions];
    [[SFMediator sharedInstance].mediatorItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SFMediatorItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.protocoltarget respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
            [obj.protocoltarget application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }];
    return YES;
}

#pragma mark - 外部URL处理
//iOS9
- (BOOL)sf_mediator_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return NO;
}

//iOS4.2-iOS9
- (BOOL)sf_mediator_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return NO;
}

//iOS2-iOS9
- (BOOL)sf_mediator_application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return NO;
}

#pragma mark - set/get
- (NSMutableDictionary<NSString *,SFMediatorItem *> *)mediatorItems {
    return _mediatorItems?:({
        _mediatorItems = [NSMutableDictionary new];
        _mediatorItems;
    });
}

- (NSMutableDictionary<NSString *,id> *)mediatorTargets {
    return _mediatorTargets?:({
        _mediatorTargets = [NSMutableDictionary new];
        _mediatorTargets;
    });
}

- (id<SFMediatorParserProtocol>)parser {
    return _parser?:({
        _parser = [SFMediatorParser new];
        _parser;
    });
}

@end
