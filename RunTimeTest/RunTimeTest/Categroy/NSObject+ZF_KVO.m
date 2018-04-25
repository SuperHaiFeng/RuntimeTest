//
//  NSObject+ZF_KVO.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/12.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "NSObject+ZF_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

const void *keyOfZfKVOInfoModel = &keyOfZfKVOInfoModel;
NSString *kPreFixOfZFKVO = @"kPreFixOfZFKVO_";

@interface ZfKVOInfoModel: NSObject {
    void *_context;
}

-(void) setContext: (void *) context;
-(void *) getContext;
@property (nonatomic, weak) id target;
@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, assign) ZF_NSKeyValueObservingOptions options;
@end

@implementation ZfKVOInfoModel

-(void)dealloc {
    _context = NULL;
}

-(void)setContext:(void *)context {
    _context = context;
}

-(void *)getContext {
    return _context;
}
@end

static NSString * setterNameFromGetterName (NSString *getterName) {
    if (getterName.length < 1) return nil;
    NSString *setterName;
    setterName = [getterName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[getterName substringToIndex:1] uppercaseString]];
    setterName = [NSString stringWithFormat:@"set%@:",setterName];
    return setterName;
}

static NSString * getterNameFromSetterName (NSString *setterName) {
    if (setterName.length < 1 || ![setterName hasPrefix:@"set"] || ![setterName hasSuffix:@":"]) return nil;
    
    NSString *getterName;
    getterName = [setterName substringWithRange:NSMakeRange(3, setterName.length - 4)];
    getterName = [getterName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[getterName substringToIndex:1] lowercaseString]];
    return getterName;
}

static inline int classHasSel (Class class, SEL sel) {
    unsigned int outCount = 0;
    Method *methods = class_copyMethodList(class, &outCount);
    for (int i = 0 ; i < outCount; i++) {
        Method method = methods[i];
        SEL mSel = method_getName(method);
        if (mSel == sel) {
            free(methods);
            return 1;
        }
    }
    free(methods);
    return 0;
}

static void callBack (id target, id nValue, id oValue, NSString *getterName, BOOL notificationIsPrior) {
    NSMutableDictionary *dic = objc_getAssociatedObject(target, keyOfZfKVOInfoModel);
    if (dic && [dic valueForKey:getterName]) {
        NSMutableArray *tempArr = [dic valueForKey:getterName];
        for (ZfKVOInfoModel *info in tempArr) {
            if (info && info.observer && [info.observer respondsToSelector:@selector(zf_observerValueForKeyPath:ofObject:change:context:)]) {
                NSMutableDictionary *change = [NSMutableDictionary dictionary];
                if (info.options & ZF_NSKeyValueObservingOptionNew && nValue) {
                    [change setValue:nValue forKey:@"new"];
                }
                if (info.options & ZF_NSKeyValueObservingOptionOld && oValue) {
                    [change setObject:oValue forKey:@"old"];
                }
                if (notificationIsPrior) {
                    if (info.options & ZF_NSKeyValueObservingOptionPrior) {
                        [change setObject:@"1" forKey:@"notificationIsPrior"];
                    }else {
                        continue;
                    }
                }
                [info.observer zf_observerValueForKeyPath:info.keyPath ofObject:info.target change:change context:info.getContext];
            }
        }
    }
}

