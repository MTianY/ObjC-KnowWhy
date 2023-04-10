//
//  TYBaseViewController.m
//  KVO
//
//  Created by 马天野 on 2018/8/16.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import "TYBaseViewController.h"
#import "TYPerson.h"
#import <objc/runtime.h>

#define TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY @"age"
#define TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY @"personAgeProperty_Context"

@interface TYBaseViewController ()

@property (nonatomic, strong) TYPerson *person;
@property (nonatomic, strong) TYPerson *person2;

@end

@implementation TYBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    TYPerson *person = [[TYPerson alloc] init];
    self.person = person;
//    person.age = 10;
    
    person -> age = 10;
    
    TYPerson *person2 = [[TYPerson alloc] init];
//    person2.age = 15;
    self.person2 = person2;
    
    NSLog(@"监听之前对应的类对象:%@---%@",object_getClass(person), object_getClass(person2));
    NSLog(@"监听之前实例对象对应的方法内存地址: %p--%p",[person methodForSelector:@selector(setAge:)], [person2 methodForSelector:@selector(setAge:)]);
    
    [person addObserver:self forKeyPath:TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY];
    
    NSLog(@"监听之后对应的类对象:%@---%@",object_getClass(person), object_getClass(person2));
    NSLog(@"监听之后实例对象对应的方法内存地址: %p--%p",[person methodForSelector:@selector(setAge:)], [person2 methodForSelector:@selector(setAge:)]);
    
    [self logMethodNameForClassObject:object_getClass(self.person)];
    [self logMethodNameForClassObject:object_getClass(self.person2)];
    
}

- (void)dealloc
{
    [self.person removeObserver:self forKeyPath:TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    [self.person setAge:20];
//
//    [self.person2 setAge:30];
    
    [self.person willChangeValueForKey:@"age"];
    self.person -> age = 1;
    [self.person didChangeValueForKey:@"age"];
  
    
}

// 监听方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY) {
        NSLog(@"监听到%@属性的改变:%@",object,change);
    }
}

#pragma mark - 打印类对象中所有的对象方法名称
- (void)logMethodNameForClassObject:(Class)class {
    unsigned int outCount;
    Method *methodList = class_copyMethodList(class, &outCount);
    NSMutableString *methodNamesMutString = [NSMutableString string];
    for (int i = 0; i < outCount; i++) {
        Method method = methodList[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        [methodNamesMutString appendString:methodName];
        [methodNamesMutString appendString:@", "];
    }
    free(methodList);
    
    NSLog(@"类对象: %@---方法名: %@\n",class,methodNamesMutString);
    
}


@end
