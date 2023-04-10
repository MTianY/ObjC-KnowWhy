//
//  TYPerson.m
//  TYForwardingTest
//
//  Created by 马天野 on 2018/10/7.
//  Copyright © 2018 Maty. All rights reserved.
//

#import "TYPerson.h"

@implementation TYPerson

- (void)run {
    NSLog(@"%s",__func__);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    // 如果方法正确调用,那么就调用
    if ([self respondsToSelector:aSelector]) {
        return [super methodSignatureForSelector:aSelector];
    }
    
    // 如果方法找不到,返回一个非常普通的方法
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"找不到方法: %@",NSStringFromSelector(anInvocation.selector));
}

@end
