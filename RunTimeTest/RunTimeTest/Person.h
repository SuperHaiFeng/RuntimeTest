//
//  Person.h
//  RunTimeTest
//
//  Created by 志方 on 2018/3/22.
//  Copyright © 2018年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

-(instancetype) initWithName : (NSString *) name age:(NSInteger) age;
-(void) showMyself;
-(void) helloWorld;

@end
