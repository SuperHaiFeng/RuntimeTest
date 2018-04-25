//
//  Person.m
//  RunTimeTest
//
//  Created by 志方 on 2018/3/22.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "Person.h"
#import <objc/runtime.h>

@implementation Person

@synthesize name = _name;
@synthesize age = _age;

-(instancetype) initWithName : (NSString *) name age:(NSInteger) age {
    if (self = [super init]) {
        self.name = name;
        self.age = age;
    }
    return self;
}

-(void)showMyself {
    NSLog(@"hello %@  %ld",self.name, self.age);
}

-(void)helloWorld {
    NSLog(@"你好，世界");
}

///如果需要传参数直接在参数列表后面加
void dynamicAdditionMethodIMP(id self, SEL _cmd) {
    NSLog(@"dynamicAdditionMethodIMP");
}
/**
    消息转发：对象所属类动态方法解析(发送消息没有找到对应的方法时请求)
 */
///第一次机会
+(BOOL)resolveInstanceMethod:(SEL)sel {
    NSLog(@"resolveInstanceMethod:%@",NSStringFromSelector(sel));
    if (sel == @selector(appendString:)) {
        class_addMethod([self class], sel, (IMP)dynamicAdditionMethodIMP, "V@:");
        
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

+(BOOL)resolveClassMethod:(SEL)sel {
    NSLog(@"resolveClassMethod:%@",NSStringFromSelector(sel));
    return [super resolveClassMethod:sel];
    
}

/**
    第二次机会：备援接受者
    询问该实例对象是否有其他实例对象可以接收这个未知的selector，如果没有就返回nil
 */
-(id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"forwardingTargetForSelector");
    return nil;
}

/**
    第三次机会：消息重定向
    (一直到NSObject,如果都无法处理就调用doesNotRecognizeSelector：方法抛出异常)
 */
-(void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"forwardInvocation:%@",anInvocation);
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        ///这里应该用新创建的一个类进行判断和赋值，我直接使用本类了
        if ([[self class] instancesRespondToSelector:aSelector]) {
            signature = [[self class] instanceMethodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

@end
