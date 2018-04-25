//
//  NSMutableArray+SafeArray.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/24.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "NSMutableArray+SafeArray.h"
#import <objc/runtime.h>

@implementation NSMutableArray (SafeArray)

+(void)load {
    [[self class] swizzleMethod:@selector(addObject:) withMethod:@selector(safeAddObject:)];
    [[self class] swizzleMethod:@selector(objectAtIndex:) withMethod:@selector(safeObjectAtIndex:)];
    [[self class] swizzleMethod:@selector(insertObject:atIndex:) withMethod:@selector(safeInsertObject:atIndex:)];
    [[self class] swizzleMethod:@selector(removeObjectAtIndex:) withMethod:@selector(safeRemoveObjectAtIndex:)];
    [[self class] swizzleMethod:@selector(replaceObjectAtIndex:withObject:) withMethod:@selector(safeReplaceObjectAtIndex:withObject:)];
}

#pragma mark - 魔法
-(void) safeAddObject: (id) anObject {
    if (anObject) {
        [self safeAddObject:anObject];
    }else {
        NSLog(@"anObject是nil");
    }
}

-(id) safeObjectAtIndex : (NSInteger) index {
    if (index >= 0 && index <= self.count) {
        return [self safeObjectAtIndex:index];
    }
    NSLog(@"index 越界了");
    return nil;
}

-(void) safeInsertObject : (id) object atIndex : (NSInteger) index{
    if (object && index >= 0 && index <= self.count) {
        [self safeInsertObject:object atIndex:index];
    }else {
        NSLog(@"object 或者 index 是无效的");
    }
}

-(void) safeRemoveObjectAtIndex : (NSInteger) index {
    if (index >= 0 && index <= self.count) {
        [self safeRemoveObjectAtIndex:index];
    }else {
        NSLog(@"index 不合法");
    }
}

-(void) safeReplaceObjectAtIndex : (NSInteger) index withObject: (id) object{
    if (object && index >= 0 && index <= self.count) {
        [self safeReplaceObjectAtIndex:index withObject:object];
    }else {
        NSLog(@"index 和 object 无效");
    }
}

+(void) swizzleMethod: (SEL) origSelector withMethod: (SEL) newSelector {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, origSelector);
    Method swizzledMethod = class_getInstanceMethod(class, newSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        origSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
