//
//  UIViewController+MyUIViewController.m
//  RunTimeTest
//
//  Created by 志方 on 2018/3/22.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "UIViewController+MyUIViewController.h"
#import <objc/runtime.h>

@implementation UIViewController (MyUIViewController)

+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(viewWillAppear:);
        Method originalMethod = class_getInstanceMethod([self class], originalSelector);
        
        SEL exchangeSelector = @selector(myViewWillAppear:);
        Method exchangeMethod = class_getInstanceMethod([self class], exchangeSelector);
    
        BOOL didAddMethod = class_addMethod([self class], originalSelector, method_getImplementation(exchangeMethod), method_getTypeEncoding(exchangeMethod));
        if (didAddMethod) {
            class_replaceMethod([self class], exchangeSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        }else{
            ///交换两个方法的实现
            method_exchangeImplementations(originalMethod, exchangeMethod);
        }
    });
}

///可以实现在每一个页面都需要实现的同一个功能（method swizzling）
-(void) myViewWillAppear: (BOOL) animated {
    [self myViewWillAppear:animated];
    NSLog(@"myViewWillAppear%@",self);
}

@end
