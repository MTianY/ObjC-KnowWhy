//
//  TYPerson.h
//  block-CircularReference
//
//  Created by 马天野 on 2018/9/7.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Test1Block)(void);
@interface TYPerson : NSObject
@property (nonatomic, copy) Test1Block test1Block;
@property (nonatomic, assign) int age;


@end
