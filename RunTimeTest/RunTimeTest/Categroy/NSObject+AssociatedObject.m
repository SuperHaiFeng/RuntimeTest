//
//  NSObject+AssociatedObject.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/4.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "NSObject+AssociatedObject.h"
#import <objc/runtime.h>

@implementation NSObject (AssociatedObject)
@dynamic associatedObject;

///通过runtime给类扩展添加属性
-(void)setAssociatedObject:(id)associatedObject {
    objc_setAssociatedObject(self, @selector(associatedObject), associatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(id)associatedObject {
    return objc_getAssociatedObject(self, @selector(associatedObject));
}

@end
