//
//  main.m
//  Objective-C Object
//
//  Created by 马天野 on 2018/8/7.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        NSObject *objc = [[NSObject alloc] init];
        
        // 获取 NSObject 实例对象的成员变量在内存中所占的大小
        NSUInteger ivarSize = class_getInstanceSize([NSObject class]);
        NSLog(@"%zd", ivarSize);
        
        // 获取 objc 指针指向内存空间的大小
        NSUInteger pointAddressSize = malloc_size((__bridge const void *)(objc));
        NSLog(@"%zd", pointAddressSize);
        
    }
    return 0;
}
