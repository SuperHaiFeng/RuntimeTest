//
//  UIButton+EnlargeTouchAre.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/3.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "UIButton+EnlargeTouchAre.h"
#import <objc/runtime.h>

static char topNameKey;
static char rightNameKey;
static char bottomNameKey;
static char leftNameKey;

@implementation UIButton (EnlargeTouchAre)

///使用runtime实现按钮的扩展点击区域
-(void) setEnlargeEdgeWithTop: (CGFloat) top right: (CGFloat) right bottom: (CGFloat) bottom left:(CGFloat) left{
    ///objc_setAssociatedObject是一个C语言函数，这个函数被称之为“关联API”，它的作用是把top、right、bottom、left这四个从外界获取到的值与本类(self)关联起来，然后设置一个static char作为能够找到他们的Key
    objc_setAssociatedObject(self, &topNameKey, [NSNumber numberWithFloat:top], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &rightNameKey, [NSNumber numberWithFloat:right], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &bottomNameKey, [NSNumber numberWithFloat:bottom], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &leftNameKey, [NSNumber numberWithFloat:left], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/// objc_getAssociatedObject同样也是一个关联API(c语言函数)，它可以通过刚刚设置的Key找到上个方法中从外界传入的top、right、bottom、left，这个api和obj_setAssociatedObject一起使用就可以达到给已有类扩展属性的效果。最后我们通过self.bounds设置一个新的CGRect，作为扩大后的点按区域
-(CGRect) enlargeRect {
    NSNumber *topEdge = objc_getAssociatedObject(self, &topNameKey);
    NSNumber *rightEdge = objc_getAssociatedObject(self, &rightNameKey);
    NSNumber *bottomEdge = objc_getAssociatedObject(self, &bottomNameKey);
    NSNumber *leftEdge = objc_getAssociatedObject(self, &leftNameKey);
    
    if (topEdge && rightEdge && bottomEdge && leftEdge) {
        return CGRectMake(self.bounds.origin.x - leftEdge.floatValue,
                          self.bounds.origin.y - topEdge.floatValue,
                          self.bounds.size.width + leftEdge.floatValue + rightEdge.floatValue,
                          self.bounds.size.height + topEdge.floatValue + bottomEdge.floatValue);
    }else {
        return self.bounds;
    }
}

///捕获当前的UITouch事件中的触摸点，检测它是否在最上层的子视图内，如果不是的话就递归检测其父视图,将当前某一个触摸的point与某一个rect进行比较，并没有改变Button真实的frame，从而真正的从逻辑上达到了只是扩大点按区域的效果。
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect rect = [self enlargeRect];
    if (CGRectEqualToRect(rect, self.bounds)) {
        return [super hitTest:point withEvent:event];
    }
    
    return CGRectContainsPoint(rect, point) ? self : nil;
}


@end
