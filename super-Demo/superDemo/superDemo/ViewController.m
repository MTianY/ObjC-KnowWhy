//
//  ViewController.m
//  superDemo
//
//  Created by 马天野 on 2018/10/8.
//  Copyright © 2018 Maty. All rights reserved.
//

#import "ViewController.h"
#import "TYPerson.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *name = @"mty";
//    NSObject *obj2 = [[NSObject alloc] init];
//
    id cls = [TYPerson class];
    
    void *obj = &cls;
    
    [(__bridge id)obj log];
    
//    [self test];
    
}

- (void)test {
    int a = 40;     // 0x7ffee7e7e9ec
    int b = 100;    // 0x7ffee7e7e9e8
    int c = 300;    // 0x7ffee7e7e9e4
    NSLog(@"%p--%p--%p",&a,&b,&c);
}


@end
