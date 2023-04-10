//
//  TYPerson.m
//  block-CircularReference
//
//  Created by 马天野 on 2018/9/7.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import "TYPerson.h"

@implementation TYPerson
- (void)dealloc {
    NSLog(@"%s",__func__);
}
@end
