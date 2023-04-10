//
//  main.m
//  Class
//
//  Created by 马天野 on 2018/10/7.
//  Copyright © 2018 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TYPerson *person = [[TYPerson alloc] init];
        
        NSLog(@"[1]-%d",[person isMemberOfClass:[person class]]);
        NSLog(@"[2]-%d",[person isKindOfClass:[NSObject class]]);
        NSLog(@"[3]-%d",[TYPerson isMemberOfClass:[TYPerson class]]);
        NSLog(@"[4]-%d",[TYPerson isKindOfClass:[TYPerson class]]);
        NSLog(@"[5]-%d",[TYPerson isMemberOfClass:[NSObject class]]);
        NSLog(@"[6]-%d",[TYPerson isKindOfClass:[NSObject class]]);
        
        NSLog(@"[7]-%d",[TYPerson isMemberOfClass:object_getClass([TYPerson class])]);
        NSLog(@"[8]-%d",[TYPerson isKindOfClass:object_getClass([TYPerson class])]);
        NSLog(@"[9]-%d",[TYPerson isMemberOfClass:object_getClass([NSObject class])]);
        NSLog(@"[10]-%d",[TYPerson isKindOfClass:object_getClass([NSObject class])]);
        
    }
    return 0;
}
