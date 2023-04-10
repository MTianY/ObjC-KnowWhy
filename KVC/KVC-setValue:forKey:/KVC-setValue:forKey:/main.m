//
//  main.m
//  KVC-setValue:forKey:
//
//  Created by 马天野 on 2018/8/19.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"
#import "TYObserver.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TYPerson *person = [[TYPerson alloc] init];
        
        TYObserver *observer = [[TYObserver alloc] init];
        [person addObserver:observer forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
        [person setValue:@10 forKey:@"age"];
        
    }
    return 0;
}
