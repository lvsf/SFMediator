//
//  UIApplication+SFAddMediator.m
//  SFProject
//
//  Created by YunSL on 2018/3/23.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import "UIApplication+SFAddMediator.h"
#import <objc/runtime.h>

static inline BOOL SFMediatorSwizzleInstanceMethod(Class originalClass,Class targetClass,SEL originalSEL,SEL targetSEL) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSEL);
    Method newMethod = class_getInstanceMethod(targetClass, targetSEL);
    if (originalMethod && newMethod) {
        class_addMethod(originalClass,
                        originalSEL,
                        class_getMethodImplementation(originalClass, originalSEL),
                        method_getTypeEncoding(originalMethod));
        class_addMethod(targetClass,
                        targetSEL,
                        class_getMethodImplementation(targetClass, targetSEL),
                        method_getTypeEncoding(newMethod));
        method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSEL),
                                       class_getInstanceMethod(targetClass, targetSEL));
        return YES;
    };
    NSLog(@"[SFMediatorSwizzleInstanceMethod] error:%@ -> %@",NSStringFromSelector(originalSEL),NSStringFromSelector(targetSEL));
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
        Class originalClass = delegate.class;
        Class targetClass = NSClassFromString(@"SFMediator");
        SFMediatorSwizzleInstanceMethod(originalClass,
                                        targetClass,
                                        @selector(forwardInvocation:),
                                        SFMediatorSwizzleSEL(@selector(forwardInvocation:)));
        SFMediatorSwizzleInstanceMethod(originalClass,
                                        targetClass,
                                        @selector(respondsToSelector:),
                                        SFMediatorSwizzleSEL(@selector(respondsToSelector:)));
        SFMediatorSwizzleInstanceMethod(originalClass,
                                        targetClass,
                                        @selector(methodSignatureForSelector:),
                                        SFMediatorSwizzleSEL(@selector(methodSignatureForSelector:)));
        unsigned int count = 0;
        struct objc_method_description *methods = protocol_copyMethodDescriptionList(@protocol(UIApplicationDelegate), NO, YES, &count);
        for (unsigned int i = 0; i < count; i++) {
            struct objc_method_description method = methods[i];
            if (SFMediatorShouldSwizzleSEL(method.name)) {
                SEL originalSEL = method.name;
                SEL targetSEL = SFMediatorSwizzleSEL(method.name);
                if (class_respondsToSelector(originalClass, originalSEL)) {
                    class_addMethod(originalClass,
                                    targetSEL,
                                    class_getMethodImplementation(targetClass, targetSEL),
                                    method.types);
                    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSEL),
                                                   class_getInstanceMethod(originalClass, targetSEL));
                }
                else {
                    class_addMethod(originalClass,
                                    originalSEL,
                                    class_getMethodImplementation(targetClass, targetSEL),
                                    method.types);
                }
            }
        }
        free(methods);
    });
    [self sf_mediator_setDelegate:delegate];
}

@end
