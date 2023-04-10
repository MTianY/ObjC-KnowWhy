//
//  TYPerson.h
//  KVCDemo
//
//  Created by 马天野 on 2018/8/19.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TYStudent;
@interface TYPerson : NSObject

@property (nonatomic, assign) int age;
@property (nonatomic, strong) TYStudent *student;

@end
