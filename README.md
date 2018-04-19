SFMediator

设置用来识别URL的scheme

    [SFMediator sharedInstance].parser.invocationURLSchemes = @[@"demo"];

本地调用,为了方便调用和参数检验项目依赖于各组件对应的协议,协议根据需求由开发者和使用者共同维护或者只由某一方维护

    UIViewController *rootViewController = [[SFMediator app] rootViewControllerWithText:@"root" 
                         count:10 
                        number:3.1415926 
                         model:[UISwitch new] 
                        enable:YES];

远程调用,为了不定义各种参数key,暂时按严格的顺序传递和获取参数

    NSString *switchUrl = @"demo://app/rootSwitch";
    NSString *url = [NSString stringWithFormat:@"demo://app/rootViewControllerWithText:count:number:model:enable:?t=root&c=10&n=3.1415926&m=%@&e=1",switchUrl];
    UIViewController *rootViewController = [SFMediator openURL:url];

调用已声明但开发方尚未实现的方法

    [[SFMediator app] printCurrentDate];
