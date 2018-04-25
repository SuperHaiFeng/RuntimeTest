//
//  UIButton+EnlargeTouchAre.h
//  RunTimeTest
//
//  Created by 志方 on 2018/4/3.
//  Copyright © 2018年 志方. All rights reserved.
//

/***
    通过runtime给扩大按钮点击范围
 */

#import <UIKit/UIKit.h>

@interface UIButton (EnlargeTouchAre)

-(void) setEnlargeEdgeWithTop: (CGFloat) top right: (CGFloat) right bottom: (CGFloat) bottom left:(CGFloat) left;

@end
