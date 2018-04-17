//
//  UIApplication+SFAddMediator.h
//  SFProject
//
//  Created by YunSL on 2018/3/23.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <UIKit/UIKit.h>

static inline BOOL SFMediatorShouldSwizzleSEL(SEL originalSEL) {
    return [NSStringFromSelector(originalSEL) hasPrefix:@"application"];
}

static inline SEL SFMediatorSwizzleSEL(SEL originalSEL) {
    return NSSelectorFromString([NSString stringWithFormat:@"sf_mediator_%@",NSStringFromSelector(originalSEL)]);
};

@interface UIApplication (SFAddMediator)
@end
