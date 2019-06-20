//
//  ViewController.m
//  SFMediator
//
//  Created by YunSL on 17/9/4.
//  Copyright © 2017年 YunSL. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic,strong) UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.label = [UILabel new];
    self.label.text = @"123";
    self.label.font = [UIFont boldSystemFontOfSize:30];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor greenColor];
    
    [self.view addSubview:self.label];
    
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.label setFrame:self.view.bounds];
}

@end
