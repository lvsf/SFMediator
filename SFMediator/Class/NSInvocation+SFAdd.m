//
//  NSInvocation+SFAdd.m
//  SFMediator
//
//  Created by YunSL on 2019/6/20.
//  Copyright © 2019年 YunSL. All rights reserved.
//

#import "NSInvocation+SFAdd.h"

static inline SFValueType SFValueTypeTransform(const char *type) {
    if (strcmp(type, @encode(void)) == 0) {
        return SFValueTypeVoid;
    } else if (strcmp(type, @encode(BOOL)) == 0) {
        return SFValueTypeBool;
    } else if (strcmp(type, @encode(int)) == 0) {
        return SFValueTypeInt;
    } else if (strcmp(type, @encode(long)) == 0) {
        return SFValueTypeLong;
    } else if (strcmp(type, @encode(float)) == 0) {
        return SFValueTypeFloat;
    } else if (strcmp(type, @encode(double)) == 0) {
        return SFValueTypeDouble;
    } else if (strcmp(type, @encode(CGPoint)) == 0) {
        return SFValueTypeCGPoint;
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        return SFValueTypeCGSize;
    } else if (strcmp(type, @encode(CGRect)) == 0) {
        return SFValueTypeCGRect;
    } else {
        return SFValueObject;
    }
};

@implementation NSInvocation(SFAdd)

- (void)lv_setArgument:(id)value atIndex:(NSInteger)index {
    switch ([self lv_argumentTypeAtIndex:index]) {
        case SFValueTypeBool:{
            BOOL argument = NO;
            if (![value isEqual:[NSNull null]]) {
                argument = [value boolValue];;
            }
            [self setArgument:&argument atIndex:index];
        }
            break;
        case SFValueTypeInt:
        case SFValueTypeLong:{
            NSInteger argument = 0;
            if (![value isEqual:[NSNull null]]) {
                argument = [value integerValue];;
            }
            [self setArgument:&argument atIndex:index];
        }
            break;
        case SFValueTypeFloat:{
            float argument = 0.0;
            if (![value isEqual:[NSNull null]]) {
                argument = [value floatValue];
            }
            [self setArgument:&argument atIndex:index];
        }
            break;
        case SFValueTypeDouble:{
            double argument = 0.0;
            if (![value isEqual:[NSNull null]]) {
                argument = [value doubleValue];
            }
            [self setArgument:&argument atIndex:index];
        }
            break;
        default:{
            if (![value isEqual:[NSNull null]]) {
                id argument = value;
                [self setArgument:&argument atIndex:index];
            }
        }
            break;
    }
}

- (id)lv_invoke {
    //暂时处理返回为void,BOOL,NSInteger,CGFloat,CGSize,CGRect,CGPoint的调用,其他视为返回NSObject对象处理
    id returnValue = nil;
    switch ([self lv_methodReturnType]) {
        case SFValueTypeVoid:{
            [self invoke];
            returnValue = nil;
        }
            break;
        case SFValueTypeBool:{
            BOOL result = NO;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeInt:
        case SFValueTypeLong:{
            NSInteger result = 0;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeFloat:
        case SFValueTypeDouble:{
            CGFloat result = 0.0;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeCGPoint:{
            CGPoint result = CGPointZero;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = [NSValue valueWithCGPoint:result];
        }
            break;
        case SFValueTypeCGSize:{
            CGSize result = CGSizeZero;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = [NSValue valueWithCGSize:result];
        }
            break;
        case SFValueTypeCGRect:{
            CGRect result = CGRectZero;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = [NSValue valueWithCGRect:result];
        }
            break;
        default:{
            __autoreleasing NSObject *result = nil;
            [self invoke];
            [self getReturnValue:&result];
            returnValue = result;
        }
            break;
    }
    return returnValue;
}

- (SFValueType)lv_argumentTypeAtIndex:(NSInteger)index {
    return SFValueTypeTransform([self.methodSignature getArgumentTypeAtIndex:index]);
}

- (SFValueType)lv_methodReturnType {
    return SFValueTypeTransform([self.methodSignature methodReturnType]);
}

@end
