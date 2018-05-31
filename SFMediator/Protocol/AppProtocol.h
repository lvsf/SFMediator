//
//  AppProtocol.h
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "SFMediatorTargetProtocol.h"

@protocol AppProtocol <SFMediatorTargetProtocol>
@optional
- (void)printCurrentDate;
- (UISwitch *)rootSwitch;
- (id)test:(void(^)(void))a;
- (UIViewController *)rootViewControllerWithText:(NSString*)text
                                          count:(NSInteger)count
                                         number:(CGFloat)number
                                          model:(id)model
                                         enable:(BOOL)enable;
@end
