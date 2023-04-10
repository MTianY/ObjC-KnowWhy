//
//  UIControl+Extension.m
//  TYButtonExtension
//
//  Created by 马天野 on 2018/10/27.
//  Copyright © 2018 Maty. All rights reserved.
//

#import "UIControl+Extension.h"
#import <objc/runtime.h>

@implementation UIControl (Extension)

+ (void)load {
    
    Method systemMethod = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
    Method myMethod = class_getInstanceMethod(self, @selector(ty_sendAction:to:forEvent:));
    method_exchangeImplementations(systemMethod, myMethod);
    
}

- (void)ty_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    NSLog(@"监听按钮点击操作--%s",__func__);
    
    
    [self ty_sendAction:action to:target forEvent:event];
    
}

@end
