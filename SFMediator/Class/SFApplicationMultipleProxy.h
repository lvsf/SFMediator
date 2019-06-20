//
//  SFMultipleDelegate.h
//  SFFormView
//
//  Created by YunSL on 17/10/20.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SFApplicationMultipleProxy : NSObject
@property (nonatomic,copy,readonly) NSPointerArray *proxies;
@property (nonatomic,weak) id originalProxy;
+ (instancetype)multipleProxyWithOriginalProxy:(id)originalProxy;
- (void)addProxy:(id)proxy;
- (void)removeProxy:(id)proxy;
- (void)removeAllProxies;
@end
