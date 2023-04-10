### isMemberOfClass: 和 isKindOfClass:

有这么两个方法:

```objc
isMemberOfClass:
isKindOfClass:
```

那么他们的区别是什么呢? 这时通过 runtime 源码可以看其实现,因为这个是开源的.找到`NSObject.mm`这个文件.

```c++
// 本身是类方法, self 就是个类对象, 通过 object_getClass 得到其元类对象.那么就会判断传进来的 cls 是不是和元类对象是一个
+ (BOOL)isMemberOfClass:(Class)cls {
    return object_getClass((id)self) == cls;
}

// 传 self, 通过[self class] 得到类对象,从而判断是不是一个类对象.
- (BOOL)isMemberOfClass:(Class)cls {
    return [self class] == cls;
}

// 因为也会类方法,所以 self 本身就是个类对象, 通过 object_getClass 获取其元类对象,然后遍历其父类,判断是不是 cls 的子类
+ (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}

// 传进来 self, 通过[self class] 得到其类对象, 然后遍历所有类对象及其父类, 判断是不是 cls 的子类
- (BOOL)isKindOfClass:(Class)cls {
    for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
        if (tcls == cls) return YES;
    }
    return NO;
}
```

举例说明:

```objc
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
```

打印结果: 

```c
Class[14066:904661] [1]-1
Class[14066:904661] [2]-1
Class[14066:904661] [3]-0
Class[14066:904661] [4]-0
Class[14066:904661] [5]-0
Class[14066:904661] [6]-1
Class[14066:904661] [7]-1
Class[14066:904661] [8]-1
Class[14066:904661] [9]-0
Class[14066:904661] [10]-1
```


