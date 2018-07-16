//
//  SFMediatorError.m
//  QuanYouApp
//
//  Created by YunSL on 2018/7/13.
//  Copyright © 2018年 QuanYou. All rights reserved.
//

#import "SFMediatorError.h"

@implementation SFMediatorError
@synthesize message = _message;

+ (SFMediatorError *)errorWithURL:(NSURL *)URL protocolName:(NSString *)protocolName selectorName:(NSString *)selectorName code:(SFMediatorErrorCode)code {
    SFMediatorError *error = [SFMediatorError new];
    error.URL = URL;
    error.fromURL = URL;
    error.protocolName = protocolName;
    error.selectorName = selectorName;
    error.code = code;
    return error;
}

- (NSString *)message {
    return _message?:({
        switch (_code) {
            case SFMediatorErrorCodeNotRecognizeScheme:
                _message = [NSString stringWithFormat:@"无法响应的scheme:%@",_URL.scheme];
                break;
            case SFMediatorErrorCodeNotRecognizeProtocolName:
                _message = [NSString stringWithFormat:@"无法响应的protocol:%@",_protocolName];
                break;
            case SFMediatorErrorCodeNotRecognizeSelector:
                _message = [NSString stringWithFormat:@"无法响应的方法[%@ %@]",_protocolName,_selectorName];
                break;
            case SFMediatorErrorCodeInvalidInvocationTarget:
                _message = [NSString stringWithFormat:@"无法获取到正确的响应对象:%@",_protocolName];
                break;

        }
        _message;
    });
}

@end
