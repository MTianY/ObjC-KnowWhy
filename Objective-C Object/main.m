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

@interface TYPerson : NSObject

{
    @public
    int no;
    int age;
}

@property (nonatomic, assign) int height;

@end

@implementation TYPerson

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        /******* NSObject *******/
        NSObject *objc = [[NSObject alloc] init];
        
        // 获取 NSObject 实例对象的成员变量在内存中所占的大小
        NSUInteger objc_ivarSize = class_getInstanceSize([NSObject class]);
        NSLog(@"objc_ivarSize = %zd\n", objc_ivarSize);
        
        // 获取 objc 指针指向内存空间的大小
        NSUInteger objc_pointAddressSize = malloc_size((__bridge const void *)(objc));
        NSLog(@"objc_pointAddressSize = %zd\n", objc_pointAddressSize);
        
        
        /******* TYPerson *******/
        TYPerson *person = [[TYPerson alloc] init];
        NSUInteger person_ivarSize = class_getInstanceSize([TYPerson class]);
        NSLog(@"person_ivarSize = %zd\n",person_ivarSize);
        
        NSUInteger person_pointAddressSize = malloc_size((__bridge const void *)(person));
        NSLog(@"person_pointAddressSize = %zd",person_pointAddressSize);
        
    }
    return 0;
}