static void zf_kvo_setter (id target, SEL sel, id p0) {
    ///拿到调用父类方法之前的值
    NSString *getterName = getterNameFromSetterName(NSStringFromSelector(sel));
    id old = [target valueForKey:getterName];
    callBack(target, nil, old, getterName, YES);
    
    ///给父类发送消息
    struct objc_super sup = {
        .receiver = target,
        .super_class = class_getSuperclass(object_getClass(target))
    };
    ((void(*)(struct objc_super *, SEL, id)) objc_msgSendSuper)(&sup, sel, p0);
    
    ///回调相关
    callBack(target, p0, old, getterName, NO);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NSObject (ZF_KVO)
#pragma clang diagnostic pop

#pragma mark add
-(void)zf_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(ZF_NSKeyValueObservingOptions)options context:(void *)context {
    if (!observer || !keyPath) return;
    
    @synchronized(self) {
        ///给keyPath链条最终类做逻辑
        NSArray *keyArr = [keyPath componentsSeparatedByString:@"."];
        if (keyArr.count <= 0) return;
        id nextTarget = self;
        for (int i = 0; i < keyArr.count; i++) {
            nextTarget = [nextTarget valueForKey:keyArr[i]];
        }
        if (![self zf_coreLoginWithTarget:nextTarget getterName:keyArr.lastObject]) {
            return;
        }
        
        ///给目标类绑定信息
        ZfKVOInfoModel *info = [ZfKVOInfoModel new];
        info.target = self;
        info.observer = observer;
        info.keyPath = keyPath;
        info.options = options;
        [info setContext:context];
        [self zf_bindInfoToTarget:nextTarget info:info key:keyArr.lastObject options:options];
    }
    
}

- (void) zf_bindInfoToTarget: (id) target info: (ZfKVOInfoModel *) info key: (NSString *) key options: (ZF_NSKeyValueObservingOptions) options{
    NSMutableDictionary *dic = objc_getAssociatedObject(target, keyOfZfKVOInfoModel);
    if (dic) {
        if ([dic valueForKey:key]) {
            NSMutableArray *tempArr = [dic valueForKey:key];
            [tempArr addObject:info];
        }else {
            NSMutableArray *tempArr = [NSMutableArray array];
            [tempArr addObject:info];
            [dic setObject:tempArr forKey:key];
        }
    }else {
        NSMutableDictionary *addDic = [NSMutableDictionary dictionary];
        NSMutableArray *tempArr = [NSMutableArray array];
        [tempArr addObject:info];
        [addDic setObject:tempArr forKey:key];
        objc_setAssociatedObject(target, keyOfZfKVOInfoModel, addDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (options & ZF_NSKeyValueObservingOptionInitial) {
        callBack(target, nil, nil, key, NO);
    }
}

- (BOOL) zf_coreLoginWithTarget: (id) target getterName: (NSString *) getterName {
    ///若setter存在
    NSString *setterName = setterNameFromGetterName(getterName);
    SEL setterSel = NSSelectorFromString(setterName);
    Method setterMethod = class_getInstanceMethod(object_getClass(target), setterSel);
    
    ///创建派生类并且更改isa指针
    [self zf_createSubClassWithTarget:target];
    
    ///给派生类添加setter方法体
    if (!classHasSel(object_getClass(target), setterSel)) {
        const char *types = method_getTypeEncoding(setterMethod);
        return class_addMethod(object_getClass(target), setterSel, (IMP)zf_kvo_setter, types);
    }
    return YES;
}

///创建派生类
- (void) zf_createSubClassWithTarget: (id) target {
    ///若isa指向是否已经是派生类
    Class nowClass = object_getClass(target);
    NSString *nowClass_name = NSStringFromClass(nowClass);
    if ([nowClass_name hasPrefix:kPreFixOfZFKVO]) {
        return;
    }
    
    ///若派生类存在,但是isa没有指向派生类
    NSString *subClass_name = [kPreFixOfZFKVO stringByAppendingString:nowClass_name];
    Class subClass = NSClassFromString(subClass_name);
    if (subClass) {
        ///将该对象isa指针指向派生类
        object_setClass(target, subClass);
        return;
    }
    
    ///添加派生类,并且给派生类添加class方法体
    subClass = objc_allocateClassPair(nowClass, subClass_name.UTF8String, 0);
    const char *types = method_getTypeEncoding(class_getInstanceMethod(nowClass, @selector(class)));
    IMP class_imp = imp_implementationWithBlock(^Class(id target){
        return class_getSuperclass(object_getClass(target));
    });
    class_addMethod(subClass, @selector(class), class_imp, types);
    objc_registerClassPair(subClass);
    
    ///将该对象isa指针指向派生类
    object_setClass(target, subClass);
}


-(void)zf_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    [self zf_removeObserver:observer forKeyPath:keyPath context:nil];
}

-(void)zf_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    @synchronized(self) {
        ///移除配置信息
        NSArray *keyArr = [keyPath componentsSeparatedByString:@"."];
        if (keyArr.count <= 0) return;
        id nextTarget = self;
        for (int i = 0; i < keyArr.count - 1; i++) {
            nextTarget = [nextTarget valueForKey:keyArr[i]];
        }
        NSString *getterName = keyArr.lastObject;
        NSMutableDictionary *dic = objc_getAssociatedObject(nextTarget, keyOfZfKVOInfoModel);
        if (dic && [dic valueForKey:getterName]) {
            NSMutableArray *tempArr = [dic valueForKey:getterName];
            @autoreleasepool {
                for (ZfKVOInfoModel *info in tempArr.copy) {
                    if (info.getContext == context && info.observer == observer && [info.keyPath isEqualToString:keyPath]) {
                        [tempArr removeObject:info];
                    }
                }
            }
            if (tempArr.count == 0) {
                [dic removeObjectForKey:getterName];
            }
            ///若无可监听项，isa指针指回去
            if (dic.count <= 0) {
                Class nowClass = object_getClass(nextTarget);
                NSString *nowClass_name = NSStringFromClass(nowClass);
                if ([nowClass_name hasPrefix:kPreFixOfZFKVO]) {
                    Class superClass = [nextTarget class];
                    object_setClass(nextTarget, superClass);
                }
            }
        }
    }
}

@end
