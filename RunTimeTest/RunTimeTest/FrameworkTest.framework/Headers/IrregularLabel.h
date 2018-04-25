//
//  IrregularLabel.h
//  RunTimeTest
//
//  Created by 志方 on 2018/4/8.
//  Copyright © 2018年 志方. All rights reserved.
//

/**
    自定义不规则的label
 */

#import <UIKit/UIKit.h>

@interface IrregularLabel : UILabel

///遮罩
@property (nonatomic, strong) CAShapeLayer *maskLayer;

///路径
@property(nonatomic, strong) UIBezierPath *borderPath;

@end
