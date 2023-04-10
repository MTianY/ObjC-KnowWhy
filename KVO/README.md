# KVO 的使用及其本质

## 1.KVO 的概念

- KVO 的全称: `key-Value Observing`.
- KVO 的作用: 用来监听某个对象`属性值`的改变.

## 2.KVO 的简单使用

点击控制器的 view, 监听某个对象属性的改变.如下:

- TYPerson 对象,属性 `age`

```objc
@interface TYPerson : NSObject

@property (nonatomic, assign) int age;

@end
```

- 在控制器中对其强引用后,设置 age 初始值为`10`.并对其`age`属性进行 KVO 监听.

```objc

#define TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY @"age"
#define TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY @"personAgeProperty_Context"

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    TYPerson *person = [[TYPerson alloc] init];
    self.person = person;
    person.age = 10;
    
    /**
     * 对 person 对象设置当前控制器监听其属性 age 的变化.
     * 如果属性 age 发生变化,就会调用控制器的 observeValueForKeyPath: ofObject: change: context 方法. 
     */
    [person addObserver:self forKeyPath:TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY];
    
}
```

- 点击控制器的 view, 改变`age`属性的值

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.person setage:20];
    
}
```

- 查看监听变化的结果.

```objc
// 监听方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY) {
        NSLog(@"监听到%@属性的改变:%@",object,change);
    }
}
```

- 打印结果

```objc
监听到<TYPerson: 0x600000200440>属性的改变:{
    kind = 1;
    new = 20;
    old = 10;
}

```

## 3.KVO 的实现原理分析

为了验证 KVO 的实现原理,我们又创建了一个 TYPerson 的实例对象, person2.但是并没有对 person2进行监听.其他代码逻辑同 person 一样.这时点击控制器的 view, 看到打印结果.`只有 person 设置监听的属性有打印变化的值.`

```objc
监听到<TYPerson: 0x6040000104d0>属性的改变:{
    kind = 1;
    new = 20;
    old = 10;
}
```

- 通过打印 person 实例对象和 person2 实例对象的 `isa 指针`.结果如下

```objc
(lldb) p self.person.isa
(Class) $0 = NSKVONotifying_TYPerson
  Fix-it applied, fixed expression was: 
    self.person->isa
(lldb) p self.person2.isa
(Class) $1 = TYPerson
  Fix-it applied, fixed expression was: 
    self.person2->isa
```

- person 对象因为设置了监听.其 isa 指针的指向变为`NSKVONotifying_TYPerson`这个类.
- person2 对象没有设置监听.其 isa 指针的指向仍就是 `TYPerson`

**结论1**

- 通过对比得出,设置监听的属性,其实例对象的 isa 指向会发生变化.

#### 3.1 NSKVONotifying_TYPerson这个类

- 这个类是在 person 实例对象的属性添加监听之后,在运行中由 Runtime 自动生成的一个类
- `NSKVONotifying_TYPerson`类是`TYPerson`的一个`子类`.
- 这个类的 class 对象中,包含了如下信息
    - isa
    - superclass
    - setAge: 方法
    - ...等等

#### 3.2 监听方法如何被调用的?

- 因为要调用 `setAge:` 这个对象方法, 所以 person 实例对象通过其`isa 指针`找到其对应的 class 对象
- age 属性被添加监听后.  运行中 person 的父类变成了 NSKVONotifying_TYPerson.
- 所以 isa 指针指向的 class 对象就是 NSKVONotifying_TYPerson 的 class 对象.
- 找到的 `setAge:` 对象方法是`NSKVONotifying_TYPerson`中的.
    - 而这个 `setAge:` 方法会来到`_NSSetIntValueAndNotify`这个方法中
    - `_NSSetIntValueAndNotify`这个方法的`伪代码`大致如下

    ```objc
    void _NSSetIntValueAndNotify() {
        [self willChangeValueForKey:@"age"];
        // 调用父类的 setAge:方法,真正的改变 age 的值
        [super setAge:age];
        // age 的值已确定被改变了
        [self didChangeValueForKey:@"age"];
    }
    
    - (void)didChangeValueForKey:(NSString *)key {
        // 在这个方法中,通知监听器,哪个属性值发生了变化.
    }
    ```
    
- 而没有添加监听的 person2 对象,其 isa 指针指向的仍是 TYPerson 这个类.

## 4.验证 NSKVONotifying_TYPerson 这个类

**方式1**

- 自己主动生成`NSKVONotifying_TYPerson`这个后,再次点击控制器的 view, 发现的结果是`KVO监听并没有被调用`.控制台会打印这样一条信息:

```c
KVO failed to allocate class pair for name NSKVONotifying_TYPerson, automatic key-value observing will not work for this class
```

- 如果把这个类删掉或不让它参与编译,发现 KVO 又可以正常调用了.
- 由此可以说明, KVO 在运行时确实是生成了一个`NSKVONotifying_TYPerson`这么一个子类,来对监听做处理.

**方式2**

```objc
NSLog(@"监听之前对应的类对象:%@---%@",object_getClass(person), object_getClass(person2));]
[person addObserver:self forKeyPath:TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY];
NSLog(@"监听之后对应的类对象:%@---%@",object_getClass(person), object_getClass(person2));
```

- 监听之前和之后,对 person 和 person2的类对象打印:

```objc
监听之前对应的类对象:TYPerson---TYPerson

