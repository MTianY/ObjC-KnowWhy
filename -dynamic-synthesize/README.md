## @dynamic和@synthesize 的区别

现在在一个类中声明一个属性,都会像下面这么写:

```objc
@property (nonatomic, assign) int age;
```

上面写完之后,其本质就会生成如下这些东西:

```objc
// 1.带下划线的成员变量
int _age;

// 2.set 方法的声明
- (void)setAge:(int)age;

// 3.get 方法的声明
- (int)age;

// 4.set 方法的实现
- (void)setAge:(int)age {
   _age = age;
   // ...
}   

// 5.get 方法的实现
- (void)age {
   return _age;
}
```

能自动生成上面的这些东西,其本质是因为这个关键字`@synthesize`.

现在的编译器经过优化,我们已经不用手动去写这个语句:

```objc
// 右侧是我们指定的成员变量名称
@synthesize age = _age;

// 如果下面这种写法,那么成员变量也叫 age
@synthesize age;
```

那么`@dynamic`的作用又是什么呢? 我们写上如下的语句之后,运行程序,看看会发生什么?

```objc
@dynamic age;
```

运行程序后,程序 crash 了.崩溃原因是:找不到 set 方法的实现

```c
reason: '-[TYPerson setAge:]: unrecognized selector sent to instance 0x10055f5f0'
```

其实`@dynamic`的作用总结如下:

- 告诉编译器,不要自动生成`setter`方法和`getter`方法的实现.
- 不要自动生成成员变量.

当我们写上`@dynamic age;`这个之后,我们可以用运行时动态添加方法来完成一些功能.


