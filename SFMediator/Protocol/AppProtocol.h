//
//  AppProtocol.h
//  SFMediator
//
//  Created by YunSL on 17/9/12.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol AppProtocol <NSObject>
- (UISwitch*)rootSwitch;
- (void)printCurrentDate;
- (UIViewController*)rootViewControllerWithText:(NSString*)text
                                          count:(NSInteger)count
                                         number:(CGFloat)number
                                          model:(id)model
                                         enable:(BOOL)enable;
@end
