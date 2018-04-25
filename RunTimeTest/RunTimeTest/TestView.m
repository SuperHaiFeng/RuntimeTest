//
//  TestView.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/2.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "TestView.h"

@implementation TestView


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"点击了圆形" delegate:nil cancelButtonTitle:@"" otherButtonTitles:@"", nil];
    [alert show];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 200, 200)];
    return [path containsPoint:point];
}

+(BOOL)resolveInstanceMethod:(SEL)sel {
    
    return YES;
}

@end
