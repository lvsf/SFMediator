//
//  SFMediator.m
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import "SFMediatorParser.h"

static inline NSURL *SFURLPraser(NSString *url) {
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
@property (nonatomic,strong) UIWindow *alertWindow;
@end

@implementation SFMediatorItem

- (void)throwErrorForSelector:(SEL)aSelector {
    SFMediatorLog([NSString stringWithFormat:@"无法响应的方法[%@ %@]",self.protocolName,NSStringFromSelector(aSelector)]);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = nil;
    if ([self.protocoltarget respondsToSelector:aSelector]) {
        signature = [self.protocoltarget methodSignatureForSelector:aSelector];
    }
    else if ([self.protocolForwardTarget respondsToSelector:aSelector]) {
        signature = [self.protocolForwardTarget methodSignatureForSelector:aSelector];
    }
    else {
        signature = [super methodSignatureForSelector:@selector(throwErrorForSelector:)];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.protocoltarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocoltarget];
    } else if ([self.protocolForwardTarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocolForwardTarget];
    } else {
        [self throwErrorForSelector:anInvocation.selector];
    }
}

@end

#pragma mark - SFMediator
@interface SFMediator()<UIApplicationDelegate>
@property (nonatomic,strong) NSMutableDictionary<NSString *,SFMediatorItem *> *mediatorItems;
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

+ (BOOL)canInvokeWithSelector:(SEL)selector {
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
    NSError *error = [self p_canOpenURL:SFURLPraser(url)];
    return !error;
}

+ (id)openURL:(NSString *)url {
    id returnValue = nil;
    NSURL *URL = SFURLPraser(url);
    NSError *error = [self p_canOpenURL:URL];
    if (!error) {
        SFMediator *manager = [self sharedInstance];
        NSString *protocolName = [manager.parser invocationProtocolNameFromURL:URL];
        SEL selector = [manager.parser invocationSelectorFromURL:URL];
        id parameter = [manager.parser invocationParameterFromURL:URL];
        id protocoltarget = [manager.parser invocationTargetFromProtocolName:protocolName];
        id forwardTarget = nil;
        error = [self p_canInvokeWithProtocol:protocolName
                               protocoltarget:protocoltarget
                                forwardTarget:forwardTarget];
        if (!error) {
            SFMediatorItem *mediatorItem = [self p_invokeTargetWithProtocol:protocolName
                                                             protocoltarget:protocoltarget
                                                              forwardTarget:forwardTarget
                                                                    fromURL:YES];
            NSMethodSignature *signature = [mediatorItem methodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:mediatorItem];
            [invocation setSelector:selector];
            [manager.parser invocation:invocation setArgumentWithParameter:parameter];
            returnValue = [manager.parser invocationGetReturnValue:invocation];
            SFMediatorLog([NSString stringWithFormat:@"open success URL:%@ \nparameter:%@ \nreturnValue:%@",url,parameter,returnValue]);
        }
    }
    if (error) {
        SFMediatorLog(error.localizedDescription);
    }
    return returnValue;
}

+ (id)invokeTargetWithProtocol:(Protocol *)protocol forwardTarget:(id)forwardTarget {
    SFMediator *manager = [self sharedInstance];
    NSString *protocolName = protocol?[NSString stringWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding]:nil;
    id protocoltarget = protocolName?[manager.parser invocationTargetFromProtocolName:protocolName]:nil;
    NSError *error = [self p_canInvokeWithProtocol:protocolName
                                    protocoltarget:protocoltarget
                                     forwardTarget:forwardTarget];
    return error?:[self p_invokeTargetWithProtocol:protocolName
                                    protocoltarget:protocoltarget
                                     forwardTarget:forwardTarget
                                           fromURL:NO];
}

#pragma mark - private
+ (NSError *)p_canOpenURL:(NSURL *)URL {
    NSError *error = nil;
    SFMediator *manager = [self sharedInstance];
    if (!URL.scheme || ![manager.parser.invocationURLSchemes containsObject:URL.scheme]) {
        error = SFMediatorError(0, [NSString stringWithFormat:@"无法响应的scheme:%@",URL.scheme]);
    }
    return error;
}

+ (NSError *)p_canInvokeWithProtocol:(NSString *)protocolName protocoltarget:(id)protocoltarget forwardTarget:(id)forwardTarget {
    NSError *error = nil;
    if (!objc_getProtocol(protocolName.UTF8String)) {
        error = SFMediatorError(0, [NSString stringWithFormat:@"无法响应的protocol:%@",protocolName]);
    }
    else if (!protocoltarget) {
        error = SFMediatorError(0,[NSString stringWithFormat:@"无法获取到正确的响应对象:%@",protocolName]);
    }
    return error;
}

+ (id)p_invokeTargetWithProtocol:(NSString *)protocolName protocoltarget:(id)protocoltarget forwardTarget:(id)forwardTarget fromURL:(BOOL)fromURL {
    SFMediator *manager = [self sharedInstance];
    SFMediatorItem *mediatorItem = manager.mediatorItems[protocolName];
    if (mediatorItem == nil) {
        mediatorItem = [SFMediatorItem new];
        mediatorItem.protocolName = protocolName;
        mediatorItem.protocoltarget = protocoltarget;
        mediatorItem.protocolForwardTarget = forwardTarget;
        manager.mediatorItems[protocolName] = mediatorItem;
    }
    return mediatorItem;
}

#pragma mark - UIApplicationDelegate
#pragma mark - 转发处理
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

#pragma mark - 外部URL处理
- (BOOL)sf_mediator_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self sf_mediator_application:application didFinishLaunchingWithOptions:launchOptions];
    [[SFMediator sharedInstance].mediatorItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SFMediatorItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.protocoltarget respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
            [obj.protocoltarget application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }];
    return YES;
}

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

- (id<SFMediatorParserProtocol>)parser {
    return _parser?:({
        _parser = [SFMediatorParser new];
        _parser;
    });
}

@end
