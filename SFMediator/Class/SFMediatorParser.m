//
//  SFMediatorParser.m
//  SFMediator
//
//  Created by YunSL on 2018/4/12.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import "SFMediatorParser.h"
#import "SFMediator.h"
#import "NSInvocation+SFAdd.h"
#import <objc/runtime.h>

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
            [invocation lv_setArgument:obj atIndex:idx + 2];
        }];
    }
}

- (id)invoke:(NSInvocation *)invocation {
    return [invocation lv_invoke];
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
