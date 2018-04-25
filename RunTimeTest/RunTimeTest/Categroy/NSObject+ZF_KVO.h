//
//  NSObject+ZF_KVO.h
//  RunTimeTest
//
//  Created by 志方 on 2018/4/12.
//  Copyright © 2018年 志方. All rights reserved.
//

///简单重新实现KVO机制
#import <Foundation/Foundation.h>

///这个宏定义所有简单指针对象都被假定为nonnull，因此我们只需要去指定那些nullable的指针
NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ZF_NSKeyValueObservingOptions) {
    ZF_NSKeyValueObservingOptionNew = 0x01,
    ZF_NSKeyValueObservingOptionOld = 0x02,
    ZF_NSKeyValueObservingOptionInitial = 0x04,
    ZF_NSKeyValueObservingOptionPrior = 0x08
};

@interface NSObject (ZF_KVO)

///添加监听
- (void) zf_addObserver: (NSObject *) observer forKeyPath: (NSString *) keyPath options: (ZF_NSKeyValueObservingOptions) options context: (nullable void *) context;

///移除监听
- (void) zf_removeObserver: (NSObject *) observer forKeyPath: (NSString *) keyPath context: (nullable void *) context;

- (void) zf_removeObserver: (NSObject *) observer forKeyPath: (NSString *) keyPath;

///回调方法
- (void) zf_observerValueForKeyPath: (nullable NSString *) keyPath ofObject: (nullable id) object change: (nullable NSDictionary *) change context: (nullable void *) context;


@end

NS_ASSUME_NONNULL_END
