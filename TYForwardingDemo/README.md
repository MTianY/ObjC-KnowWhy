# README

## 消息转发的简单应用-- 防止因为找不到方法而造成的程序 crash

有这么个对象 `TYPerson`. 其声明了几个方法,其中只有 `- (void)run`方法有实现,另两个均没有实现.

```objc
- (void)run;
- (void)play;
- (void)test;
```

那么当`TYPerson`的对象调用这几个方法的话, 除了`run`方法都会因为`找不到方法实现`而导致程序 crash.

```objc
TYPerson *person = [[TYPerson alloc] init];
[person run];
[person play];
[person test];
```

所以,这里可以通过消息转发来规避这种 crash 的发生.

```objc
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    // 如果方法正确调用,那么就调用
    if ([self respondsToSelector:aSelector]) {
        return [super methodSignatureForSelector:aSelector];
    }
    
    // 如果方法找不到,返回一个非常普通的方法
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"找不到方法: %@",NSStringFromSelector(anInvocation.selector));
}
```

再次调用,打印如下:

```c
TYForwardingTest[13728:884271] -[TYPerson run]
TYForwardingTest[13728:884271] 找不到方法: play
TYForwardingTest[13728:884271] 找不到方法: test
```




