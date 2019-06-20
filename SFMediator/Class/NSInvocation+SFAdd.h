//
//  NSInvocation+SFAdd.h
//  SFMediator
//
//  Created by YunSL on 2019/6/20.
//  Copyright © 2019年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,SFValueType) {
    SFValueTypeNo = 0,
    SFValueTypeVoid,
    SFValueTypeChar,
    SFValueTypeInt,
    SFValueTypeLong,
    SFValueTypeFloat,
    SFValueTypeDouble,
    SFValueTypeBool,
    SFValueTypeSelector,
    SFValueObject,
    SFValueTypeCGPoint,
    SFValueTypeCGSize,
    SFValueTypeCGRect,
    SFValueTypePointer
};

NS_ASSUME_NONNULL_BEGIN

@interface NSInvocation (SFAdd)
- (void)lv_setArgument:(id)value atIndex:(NSInteger)index;
- (id)lv_invoke;
- (SFValueType)lv_argumentTypeAtIndex:(NSInteger)index;
- (SFValueType)lv_methodReturnType;
@end

NS_ASSUME_NONNULL_END
