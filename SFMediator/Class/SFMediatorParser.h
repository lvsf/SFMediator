//
//  SFMediatorParser.h
//  SFMediator
//
//  Created by YunSL on 2018/4/12.
//  Copyright © 2018年 YunSL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFMediatorParserProtocol.h"

typedef NS_ENUM(NSInteger,SFMediatorParserType) {
    Array = 0,
    Dictionary
};

@interface SFMediatorParser : NSObject<SFMediatorParserProtocol>
@property (nonatomic,assign) BOOL enableRecursiveParse;
@property (nonatomic,assign) SFMediatorParserType parserType;
@property (nonatomic,copy) NSString *(^targetClassNameHandler)(NSString *protocolName, NSString *originalClassName);
@end
