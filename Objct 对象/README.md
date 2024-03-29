[TOC]

## Objective-C 对象在内存中的表现形式.

> Objective-C 中的对象,主要分为3种
> 
> - instance 对象(实例对象)
> 	- instance 对象就是通过类 alloc 出来的对象.每次调用 alloc 方法都会产生新的 instance 对象.它们分别占用不同的内存.
> 	- instance 对象在内存中存储的信息?
> 		- isa 指针
> 		- 其他`成员变量`
> - class 对象 (类对象)
> 	- class 对象获取办法有如下几种
> 	
> 	```objc
> 	// 1.创建 instance 对象
> 	NSObject obj1 = [[NSObject alloc] init];
> 	NSObject obj2 = [[NSObject alloc] init];
> 		
> 	// 2.获取 instance 对象的类对象
> 	Class objClass1 = [obj1 class];
> 	Class objClass2 = [obj2 class];
> 	Class objClass3 = object_getClass(obj1);
> 	Class objClass4 = object_getClass(obj2);
> 		
> 	// 3.根据类直接获取其 class 对象
> 	Class objClass5 = [NSObject class];
> 	```
> 
> 	- 以上 objClass1 ~ objClass5都是  NSObject 的 class 对象.并且它们都是同一个对象.每个类在内存中有且只有一个 class 对象.(打印内存地址都是一样的)
> 	- class 对象在内存中存储的信息有哪些?
> 		- isa 指针
> 		- superclass 指针
> 		- 类的`属性`信息(@property)
> 		- 类的`对象方法`信息(instance method)
> 		- 类的`协议`信息(protocol)
> 		- 类的`成员变量`信息(ivar)
> 		- 其他
> 
> - meta-class 对象(元类对象)
> 	- meta-class 对象获取办法:
> 
> 	```objc
> 	Class objMetaClass = object_getClass([NSObject class]);
> 	```
> 
> 	- 每个类在内存中有且只有一个 meta-class 对象
> 	- meta-class 对象和 class 对象在内存中的结构是一样的,但是用途不一样,这样就导致他们存储的信息不同.(存储信息不同,但是结构一样,那么不存储的地方为 null)
> 	- meta-class 在内存中存储的信息
> 		- isa 指针
> 		- superclass 指针
> 		- 类的`类方法`信息(class method)


### 一. instance 对象

#### 1. OC对象、类主要是基于 C/C++的`结构体`实现的.

```c
// OC代码编译最终会转成机器语言的代码
Objective-C ---> C/C++ ---> 汇编语言 ---> 机器语言
```


#### 2. `Objective-C`文件转`C++`文件

- C/C++转汇编语言会因为硬件设备的不同而不同,如 Mac、Windows、iOS. 不同的平台支持的代码形式不同.

```c
//方式一: 没有指定平台,OC 文件转 C++文件
clang -rewrite-objc (OC文件) -o (输出的C++文件)
```

- 指定 iOS 平台

```c
// arch: 架构
// 模拟器(i386). 32bit(armv7). 64bit(arm64)
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc (OC文件) -o (输入的 C++文件)
```

#### 3.`NSObject`对象在内存中占用的大小

- `main.m` 文件中, 通过`control+command` 点进去 NSObject 查看后,发现 NSObject 对象其实如下:

```objc
@Interface NSObject <NSObject> {
	Class isa;
}
```

- `mainArm64.cpp`文件中,通过查找发现 NSObject 对象的表现形式为: 

```c++
struct NSObject_IMPL {
	Class isa;
};
```

- 从以上可以看出,`OC 类的底层实现其实就是 C++的结构体`

- 查看`isa`的构成, 发现它是一个`指向结构体的指针`, 所以在64位环境中一个指针在内存中占8个字节(32位下占4个字节), 所以上面的结构体在内存中也占8个字节(因为只有一个 isa 成员).

```c++
/// An opaque type that represents an Objective-C class.
typedef struct objc_class *Class;
```

- 解读 `NSObject *obj = [[NSObject allic] init];`
	- 从右往左读
	- `[NSObject alloc]` .内存分配存储空间给结构体(NSObject 的本质就是结构体,见上面),结构体中只有`isa`,其内存地址就是这个结构体的内存地址
	- 左边 `NSObject *obj`指针指向这个分配的内存地址.所以 obj 存的地址就是 isa 的内存地址

- 获取 NSObject `实例对象的成员变量`在内存中所占用的大小,打印结果为 8.

```objc
#import <objc/runtime.h>
NSUInteger ivarSize = class_getInstanceSize([NSObject class]);
NSLog(@"%zd",ivarSize);
```

- 获取 objc 指针指向内存的大小,结果为16
- OC 对象实际分配内存空间,内存对齐是**16** 的倍数.
- `结构体`按其成员最宽的整数倍对齐, 比如`double`占 8 个字节, 那么会有`8, 16,32..`些情况

```objc
#import <malloc/malloc.h>

NSUInteger pointAddressSize = malloc_size((__bridge const void *)(objc));
```

- 所以说, NSObject 对象创建时内存为其开辟的16字节的控件,其中 isa 占用8字节大小.

举例:

```objc
结构体:
typedef struct {
    int a;
    char c;
    int *b;
} testStruct;	// sizeof(testStruct), 内存空间是 16
/*
 * int a; 需 4 个字节, 按最大 int*b 分 8 个字节, int a 后面的 char c 占 1 个字节, 能填下, 所以是 16 个字节
 */

typedef struct {
    int a;
    int *b;
    char c;
} testStruct1;	// sizeof(testStruct1). 内存空间是 24

/*
 * int a; 需 4 个字节.  按最大 int *b分 8 个字节. a 后面剩 4 个字节, 放不下 int *b; 所以 char c 占 1 个字节, 但给它分配 8 个字节. 共 24 字节.
 */

```

