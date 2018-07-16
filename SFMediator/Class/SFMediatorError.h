//
//  SFMediatorError.h
//  QuanYouApp
//
//  Created by YunSL on 2018/7/13.
//  Copyright © 2018年 QuanYou. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,SFMediatorErrorCode) {
    SFMediatorErrorCodeNotRecognizeScheme = 1,
    SFMediatorErrorCodeNotRecognizeProtocolName = 2,
    SFMediatorErrorCodeNotRecognizeSelector = 3,
    SFMediatorErrorCodeInvalidInvocationTarget = 4
};

@interface SFMediatorError : NSObject
@property (nonatomic,assign) BOOL fromURL;
@property (nonatomic,assign) SFMediatorErrorCode code;
@property (nonatomic,copy) NSURL *URL;
@property (nonatomic,copy) NSString *protocolName;
@property (nonatomic,copy) NSString *selectorName;
@property (nonatomic,copy,readonly) NSString *message;
+ (SFMediatorError *)errorWithURL:(NSURL *)URL
                     protocolName:(NSString *)protocolName
                     selectorName:(NSString *)selectorName
                             code:(SFMediatorErrorCode)code;
@end
