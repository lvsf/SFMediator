//
//  UIApplication+SFMediator.m
//  SFProject
//
//  Created by YunSL on 2018/3/23.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import "UIApplication+SFMediator.h"
#import "SFMediator.h"
#import <objc/runtime.h>

static inline BOOL SFMediatorSwizzleInstanceMethod(Class originalClass, Class targetClass, SEL originalSEL, SEL targetSEL) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSEL);
    Method targetMethod = class_getInstanceMethod(targetClass, targetSEL);
    if (originalMethod && targetMethod) {
        class_addMethod(originalClass,
                        originalSEL,
                        class_getMethodImplementation(originalClass, originalSEL),
                        method_getTypeEncoding(originalMethod));
        class_addMethod(originalClass,
                        targetSEL,
                        class_getMethodImplementation(targetClass, targetSEL),
                        method_getTypeEncoding(targetMethod));
        method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSEL),
                                       class_getInstanceMethod(originalClass, targetSEL));
        return YES;
    };
    return NO;
}

@implementation UIApplication (SFMediator)

+ (void)load {
    SFMediatorSwizzleInstanceMethod(self,
                                    self,
                                    @selector(setDelegate:),
                                    @selector(_lv_mediator_setDelegate:));
    SFMediatorSwizzleInstanceMethod(self,
                                    self,
                                    @selector(delegate),
                                    @selector(_lv_mediator_delegate));
}

- (void)_lv_mediator_setDelegate:(id<UIApplicationDelegate>)delegate {
    [self.lv_multipleProxy setOriginalProxy:delegate];
    [[SFMediator sharedInstance].allTargets enumerateObjectsUsingBlock:^(id<SFMediatorTargetProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.respondToApplicationDelegate) {
            [self.lv_multipleProxy addProxy:obj];
        }
    }];
    [self _lv_mediator_setDelegate:self.lv_multipleProxy];
}

- (id<UIApplicationDelegate>)_lv_mediator_delegate {
    id<UIApplicationDelegate> delegate = [self _lv_mediator_delegate];
    if ([delegate isEqual:self.lv_multipleProxy]) {
        delegate = self.lv_multipleProxy.originalProxy;
    }
    return delegate;
}

- (SFApplicationMultipleProxy<UIApplicationDelegate> *)lv_multipleProxy {
    return objc_getAssociatedObject(self, _cmd)?:({
        SFApplicationMultipleProxy *multipleProxy = [SFApplicationMultipleProxy new];
        objc_setAssociatedObject(self, _cmd, multipleProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        multipleProxy;
    });
}

@end
