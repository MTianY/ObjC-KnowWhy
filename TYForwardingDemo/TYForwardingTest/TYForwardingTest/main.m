//
//  main.m
//  TYForwardingTest
//
//  Created by 马天野 on 2018/10/7.
//  Copyright © 2018 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYPerson.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TYPerson *person = [[TYPerson alloc] init];
        [person run];
        [person play];
        [person test];
        
    }
    return 0;
}
