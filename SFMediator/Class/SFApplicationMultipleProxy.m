//
//  SFApplicationMultipleProxy.m
//  SFFormView
//
//  Created by YunSL on 17/10/20.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFApplicationMultipleProxy.h"
#import "SFMediator.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

@implementation SFApplicationMultipleProxy
@synthesize proxies = _proxies;

+ (instancetype)multipleProxyWithOriginalProxy:(id)originalProxy {
    SFApplicationMultipleProxy *proxy = [self new];
    proxy.originalProxy = originalProxy;
    return proxy;
}

- (void)addProxy:(id)proxy {
    if (proxy && [self.proxies.allObjects indexOfObject:proxy] == NSNotFound) {
        [self.proxies addPointer:(__bridge void * _Nullable)(proxy)];
    }
}

- (void)removeProxy:(id)proxy {
    NSInteger index = [self.proxies.allObjects indexOfObject:proxy];
    if (index != NSNotFound) {
        [self.proxies removePointerAtIndex:index];
    }
}

- (void)removeAllProxies {
    NSInteger count = self.proxies.count;
    for (NSInteger i = 0; i < count; i++) {
        [self.proxies removePointerAtIndex:i];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.originalProxy respondsToSelector:aSelector]) {
        return YES;
    }
    BOOL responds = NO;
    for (NSObject *proxy in self.proxies.allObjects) {
        if ([proxy respondsToSelector:aSelector]) {
            responds = YES;
            break;
        }
    }
    return responds;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    __block NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature == nil) {
        if ([self.originalProxy respondsToSelector:aSelector]) {
            signature = [self.originalProxy methodSignatureForSelector:aSelector];
        }
    }
    if (signature == nil) {
        [self.proxies.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:aSelector]) {
                signature = [obj methodSignatureForSelector:aSelector];
                if (signature) {
                    *stop = YES;
                }
            }
        }];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [self.proxies.allObjects enumerateObjectsUsingBlock:^(id<SFMediatorTargetProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL responds = ([obj respondsToSelector:invocation.selector]);
        if (responds) {
            if ([obj conformsToProtocol:@protocol(UIApplicationDelegate)] &&
                [obj respondsToSelector:@selector(ingoreApplicationDelegateSelectorNames)]) {
                if ([[obj ingoreApplicationDelegateSelectorNames] containsObject:NSStringFromSelector(invocation.selector)]) {
                    responds = NO;
                }
            }
        }
        if (responds) {
            [invocation invokeWithTarget:obj];
        }
    }];
    if ([self.originalProxy respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.originalProxy];        
    }
}

- (NSPointerArray *)proxies {
    return _proxies?:({
        _proxies = [NSPointerArray weakObjectsPointerArray];
        _proxies;
    });
}

@end

#pragma clang diagnostic pop