监听之后对应的类对象:NSKVONotifying_TYPerson---TYPerson
```

- 被监听的person 其类对象发生了变化

**方式3**

```objc
NSLog(@"监听之前实例对象对应的方法内存地址: %p--%p",[person methodForSelector:@selector(setAge:)], [person2 methodForSelector:@selector(setAge:)]);
[person addObserver:self forKeyPath:TYPERSON_KEYPATH_FOR_PERSON_Age_PROPERTY options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:TYPERSON_CONTEXT_FOR_PERSON_Age_PROPERTY];
NSLog(@"监听之后实例对象对应的方法内存地址: %p--%p",[person methodForSelector:@selector(setAge:)], [person2 methodForSelector:@selector(setAge:)]);
```

- 打印结果如下:

```c
监听之前实例对象对应的方法内存地址: 0x10039a4a0--0x10039a4a0
监听之后实例对象对应的方法内存地址: 0x100747f8e--0x10039a4a0
```

- 发现 person 对象在监听之后,其 isa 指针指向的 class 对象中的对象方法(setAge:)的内存地址发生了变化
- 在 `touchBegin` 方法处打断点,调出`lldb`模式,通过`p (IMP)方法内存地址`打印出其方法名具体是什么

```lldb
(lldb) p (IMP)0x10039a4a0
(IMP) $0 = 0x000000010039a4a0 (KVO`-[TYPerson setAge:] at TYPerson.m:13)
(lldb) p (IMP)0x100747f8e
(IMP) $1 = 0x0000000100747f8e (Foundation`_NSSetIntValueAndNotify)
```

- 由此也可以看到,被监听之后的 person 对象,其 setAge:方法在调用时其实是走了`Foundation`的`__NSSetIntValueAndNotify`方法.

## 5.查看 NSKVONotifying_TYPerson 和 TYPerson 两个类对象中的对象方法有哪些?

- 要想看类对象中所有对象的方法名称.拿到其方法列表中的方法打印出就行
- 下面通过 runtime 方法获取类对象中的方法名称

```objc
- (void)logMethodNameForClassObject:(Class)class {
    unsigned int outCount;
    Method *methodList = class_copyMethodList(class, &outCount);
    NSMutableString *methodNamesMutString = [NSMutableString string];
    for(int i = 0; i < outCount; i++) {
    Method method = methodList[i];
    NSString *methodName = NSStringFromSelector(method_getName(method));
    [methodNamesMutString appendString:methodName];
    [methodNamesMutString appendString:@", "];
    }
    free(methodList);
}

NSLog(@"类对象: %@---方法名: %@\n",class,methodNamesMutString);
```

- 打印结果如下:
- 类对象 `NSKVONotifying_TYPerson` 中包含的方法有:
    - `setAge:`
    - `class` 
    - `dealloc`
    - `_isKVOA`

- 类对象`TYPerson`中包含的方法有:
    - `setAge:`
    - `age` 


## 6.KVO 的本质是什么?

- KVO 能实现的本质就是修改了 set 方法的实现.
- 那么我们将 person 对象原先的 set 方法实现屏蔽掉,新增一个暴露的成员变量`age`.
- 实现如下方法,KVO 是否可以成功监听`age`的变化呢?

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.person -> age = 1;
}
```

- `当然是不能.`
- 因为上面并没有调用 person 的 set 方法.
- 那么按上面的方式如何成功调用 KVO?

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { 
    [self.person willChangeValueForKey:@"age"];
    self.person -> age = 1;
    [self.person didChangeValueForKey:@"age"];
}
```

- 我们要手动添加两行代码:`willChange..`和`didChange...`
- 因为 KVO 的本质就是将 person 的 isa 指针,指向了动态生成的 NSKVONotifying_TYPerson 这个类.然后调用其类对象中的 set方法.这个 set 方法其实现流程大致为:
    - 调用 `willChangeValueForKey:...` 方法
    - 调用父类TYPerson 的`set`方法,`真正的改变值`.
    - 调用`didChangeValueForKey...`确定改过值之后,调用控制器的`observer....`监听方法.

