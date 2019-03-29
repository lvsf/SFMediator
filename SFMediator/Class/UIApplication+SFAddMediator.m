//
//  UIApplication+SFAddMediator.m
//  SFProject
//
//  Created by YunSL on 2018/3/23.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import "UIApplication+SFAddMediator.h"
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

@implementation UIApplication (SFAddMediator)

+ (void)load {
//    SFMediatorSwizzleInstanceMethod(self,
//                                    self,
//                                    @selector(setDelegate:),
//                                    SFMediatorSwizzleSEL(@selector(setDelegate:)));
}

- (void)sf_mediator_setDelegate:(id<UIApplicationDelegate>)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([SFMediator sharedInstance].targetCount > 0) {
            //1.初始化接受UIApplicationDelegate的组件对象
//            [[SFMediator sharedInstance].registerApplicationDelegateProtocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                [SFMediator invokeTargetWithProtocol:obj];
//            }];
            /*
              2.判断是否要交换UIApplicationDelegate协议里的方法
             -> 是否为UIApplicationDelegate中允许转发实现的代理方法(过滤掉协议中属性的访问方法以及部分不做转发处理的方法),如果为否不做任何处理
             -> 组件的所有调用对象中是否实现了UIApplicationDelegate中的某个方法,如果没有不做任何处理
             -> 原UIApplicationDelegate是否实现了该方法,如果有交换给SFMediator统一分发处理,如果没有添加一个空实现后再交换
             */
            Class originalClass = [delegate class];
            Class targetClass = [SFMediator class];
            BOOL swizzledSEL = NO;
            unsigned int count = 0;
            struct objc_method_description *methods = protocol_copyMethodDescriptionList(@protocol(UIApplicationDelegate), NO, YES, &count);
            for (unsigned int i = 0; i < count; i++) {
                struct objc_method_description method = methods[i];
                if (!SFMediatorShouldSwizzleSEL(method.name)) continue;
                if ([SFMediator respondsToSelectorByTargets:method.name]) {
                    if (!swizzledSEL) {
                        swizzledSEL = YES;
                        SFMediatorSwizzleInstanceMethod(originalClass,
                                                        targetClass,
                                                        @selector(forwardInvocation:),
                                                        SFMediatorSwizzleSEL(@selector(forwardInvocation:)));
                    }
                    SEL orginalSEL = method.name;
                    SEL targetSEL = SFMediatorSwizzleSEL(orginalSEL);
                    if (![delegate respondsToSelector:orginalSEL]) {
                        void (^nothingImplementation)(id) = ^(id obj){};
                        class_addMethod(originalClass,
                                        orginalSEL,
                                        imp_implementationWithBlock(nothingImplementation),
                                        method.types);
                    }
                    class_addMethod(originalClass,
                                    targetSEL,
                                    class_getMethodImplementation(targetClass, targetSEL),
                                    method.types);
                    method_exchangeImplementations(class_getInstanceMethod(originalClass, orginalSEL),
                                                   class_getInstanceMethod(originalClass, targetSEL));
                }
            }
            free(methods);
        }
    });

    [self sf_mediator_setDelegate:delegate];
}

@end
