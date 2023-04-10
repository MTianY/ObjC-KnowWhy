//
//  main.m
//  KVC-ValueforKey
//
//  Created by 马天野 on 2018/8/19.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TYPerson *person = [[TYPerson alloc] init];
        
        [person setValue:@10 forKey:@"age"];
        
        NSLog(@"%@",[person valueForKey:@"age"]);
        
    }
    return 0;
}

