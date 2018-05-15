//
//  SFMediatorParser.m
//  SFMediator
//
//  Created by YunSL on 2018/4/12.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import "SFMediatorParser.h"
#import "SFMediator.h"
#import <objc/runtime.h>

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

static inline SFValueType SFValueTypeTransform(const char *type){
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

@implementation SFMediatorParser
@synthesize invocationURLSchemes = _invocationURLSchemes;

- (instancetype)init {
    if (self = [super init]) {
        self.invocationURLSchemes = @[@"app"];
        self.enableRecursiveParse = YES;
        self.parserType = Array;
    }
    return self;
}

- (NSString *)invocationProtocolNameFromURL:(NSURL *)URL {
    return [[URL.host stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[URL.host substringToIndex:1] uppercaseString]] stringByAppendingString:@"Protocol"];
}

- (id)invocationTargetFromProtocolName:(NSString *)protocolName {
    id target = nil;
    if (protocolName) {
        NSString *targetClassName = [protocolName stringByAppendingString:@"Target"];
        if ([NSClassFromString(targetClassName) respondsToSelector:@selector(new)]) {
            target = [NSClassFromString(targetClassName) new];
        }
    }
    return target;
}

- (SEL)invocationSelectorFromURL:(NSURL *)URL {
    return NSSelectorFromString([URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""]);
}

- (id)invocationParameterFromURL:(NSURL *)URL {
    id parameter = nil;
    switch (self.parserType) {
        case Array:
        case Dictionary:{
            NSString *query = URL.query;
            NSMutableArray *array = (self.parserType == Array)?[NSMutableArray new]:nil;
            NSMutableDictionary *dictionary = (self.parserType == Dictionary)?[NSMutableDictionary new]:nil;
            parameter = (self.parserType == Array)?array:dictionary;
            if (query.length > 0) {
                NSArray *components = [query componentsSeparatedByString:@"&"];
                [components enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSArray *elements = [obj componentsSeparatedByString:@"="];
                    if (elements.count == 2) {
                        id value = elements.lastObject;
                        if ([value isKindOfClass:[NSString class]]) {
                            NSString *string = (NSString *)value;
                            if (string.length == 0) {
                                value = [NSNull null];
                            }
                            else {
                                if (self.enableRecursiveParse && [SFMediator canOpenURL:string]) {
                                    value = [SFMediator openURL:string];
                                    value = value?:[NSNull null];
                                }
                            }
                        }
                        if (self.parserType == Array) {
                            [array addObject:value];
                        }
                        if (self.parserType == Dictionary) {
                            [dictionary setObject:value
                                           forKey:elements.firstObject];
                        }
                    }
                }];
            }
        }
            break;
        default:
            break;
    }
    return parameter;
}

- (void)invocation:(NSInvocation *)invocation setArgumentWithParameter:(id)parameter {
    //此处使用NSArray保证参数的顺序
    if ([parameter isKindOfClass:[NSArray class]]) {
        [(NSArray *)parameter enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //此处应该封装一个协议用来处理URL获取的参数类型到OC类型的转换
            switch (SFValueTypeTransform([invocation.methodSignature getArgumentTypeAtIndex:idx + 2])) {
                case SFValueTypeBool:{
                    BOOL argument = [obj boolValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeInt:
                case SFValueTypeLong:{
                    NSInteger argument = [obj integerValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeFloat:{
                    float argument = [obj floatValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeDouble:{
                    double argument = [obj doubleValue];
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                default:{
                    id argument = obj;
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
            }
        }];
    }
}

- (id)invocationGetReturnValue:(NSInvocation *)invocation {
    //暂时处理返回为void,BOOL,NSInteger,CGFloat,CGSize,CGRect,CGPoint的调用,其他视为返回NSObject对象处理
    id returnValue = nil;
    const char *returnType = [invocation.methodSignature methodReturnType];
    switch (SFValueTypeTransform(returnType)) {
        case SFValueTypeVoid:{
            [invocation invoke];
            returnValue = nil;
        }
            break;
        case SFValueTypeBool:{
            BOOL result = NO;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeInt:
        case SFValueTypeLong:{
            NSInteger result = 0;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeFloat:
        case SFValueTypeDouble:{
            CGFloat result = 0.0;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = @(result);
        }
            break;
        case SFValueTypeCGPoint:{
            CGPoint result = CGPointZero;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = [NSValue valueWithCGPoint:result];
        }
            break;
        case SFValueTypeCGSize:{
            CGSize result = CGSizeZero;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = [NSValue valueWithCGSize:result];
        }
            break;
        case SFValueTypeCGRect:{
            CGRect result = CGRectZero;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = [NSValue valueWithCGRect:result];
        }
            break;
        default:{
            __autoreleasing NSObject *result = nil;
            [invocation invoke];
            [invocation getReturnValue:&result];
            returnValue = result;
        }
            break;
    }
    return returnValue;
}

@end
