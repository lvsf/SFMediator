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
@synthesize invocationRecognizedURLSchemes = _invocationRecognizedURLSchemes;

- (instancetype)init {
    if (self = [super init]) {
        self.invocationRecognizedURLSchemes = @[@"app"];
        self.enableRecursiveParse = NO;
        self.parserType = Array;
    }
    return self;
}

- (NSString *)invocationProtocolNameFromURL:(NSURL *)URL {
    return [[URL.host stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[URL.host substringToIndex:1] uppercaseString]] stringByAppendingString:@"Protocol"];
}

- (NSString *)invocationTargetClassNameFromProtocolName:(NSString *)protocolName {
    NSString *name = nil;
    if (protocolName) {
        NSString *name_ = [protocolName stringByAppendingString:@"Target"];
        if ([NSClassFromString(name_) respondsToSelector:@selector(new)]) {
            name = name_;
        }
        if (self.targetClassNameHandler) {
            name = self.targetClassNameHandler(protocolName, name);
        }
    }
    return name;
}

- (SEL)invocationSelectorFromURL:(NSURL *)URL {
    return NSSelectorFromString([URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""]);
}

- (id)invocationParametersFromURL:(NSURL *)URL {
    id parameter = nil;
    switch (self.parserType) {
        case Array:
        case Dictionary:{
            NSMutableArray *array = (self.parserType == Array)?[NSMutableArray new]:nil;
            NSMutableDictionary *dictionary = (self.parserType == Dictionary)?[NSMutableDictionary new]:nil;
            parameter = (self.parserType == Array)?array:dictionary;
            NSString __block *query = URL.query;
            if (query.length > 0) {
                NSMutableDictionary *URLParameters = [NSMutableDictionary new];
                if ([query containsString:@"("] && [query containsString:@")"]) {
                    NSArray<NSString *> *URLComponents = [query componentsSeparatedByString:@"("];
                    [URLComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (idx > 0) {
                            NSArray *URLComponents1 = [obj componentsSeparatedByString:@")"];
                            NSString *URLKey = [NSString stringWithFormat:@"(%@)",@(idx)];
                            [URLParameters setObject:URLComponents1.firstObject forKey:URLKey];
                            query = [query stringByReplacingOccurrencesOfString:URLComponents1.firstObject
                                                                     withString:[@(idx) stringValue]];
                        }
                    }];
                }
                NSArray *components = [query componentsSeparatedByString:@"&"];
                [components enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSArray *elements = [obj componentsSeparatedByString:@"="];
                    if (elements.count == 2) {
                        id value = elements.lastObject;
                        if ([value isKindOfClass:[NSString class]]) {
                            if ([URLParameters.allKeys containsObject:value]) {
                                value = URLParameters[value];
                            }
                            NSString *string = (NSString *)value;
                            if (string.length == 0 || [string isEqualToString:@"null"]) {
                                value = [NSNull null];
                            }
                            else {
                                if (self.enableRecursiveParse && [[SFMediator sharedInstance] canOpenURL:string]) {
                                    value = [[SFMediator sharedInstance] openURL:string];
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

- (id)invocationParametersFromParameters:(NSDictionary *)parameters parameterIndexKeys:(NSArray<NSString *> *)parameterIndexKeys {
    NSMutableArray *indexParameters = [NSMutableArray new];
    [parameterIndexKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([parameters.allKeys containsObject:obj]) {
            [indexParameters addObject:parameters[obj]];
        }
        else {
            [indexParameters addObject:[NSNull null]];
        }
    }];
    return indexParameters;
}

- (void)invocation:(NSInvocation *)invocation setArgumentWithParameters:(id)parameters {
    //此处使用NSArray保证参数的顺序
    if ([parameters isKindOfClass:[NSArray class]]) {
        [(NSArray *)parameters enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            switch (SFValueTypeTransform([invocation.methodSignature getArgumentTypeAtIndex:idx + 2])) {
                case SFValueTypeBool:{
                    BOOL argument = NO;
                    if (![obj isEqual:[NSNull null]]) {
                        argument = [obj boolValue];;
                    }
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeInt:
                case SFValueTypeLong:{
                    NSInteger argument = 0;
                    if (![obj isEqual:[NSNull null]]) {
                        argument = [obj integerValue];;
                    }
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeFloat:{
                    float argument = 0.0;
                    if (![obj isEqual:[NSNull null]]) {
                        argument = [obj floatValue];
                    }
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                case SFValueTypeDouble:{
                    double argument = 0.0;
                    if (![obj isEqual:[NSNull null]]) {
                        argument = [obj doubleValue];
                    }
                    [invocation setArgument:&argument atIndex:idx + 2];
                }
                    break;
                default:{
                    if (![obj isEqual:[NSNull null]]) {
                        id argument = obj;
                        [invocation setArgument:&argument atIndex:idx + 2];
                    }
                }
                    break;
            }
        }];
    }
}

- (id)invoke:(NSInvocation *)invocation {
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

- (void)invokeFailureWithError:(SFMediatorError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[SFMediator Error]" message:error.message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    if ([UIApplication sharedApplication].keyWindow.rootViewController) {
        UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topRootViewController.presentedViewController){
            topRootViewController = topRootViewController.presentedViewController;
        }
        [topRootViewController presentViewController:alert animated:YES completion:nil];
    }
}

@end
