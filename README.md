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
> 


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

```objc
#import <malloc/malloc.h>

NSUInteger pointAddressSize = malloc_size((__bridge const void *)(objc));
```

- 所以说, NSObject 对象创建时内存为其开辟的16字节的控件,其中 isa 占用8字节大小.

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

