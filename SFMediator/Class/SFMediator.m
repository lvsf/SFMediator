//
//  SFMediator.m
//  SFMediator
//
//  Created by YunSL on 17/8/15.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediator.h"
#import "SFMediatorParser.h"

inline BOOL SFMediatorShouldSwizzleSEL(SEL originalSEL) {
    return [NSStringFromSelector(originalSEL) hasPrefix:@"application"];
}

inline SEL SFMediatorSwizzleSEL(SEL originalSEL) {
    return NSSelectorFromString([NSString stringWithFormat:@"_sf_mediator_%@",NSStringFromSelector(originalSEL)]);
};

static inline NSURL *SFURLParser(NSString *url) {
    NSString *encodeURL = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [NSURL URLWithString:encodeURL];
    return URL;
}

static inline void SFMediatorLog(NSString *message) {
#ifdef DEBUG
    NSLog(@"[SFMediator] %@",message);
#endif
};

@interface SFMediatorErrorHandler : NSObject
@end

@implementation SFMediatorErrorHandler
- (void)doNothing {}
- (void)forwardInvocation:(NSInvocation *)anInvocation {}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [super methodSignatureForSelector:@selector(doNothing)];
}
@end

#pragma mark - SFMediator
@interface SFMediator()<UIApplicationDelegate>;
@property (nonatomic,strong) NSMutableDictionary<NSString *,id> *targets;
@property (nonatomic,strong) NSMutableDictionary<NSString *,NSDictionary *> *mappedRoutes;
@property (nonatomic,strong) SFMediatorErrorHandler *errorHandler;
@end

@implementation SFMediator

#pragma mark - public
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

+ (BOOL)respondsToSelectorByTargets:(SEL)selector {
    __block BOOL responds = NO;
    [[SFMediator sharedInstance].targets enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:selector]) {
            responds = YES;
            *stop = YES;
        }
    }];
    return responds;
}

- (BOOL)canOpenURL:(NSString *)url {
    SFMediatorError *error = [self _canOpenURL:SFURLParser(url)];
    return !error;
}

