# KVC

## 一. KVC 简单介绍

1.KVC 的全称

- Key-Value Coding
- 可以通过一个 key 来`访问某个属性`

2.常见 API

```objc
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKeyPath:(NSString *)keyPath;
- (id)valueForKey:(NSString *)key;
```

## 二. KVC API 简单使用

1.`- (void)setValue:(id)value forKeyPath:(NSString *)keyPath` 和 `- (void)setValue:(id)value forKey:(NSString *)key` 的区别?

- key 就是根据某个对象的属性去找
- keyPath 可以理解为根据某个对象的属性路径去找.可以更精确.

```objc
// TYPerson 类有个属性 age 和 TYStudent 对象;
// TYStudent 类有个属性 no;

TYPerson *person = [[TYPerson alloc] init];
person.student = [[TYStudent alloc] init];

// 1.使用 KVC 的 setValue:forKey: 给 person 的 age 赋值.
// 打印结果为 10;
[person setValue:@10 forKey:@"age"];
NSLog(@"Key: age = %@",[person valueForKey:@"age"]);

// 2.使用 KVC 的 setValue:forKeyPath: 给 person 的 age 赋值.
// 打印结果为 20
[person setValue:@20 forKeyPath:@"age"];
NSLog(@"KeyPath: age = %@",[person valueForKeyPath:@"age"]);

// 3.使用 KVC 的 setValue:forKey 或 setValue:forKeyPath: 给一个 person 没有的属性赋值.
// 报错:Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<TYPerson 0x1005394b0> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key weight.'

// 4.使用 setValue:forKey: 给 person 的 student 对象的属性赋值
// 打印结果:40
person.student = [[TYStudent alloc] init];
[person.student setValue:@40 forKey:@"no"];
NSLog(@"key: no = %@",[person.student valueForKey:@"no"]);

// 5.使用 setValue:forkeyPath: 给 person 的student 对象的属性赋值
// 打印结果 60
[person.student setValue:@60 forKeyPath:@"no"];
NSLog(@"keyPath: no = %@",[person.student valueForKeyPath:@"no"]);

// 6.使用 setValue:forKeyPath: 直接用 person 对象给 student 对象的属性赋值.

```

## 三. `setValue:forKey:`原理

![](https://lh3.googleusercontent.com/XX1hoB2p4L2mCqjy2xuFRtXjevwWhVyggIZAOJcYKFLkpU4QPzSBZCUmRqJJT4jJ-nwI28EVM84WOwzurVthHgWduyGG7uYXnvTBREA6KZ2J7IBnNsiqIm1wqSb6s2za0olgzbRUy2o8TnYxsFjo8UxjHsy7-66jc9nbSTxEIqedTaVMgvEp_-9rg8tV1VQ1oEWBMYmFNeG4bZp9UiLR_t187yr7bus4y5jCSdGqbL-re2QLIx1TC869rFAYZcuDPl8Iq5OvO_gzaJuRBksOEi6NauGFZjEtRMs3IJmRTHcLWWvpNVNpi2mjQJ13yHPxD6kx0bGWWMYYd0k9VTBQ_6lZSY1WKqhGmU5uYMZqdE-hrQe4E9qibNeMW8vr4bbWvNazR3q0-y_2StsigbZtQAo_1H87xS6_NeilzC_bBmZsmKsXuZiDfN9f0FXfgJpYXxSIXhVt_IrjxYvjMCeVGM3ceWlX0_4AV5Axmvy75Tvl_6EqkfNlYu3Uuu0VUDXLDRg708t4gdV3gYNoiy0_YlM5iSklOkm8xHsv1ONCbeWjuYrSRyD8sKKNWykOHHQEGVz_nC6x2bLvNhWgqbw0e-dqOYFCrrlVV0rgHQ=w1024-h768-no)

- 首先查找`setKey:`方法.如果找到: `传递参数,调用 setKey:`方法.
 - 如果`没有找到 setKey:` 方法,那么接着查找`_setKey:`方法.如果找到:`传递参数,调用_ setKey: 方法.`
 - 如果`setKey:`和`_setKey:`方法都没有找到,那么调用`+ (BOOL)accessInstanceVariablesDirectly`方法.该方法的含义是:`是否可以直接访问成员变量`.查看其返回值
     - 如果返回值为`YES`
            - 那么将严格按照顺序查找成员变量: `_key、 _isKey、 key、 isKey`.如果找到其中某个成员变量,那么就`直接赋值`.
            - 如果一个都没有找到,那么调用`setValueForUndefinedKey:`方法,并且抛异常,找不到 key
        - 如果返回 NO 
            - 调用`setValueForUndefinedKey:`并且抛异常,找不到 key 

## 四.通过 KVC 给属性赋值,是否可以触发 KVO?

#### 可以触发 KVO

- 如果属性有 set 方法的实现,那么可以触发 KVO.
- 如果属性没有 set 方法的实现,用 KVC 直接访问成员变量,依然可以触发 KVO.
    - 这里它默认手动实现了下面的方法

    ```objc
    willChangeValue...
    [super setKey:];
    didChangeValue...
    ``` 
    
    ## 五. `valueForKey:`实现原理
    
    ![](https://lh3.googleusercontent.com/2QO1BCGe-H_2AntvgVNFp_FqW-3AC5WBe6JsDsx8BZjUeqybgvRsx8GNT45aIZPOLgP_BGgXcGcJpACcVgE1w9Br_2fHM5Rztr9Mz2bod0Z-cKO5tlqRK__YEoM7aGXZgTEslrsK4aQXyoBN4wnr0n3lcqBn9wqbbDPFA5zBDhtIa-8kTHJpHPc-toT4f_bSPnXGlZsqOnXxJ55KueYzyMDCI5rInhGyDqADFAmbrdALIc96Ocb77xFpcoCow5vOY1aU6u8yX-SZKp4HX3dLrrLZGSODDLpXF2d8ozqJxC5Xf9UGRXbjA5NJLhYJDIPW5-MjY_48q4n5F-EYGFqCktBF1tSFZ0w0vt-RQL0pEvwD8DlQIZi2Ni7IoFOXmUgEFJzWW6zsd95AhPZ78hHAseYiVGcCWh6eM8TIgDr0fI8ONZkqi0mDvxDi6cZDqusnIe2oLaTRevnObBcFB5y3rQHl4aVuPgclSd4jPg46EoIuZ4gXEPT-7Jjo6v1z8VbDIG7gVyVOIiBecInCGJX3pQwFi0unyYJrm-1xe_UlvFTqBO2by8k5IoqA7AxFdIfyMzylh0TnS1BLvPg_YR_N-zjc3Iabint6vMcnhw=w1024-h768-no)


#### 1.有属性的情况

有属性的情况,取值会直接调用`getKey:`方法.

#### 2.没有属性只有成员变量的情况

- 优先查找`- (返回值类型)getKey` 方法
- 如果查找不到`getKey`方法,那么接着找`- (返回值类型)key`方法.
- 如果还是找不到`key`方法,那么接着找`- (返回值类型)isKey`方法.
- 如果仍旧找不到,最后找`- (返回值类型)_key`方法.
- 如果都找不到,调用`accessInstanceVariablesDirectly`方法,看起返回值
    - 如果返回 YES
        - 按照`_key、_isKey、key、isKey`顺序查找成员变量
            - 找到了直接返回值
            - 找不到调用`valueforUndefinedKey:`方法并抛异常  
    - 如果返回 NO
        - 调用: `valueforUndefinedKey:`方法并抛异常.    

