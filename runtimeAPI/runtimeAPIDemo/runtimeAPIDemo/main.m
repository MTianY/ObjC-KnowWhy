//
//  main.m
//  runtimeAPIDemo
//
//  Created by 马天野 on 2018/10/8.
//  Copyright © 2018 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"
#import <objc/runtime.h>
#import "TYAnimal.h"

void run(id self, SEL _cmd) {
    NSLog(@"%@--%@",self, NSStringFromSelector(_cmd));
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TYPerson *person = [[TYPerson alloc] init];
        [person run];
        
        // 传入一个对象,获取其 isa 指向的 Class 对象
//        NSLog(@"%p---%p",object_getClass(person), [TYPerson class]);
//        NSLog(@"%p---%p",object_getClass([TYPerson class]), [TYPerson class]);
        
        // 修改传入进来对象的 isa 指向
//        object_setClass(person, [TYAnimal class]);
//        [person run];
        
//        NSLog(@"%d---%d----%d",object_isClass(person), object_isClass([TYPerson class]), object_isClass(object_getClass([TYPerson class])));
        
//        // 动态创建这个类
//        Class newClass = objc_allocateClassPair([NSObject class], "TYDog", 0);
//
//        // 动态添加成员变量
//        class_addIvar(newClass, "_age", 4, 1, @encode(int));
//        class_addIvar(newClass, "_weight", 4, 1, @encode(int));
//
//        // 动态添加方法
//        class_addMethod(newClass, @selector(run), (IMP)run, "v@:");
//
//        // 注册类
//        objc_registerClassPair(newClass);
//
//        // 使用动态创建的这个类
//        id dog = [[newClass alloc] init];
//        [dog setValue:@10 forKey:@"_age"];
//        [dog setValue:@30 forKey:@"_weight"];
//        [dog run];
//
//        NSLog(@"%@---%@",[dog valueForKey:@"_age"], [dog valueForKey:@"_weight"]);
        
        // 获取成员变量信息
        Ivar nameIvar = class_getInstanceVariable([TYPerson class], "_name");
        Ivar ageIvar = class_getInstanceVariable([TYPerson class], "_age");
        NSLog(@"\n%s %s\n%s %s", ivar_getName(nameIvar), ivar_getTypeEncoding(nameIvar), ivar_getName(ageIvar), ivar_getTypeEncoding(ageIvar));
        
        object_setIvar(person, nameIvar, @"mty");
        object_setIvar(person, ageIvar, @10);
        
        NSLog(@"\nname = %@\n age = %@",object_getIvar(person, nameIvar), object_getIvar(person, ageIvar));
        
        
        
        // 获取所有的成员变量信息
        // 成员变量的数量
        unsigned int count;
        Ivar *ivars = class_copyIvarList([TYPerson class], &count);
        for (int i = 0; i<count; i++) {
            // 取出 i 位置的成员变量
            Ivar ivar = ivars[i];
            NSLog(@"%s  %s", ivar_getName(ivar), ivar_getTypeEncoding(ivar));
        }
        // 释放
        free(ivars);
        
    }
    return 0;
}
