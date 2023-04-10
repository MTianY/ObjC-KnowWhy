//
//  TYObserver.m
//  KVC-setValue:forKey:
//
//  Created by 马天野 on 2018/8/19.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import "TYObserver.h"

@implementation TYObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"object:%@\n---change:%@",object,change);
}

@end
