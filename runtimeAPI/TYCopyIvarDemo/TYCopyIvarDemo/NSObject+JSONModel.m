//
//  NSObject+JSONModel.m
//  TYCopyIvarDemo
//
//  Created by 马天野 on 2018/10/26.
//  Copyright © 2018 Maty. All rights reserved.
//

#import "NSObject+JSONModel.h"
#import <objc/runtime.h>

@implementation NSObject (JSONModel)

+ (instancetype)ty_objectWithJSON:(NSDictionary *)jsonDict {
    
    NSObject *obj = [[self alloc] init];
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList(self, &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        NSMutableString *name = [NSMutableString stringWithUTF8String:ivar_getName(ivar)];
        NSString *newName = [name substringFromIndex:1];
        NSLog(@"name = %@",newName);
        [obj setValue:jsonDict[newName] forKey:newName];
    }
    
    return obj;
    
}

@end
