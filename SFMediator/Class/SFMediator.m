//
//  SFMediator.m
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

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
    }  else {
        return SFValueObject;
    }
};

static inline NSURL* SFURLPraser(NSString *url) {
    NSString *encodeURL = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [NSURL URLWithString:encodeURL];
    return URL;
}

@implementation SFMediatorURLInvokeComponent @end

@interface SFMediatorDefaultParser : NSObject<SFMediatorProtocolParser>
@end

@implementation SFMediatorDefaultParser
@synthesize targetURLSchemeForInvoke = _targetURLSchemeForInvoke;

- (instancetype)init {
    if (self = [super init]) {
        self.targetURLSchemeForInvoke = @"App";
    }
    return self;
}

- (id)targetFromProtocol:(Protocol *)protocol {
    NSString *targetName = [[[NSString alloc] initWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding] stringByAppendingString:@"Target"];
    id target = nil;
    if ([NSClassFromString(targetName) respondsToSelector:@selector(new)]) {
        target = [NSClassFromString(targetName) new];
    }
    return target;
}

- (SFMediatorURLInvokeComponent *)targetInvokeComponentFromURL:(NSURL *)URL {
    SFMediatorURLInvokeComponent *component = [SFMediatorURLInvokeComponent new];
    component.scheme = URL.scheme;
    component.protocolName = [URL.host stringByAppendingString:@"Protocol"];
    component.selector = NSSelectorFromString([URL.path stringByReplacingOccurrencesOfString:@"/" withString:@""]);
    component.parameters = ({
        NSMutableDictionary *params = [NSMutableDictionary new];
        NSMutableArray *values = [NSMutableArray new];
        NSString *query = URL.query;
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
                        else if ([SFMediator canInvokeURL:string]) {
                            value = [SFMediator invokeURL:string];
                            value = value?:[NSNull null];
                        }
                    }
                    [params setObject:value
                               forKey:elements.firstObject];
                    [values addObject:value];
                }
            }];
        }
        component.parameterValues = values.copy;
        params;
    });
    return component;
}

- (void)invocation:(NSInvocation *)invocation setArgumentWithValues:(NSArray *)values {
    //此处使用NSArray保证参数的顺序
    [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

@interface SFMediatorItem : NSObject
@property (nonatomic,strong) id protocoltarget;
@property (nonatomic,strong) id protocolForwardTarget;
@property (nonatomic,copy) NSString *protocolName;
@end

@implementation SFMediatorItem

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if ([self.protocoltarget respondsToSelector:aSelector]) {
        signature = [self.protocoltarget methodSignatureForSelector:aSelector];
    }
    else if ([self.protocolForwardTarget respondsToSelector:aSelector]) {
        NSLog(@"protocol:%@ 转发未实现的方法[%@] => %@",self.protocolName,NSStringFromSelector(aSelector), NSStringFromClass([self.protocolForwardTarget class]));
        signature = [self.protocolForwardTarget methodSignatureForSelector:aSelector];
    }
    else {
        NSLog(@"protocol:%@ 抛弃未实现的方法[%@]",self.protocolName,NSStringFromSelector(aSelector));
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.protocoltarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocoltarget];
    } else if ([self.protocolForwardTarget respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.protocolForwardTarget];
    } else {
    }
}

@end

@interface SFMediator()
@property (nonatomic,strong) NSMutableDictionary *mediatorItems;
@end

@implementation SFMediator

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (BOOL)canInvokeURL:(NSString *)url {
    SFMediator *manager = [self sharedInstance];
    NSURL *URL = SFURLPraser(url);
    BOOL can = NO;
    if (URL) {
        if ([URL.scheme isEqualToString:[manager.parser targetURLSchemeForInvoke]]) {
            if (URL.path.length > 0) {
                can = YES;
            }
        }
    }
    return can;
}

+ (id)invokeURL:(NSString *)url {
    id returnValue = nil;
    if ([self canInvokeURL:url]) {
        SFMediator *manager = [self sharedInstance];
        SFMediatorURLInvokeComponent *component = [manager.parser targetInvokeComponentFromURL:SFURLPraser(url)];
        SFMediatorItem *mediatorItem = [self invokeTargetWithProtocol:objc_getProtocol(component.protocolName.UTF8String) forwardTarget:component.forwardTarget];
        NSMethodSignature *signature = [mediatorItem methodSignatureForSelector:component.selector];
        if (mediatorItem && signature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:mediatorItem];
            [invocation setSelector:component.selector];
            [manager.parser invocation:invocation setArgumentWithValues:component.parameterValues];
            returnValue = [manager.parser invocationGetReturnValue:invocation];
        }
    }
    return returnValue;
}

+ (id)invokeTargetWithProtocol:(Protocol *)protocol forwardTarget:(id)forwardTarget {
    SFMediator *manager = [self sharedInstance];
    SFMediatorItem *mediatorItem = nil;
    NSString *protocolName = [[NSString alloc] initWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding];
    if (protocolName.length > 0) {
        mediatorItem = [manager.mediatorItems objectForKey:protocolName];
        if (mediatorItem == nil) {
            mediatorItem = [SFMediatorItem new];
            mediatorItem.protocolName = protocolName;
            mediatorItem.protocolForwardTarget = forwardTarget;
            mediatorItem.protocoltarget = [manager.parser targetFromProtocol:protocol];
            manager.mediatorItems[protocolName] = mediatorItem;
        }
    }
    return mediatorItem;
}

- (NSMutableDictionary *)mediatorItems {
    return _mediatorItems?:({
        _mediatorItems = [NSMutableDictionary new];
        _mediatorItems;
    });
}

- (id<SFMediatorProtocolParser>)parser {
    return _parser?:({
        _parser = [SFMediatorDefaultParser new];
        _parser;
    });
}

@end