- `sizeof(x)` 求 `x` 所占用的内存空间
- `class_getInstanceSize([Person class])` 求出`Person`对象占用的内存空间
- `malloc_size((__bridge const void *)(p))` 求`p`指向内存空间实际分配的空间

#### 4.继承自 NSObject 的 TYPerson 类在内存中占用情况

```objc
@interface TYPerson : NSObject

{
	@public
	int no;
	int age;
}

@end
```

编译成`c++`文件后,得到 TYPerson 的表现形式为

```c++
struct TYPerson_IMPL {
	struct NSObject_IMPL NSObject_IVARS;
	int no;
	int age;
};
```

其中

```objc
struct NSObject_IMPL {
	Class isa;
};
```

#### 5.添加一个属性之后,内存占用情况又如何?

- 添加一个 height 属性

```objc
@interface TYPerson : NSObject

{
    @public
    int no;
    int age;
}

@property (nonatomic, assign) int height;

@end

@implementation TYPerson

@end
```

- 编译成 C++ 文件之后,其内存中表现形式为:

```c++
struct TYPerson_IMPL {
	struct NSObject_IMPL NSObject_IVARS;
	int no;
	int age;
	int _height;
};
```

- 属性,会自动生成下划线的成员变量和 SET 及 GET 方法.这里的 person 对象在内存中会多出一个带下划线的`_height`成员变量.但是其 GET 及 SET 方法并没有保存在 person 对象的内存中.
- 方法其实是保存在 `TYPerson`类的方法列表中


### 二. isa 指针 & superclass 指针

比较经典的一张图:

![4185621-379b14bf1226140a](https://lh3.googleusercontent.com/-UaaeJdIlzc4/W3Q0IbgsijI/AAAAAAAAAC4/WrTxS2VvzOchxgJkW2AIXQRVtjXVE87XgCHMYCw/I/4185621-379b14bf1226140a.png)


上面可以看到, instance 对象、class 对象、meta-class 对象中都有 isa 指针.那么其作用具体是什么?

#### 1.isa 指针的概念

| instance 对象 |  | class 对象 |  |  meta-class 对象 |
| --- | --- | --- | --- | --- |
| isa 指针 |  | isa 指针 |  |  isa 指针 |
|其他成员变量| |superclass 指针| |superclass 指针| 
|  | | 属性信息、对象方法、协议信息、成员变量信息等等 |  |  类方法 |

- instance 对象的`isa`指针指向 class 对象
    - 当调用其`对象方法`时,通过`instance 对象的 isa指针`找到`class 对象`,然后在class 对象中找到`对象方法`的实现进行调用
- class 对象的`isa`指针指向 meta-class 对象
    - 当调用其`类方法`时.通过`class 对象的 isa 指针`,找到`meta-class 对象`,然后在 meta-class 对象中找到`类方法`的实现进行调用  

#### 2.class对象的 superclass 指针

子类的class 对象的 superClass 指针指向其父类的 class 对象,同时父类的 superclass 指针指向基类的 class 对象.

**2.1 子类对象调用父类的`对象方法`执行流程**

如果有个对象的继承关系如下. TYPerson 继承自 NSObject. TYStudent 继承自 TYPerson.其中有各自的成员变量、属性、和方法,如果 student 对象调用 TYPerson 的实例方法等等其调用流程是如何实现的?

```objc
#pragma mark - TYPerson
@interface TYPerson : NSObject

{
    @public
    int no;
    int age;
}

@property (nonatomic, assign) int height;

- (void)personIntanceMethod;
+ (void)personClassMethod;

@end

@implementation TYPerson

- (void)personIntanceMethod {
    
}

+ (void)personClassMethod {
    
}

@end

#pragma mark - TYStudent
@interface TYStudent : TYPerson

{
    int weight;
}

@property (nonatomic, copy) NSString *name;

- (void)studentInstanceMethod;
+ (void)studentClassMethod;

@end

@implementation TYStudent

- (void)studentInstanceMethod {
    
}

+ (void)studentClassMethod {
    
}

@end

// 子类 student 对象父类实例方法
[student personInstanceMethod];
```


| TYStudent 的 class 对象 |  | TYPerson 的 class 对象|  | NSObject 的 class 对象 |
| --- | --- | --- | --- | --- |
| isa 指针 |  | isa 指针 |  | isa指针 |
| superclass 指针 |  | superclass 指针 |  | superclass 指针 |
| 属性信息、对象方法、协议信息、成员变量信息 |  | 属性信息、对象方法、协议信息、成员变量信息 |  | 属性信息、对象方法、协议信息、成员变量信息 |

student 对象调用其父类 TYPerson 的实例对象方法本质就是:

- 通过 `TYStudent`的`实例对象的isa指针`,找到`TYStudent 的 class 对象`,然后通过`TYStudent 的 class 对象的 superclass 指针`找到它的父类`TYPerson的 class 对象`.然后在`TYPerson 的 class 对象中找到其对象方法进行调用`.
- 如果调用基类 NSObject 的对象方法,流程一样.`TYStudent 实例对象的 isa 指针,先找到 TYStudent 的 class 对象,通过 TYStudent 的 class 对象中的 superclass 指针,找到 TYPerson 的 class 对象,然后通过 TYPerson 的 class 对象中的 superclass 指针,找到 NSObject 的 class 对象,从而调用其对象方法.`


**2.2 子类调用父类的`类方法`执行流程**

原理同上. 子类的 meta-class 对象中的 superclass 指针都是指向其父类的 meta-class 对象.然后去 meta-class 对象中找到类方法.完成调用



