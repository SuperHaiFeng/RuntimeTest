//
//  NSMutableArray+SafeArray.h
//  RunTimeTest
//
//  Created by 志方 on 2018/4/24.
//  Copyright © 2018年 志方. All rights reserved.
//

///AOP为了避免我们在每次操作这些容器的时候都去判断数组是否为空，以及指针越界，使用method swizzling解决(所有的NSMutable开头的类)，这里只是使用数组做判断

#import <Foundation/Foundation.h>

@interface NSMutableArray (SafeArray)

@end