- (id)openURL:(NSString *)url {
    NSURL *URL = SFURLParser(url);
    SFMediatorError *error = [self _canOpenURL:URL];;
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    NSString *protocolName = [self.parser invocationProtocolNameFromURL:URL];
    if (!protocolName || !objc_getProtocol(protocolName.UTF8String)) {
        error = [SFMediatorError errorWithURL:URL
                                 protocolName:protocolName
                                 selectorName:nil
                                         code:SFMediatorErrorCodeNotRecognizeProtocolName];
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    id target = [self _invokeTargetFromProtocolName:protocolName];
    if (!target) {
        error = [SFMediatorError errorWithURL:URL
                                 protocolName:protocolName
                                 selectorName:nil
                                         code:SFMediatorErrorCodeInvalidInvocationTarget];
        
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    SEL selector = [self.parser invocationSelectorFromURL:URL];
    if (![target respondsToSelector:selector]) {
        error = [SFMediatorError errorWithURL:URL
                                 protocolName:protocolName
                                 selectorName:NSStringFromSelector(selector)
                                         code:SFMediatorErrorCodeNotRecognizeSelector];
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    id parameter = [self.parser invocationParametersFromURL:URL];
    id returnValue = [self _invokeWithTarget:target selector:selector parameters:parameter];
    SFMediatorLog([NSString stringWithFormat:@"open success URL:%@ \nparameter:%@ \nreturnValue:%@",url,parameter,returnValue]);
    return returnValue;
}

- (BOOL)canOpenRoute:(NSString *)route {
    SFMediatorError *error = [self _canOpenRoute:route];
    return !error;
}

- (id)openRoute:(NSString *)route withParameters:(NSDictionary *)parameters parameterIndexKeys:(NSArray<NSString *> *)parameterIndexKeys {
    SFMediatorError *error = [self _canOpenRoute:route];;
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    NSString *protocolName = self.mappedRoutes[route][@"protocol"];
    if (!protocolName || !objc_getProtocol(protocolName.UTF8String)) {
        error = [SFMediatorError errorWithRoute:route
                                   protocolName:protocolName
                                   selectorName:nil
                                           code:SFMediatorErrorCodeNotRecognizeProtocolName];
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    id target = [self _invokeTargetFromProtocolName:protocolName];
    if (!target) {
        error = [SFMediatorError errorWithRoute:route
                                  protocolName:protocolName
                                  selectorName:nil
                                          code:SFMediatorErrorCodeInvalidInvocationTarget];
        
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    NSString *selectorName = self.mappedRoutes[route][@"selector"];
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) {
        error = [SFMediatorError errorWithRoute:route
                                   protocolName:protocolName
                                   selectorName:selectorName
                                           code:SFMediatorErrorCodeNotRecognizeSelector];
    }
    if (error) {
        [self _invokeFailureWithError:error];
        return nil;
    }
    id invocationParameters = [self.parser invocationParametersFromParameters:parameters
                                                           parameterIndexKeys:parameterIndexKeys];
    id returnValue = [self _invokeWithTarget:target selector:selector parameters:invocationParameters];
    SFMediatorLog([NSString stringWithFormat:@"open success route:%@ \nselector:[%@] \nparameter:%@ \nreturnValue:%@",route,selectorName,parameters,returnValue]);
    return returnValue;
}

- (void)mappedRoute:(NSString *)route toSEL:(SEL)selector atProtocol:(Protocol *)protocol {
    NSString *protocolName = [NSString stringWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding];
    NSString *selectorName = NSStringFromSelector(selector);
    if (route && protocolName && selectorName) {
        [self.mappedRoutes setObject:@{@"protocol":protocolName,@"selector":selectorName} forKey:route];
    }
}

- (id)invokeTargetFromProtocol:(Protocol *)protocol {
    NSAssert(protocol, [NSString stringWithFormat:@"[SFMediator] invokeTargetFromProtocol: protocol不能为空"]);
    NSString *protocolName = [NSString stringWithCString:protocol_getName(protocol) encoding:NSUTF8StringEncoding];
    id target = [self _invokeTargetFromProtocolName:protocolName];
    if (!target) {
        [self _invokeFailureWithError:[SFMediatorError errorWithURL:nil
                                                       protocolName:protocolName
                                                       selectorName:nil
                                                               code:SFMediatorErrorCodeInvalidInvocationTarget]];
    }
    return target;
}

#pragma mark - private
- (SFMediatorError *)_canOpenURL:(NSURL *)URL {
    if (!URL.scheme || ![self.parser.invocationRecognizedURLSchemes containsObject:URL.scheme]) {
        return [SFMediatorError errorWithURL:URL
                                protocolName:nil
                                selectorName:nil
                                        code:SFMediatorErrorCodeNotRecognizeScheme];
    }
    return nil;
}

- (SFMediatorError *)_canOpenRoute:(NSString *)route {
    if (!route || ![self.mappedRoutes objectForKey:route]) {
        return [SFMediatorError errorWithRoute:route
                                  protocolName:nil
                                  selectorName:nil
                                          code:SFMediatorErrorCodeNotRecognizeRoute];
    }
    return nil;
}

- (id)_invokeWithTarget:(id)target selector:(SEL)selector parameters:(id)parameters {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    [self.parser invocation:invocation setArgumentWithParameters:parameters];
    return [self.parser invoke:invocation];
}

- (id)_invokeTargetFromProtocolName:(NSString *)protocolName {
    id target = self.targets[protocolName];
    if (target == nil) {
        //此处将协议调用对象所有的不存在调用都做转发处理,即使是不属于协议方法里的不存在调用也会被处理而不抛出系统错误
        //修改方法:对协议里的所有方法做缓存,然后在转发处理时判断该方法是否属于协议里的方法
        NSString *targetClassName = [self.parser invocationTargetClassNameFromProtocolName:protocolName];
        if ([NSClassFromString(targetClassName) respondsToSelector:@selector(new)]) {
            target = [NSClassFromString(targetClassName) new];
            Class originalClass = [target class];
            SEL originalSEL = @selector(forwardingTargetForSelector:);
            SEL newSEL = SFMediatorSwizzleSEL(originalSEL);
            id (^implementation)(id, SEL) = ^(id obj, SEL selector) {
                [self _invokeFailureWithError:[SFMediatorError errorWithURL:nil
                                                                protocolName:protocolName
                                                                selectorName:NSStringFromSelector(selector)
                                                                        code:SFMediatorErrorCodeNotRecognizeSelector]];
                return self.errorHandler;
            };
            class_addMethod(originalClass, originalSEL,
                            class_getMethodImplementation(originalClass, originalSEL),
                            method_getTypeEncoding(class_getInstanceMethod(originalClass, originalSEL)));
            class_addMethod(originalClass, newSEL,
                            imp_implementationWithBlock(implementation),
                            method_getTypeEncoding(class_getInstanceMethod(originalClass, originalSEL)));
            method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSEL),
                                           class_getInstanceMethod(originalClass, newSEL));
            self.targets[protocolName] = target;
        }
    }
    return target;
}

- (void)_invokeFailureWithError:(SFMediatorError *)error {
    SFMediatorLog(error.message);
    if ([self.parser respondsToSelector:@selector(invokeFailureWithError:)]) {
        [self.parser invokeFailureWithError:error];
    }
}
 
#pragma mark - set/get
- (id<SFMediatorParserProtocol>)parser {
    return _parser?:({
        _parser = [SFMediatorParser new];
        _parser;
    });
}

- (SFMediatorErrorHandler *)errorHandler {
    return _errorHandler?:({
        _errorHandler = [SFMediatorErrorHandler new];
        _errorHandler;
    });
}

- (NSMutableDictionary<NSString *,NSDictionary *> *)mappedRoutes {
    return _mappedRoutes?:({
        _mappedRoutes = [NSMutableDictionary new];
        _mappedRoutes;
    });
}

- (NSMutableDictionary<NSString *,id> *)targets {
    return _targets?:({
        _targets = [NSMutableDictionary new];
        _targets;
    });
}

- (NSArray<id<SFMediatorTargetProtocol>> *)allTargets {
    return self.targets.allValues;
}

@end
