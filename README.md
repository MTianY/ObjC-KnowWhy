## Objective-C Object 在内存中的表现形式.

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

#### 3.查看`Objective-C`对象的底层实现

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