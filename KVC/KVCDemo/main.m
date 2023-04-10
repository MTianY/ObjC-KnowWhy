//
//  main.m
//  KVCDemo
//
//  Created by 马天野 on 2018/8/19.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"
#import "TYStudent.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
       
        TYPerson *person = [[TYPerson alloc] init];
        
        // 1.
        [person setValue:@10 forKey:@"age"];
        NSLog(@"Key: age = %@",[person valueForKey:@"age"]);
        
        // 2
        [person setValue:@20 forKeyPath:@"age"];
        NSLog(@"KeyPath: age = %@",[person valueForKeyPath:@"age"]);
        
        // 3.报错:
        // Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<TYPerson 0x1005394b0> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key weight.'
//        person.student = [[TYStudent alloc] init];
//        [person.student setValue:@30 forKey:@"weight"];
//        NSLog(@"key: weight = %@",[person.student valueForKey:@"weight"]);
        
        // 4.
        person.student = [[TYStudent alloc] init];
        [person.student setValue:@40 forKey:@"no"];
        NSLog(@"key: no = %@",[person.student valueForKey:@"no"]);
        
        // 5
        [person.student setValue:@60 forKeyPath:@"no"];
        NSLog(@"keyPath: no = %@",[person.student valueForKeyPath:@"no"]);
        
        // 6. 报错: Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<TYPerson 0x1007706d0> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key no.'
//        [person setValue:@100 forKey:@"no"];
//        NSLog(@"key: no",[person valueForKey:@"no"]);
        
        // 7.
        [person setValue:@134 forKeyPath:@"student.no"];
        NSLog(@"keyPath: %@",[person valueForKeyPath:@"student.no"]);
        
    }
    return 0;
}

