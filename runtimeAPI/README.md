# runtime API

### 和 类 相关的 API

#### 1. 传入一个对象, 获取其 `isa` 指向的 Class 对象.
```c++
Class object_getClass(id obj)
```

如

```objc
TYPerson *person = [[TYPerson alloc] init];
[person run];
        
// 传入一个对象,获取其 isa 指向的 Class 对象
// 传入的 person 实例对象,其 isa 指向的是其类对象 TYPerson
NSLog(@"%p---%p",object_getClass(person), [TYPerson class]);
// 传入的类对象[TYPerson class],则object_getClass 得到的就是其元类对象
NSLog(@"%p---%p",object_getClass([TYPerson class]), [TYPerson class]);
```

#### 2.设置 `isa` 指向的 Class

```c++
Class object_setClass(id obj, Class cls)
```

如:

```objc
// 修改了 person 对象的 isa 指向,现在其 isa 指向 TYAnimal 这个类对象
object_setClass(person, [TYAnimal class]);
// 调用这个方法,看打印
[person run];
```

打印结果:

```c
// 因为 person 的 isa 已经指向 TYAnimal 了,所以执行 run 方法时是去 TYAnimal 这个类对象的方法列表里去找方法的.
-[TYAnimal run]
```

#### 3.判断一个 OC 对象是否是 Class 类型

```c++
BOOL object_isClass(id obj)
```

如:

```objc
NSLog(
@"%d---%d----%d",
object_isClass(person),
object_isClass([TYPerson class]), 
object_isClass(object_getClass([TYPerson class])));
```

打印结果:

```c
// person 是实例对象,不是一个类对象
// TYPerson 是类对象
// object_getClass([TYPerson class]) 得到的 元类对象,也是 Class 类型
0---1----1
```

#### 4. 动态创建一个类 

```c++
/**
 * 参数1: superclass, 父类
 * 参数2: name, 类名
 * 参数3: extraBytes, 额外的内存空间
 */
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
```

如: 

```objc
Class newClass = objc_allocateClassPair([NSObject class], "TYDog", 0);
```

#### 5.注册这个类

一般和`动态创建类`结合使用.动态创建完成之后,注册这个类.

类,注册完毕,就相当于类对象和元类对象里面的结构已经定义好了.所以动态创建类,动态添加成员变量,都要在注册类之前进行.

- 因为成员变量在 `class_ro_t` 这个结构体中,是只读的,所以不能为一个结构已经确定的类去动态的添加成员变量.
- 但是方法、协议、属性等等是可以动态添加的,就是说动态添加方法可以在注册类后面再写,因为方法是在`class_rw_t`这个结构体中.

```c++
objc_registerClassPair(Class *cls)
```

如:

```objc
// 动态创建这个类
Class newClass = objc_allocateClassPair([NSObject class], "TYDog", 0);
// 注册这个类
objc_registerClassPair(newClass);
```

```objc
// 动态创建这个类
Class newClass = objc_allocateClassPair([NSObject class], "TYDog", 0);
   
// 动态添加成员变量
class_addIvar(newClass, "_age", 4, 1, @encode(int));
class_addIvar(newClass, "_weight", 4, 1, @encode(int));
   
// 动态添加方法
class_addMethod(newClass, @selector(run), (IMP)run, "v@:");
   
// 注册类
objc_registerClassPair(newClass);
   
// 使用动态创建的这个类
id dog = [[newClass alloc] init];
[dog setValue:@10 forKey:@"_age"];
[dog setValue:@30 forKey:@"_weight"];
[dog run];
   
NSLog(@"%@---%@",[dog valueForKey:@"_age"], [dog valueForKey:@"_weight"]);
```

### 和 成员变量 有关的API

#### 1.获取成员变量的相关信息

```c++
const char *ivar_getName(Ivar v)
const char *ivar_getTypeEncoding(Ivar v)
```

如:

`TYPerson` 有两个属性

```objc
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
```

执行如下方法,看其成员变量信息

```c++
// 获取成员变量信息
Ivar nameIvar = class_getInstanceVariable([TYPerson class], "_name");
Ivar ageIvar = class_getInstanceVariable([TYPerson class], "_age");
NSLog(@"\n%s %s\n%s %s", ivar_getName(nameIvar), ivar_getTypeEncoding(nameIvar), ivar_getName(ageIvar), ivar_getTypeEncoding(ageIvar));
```

打印结果:

```c
_name @"NSString"
_age i
```
#### 2.设置和获取成员变量的值

```c++
object_setIvar(id obj, Ivar ivar, id value)
```

如

```objc
TYPerson *person = [[TYPerson alloc] init];
object_setIvar(person, nameIvar, @"mty");
object_setIvar(person, ageIvar, @10);

NSLog(@"\nname = %@\n age = %@",object_getIvar(person, nameIvar), object_getIvar(person, ageIvar));
```

打印结果:

```c
name = mty
age = 10
```

#### 3.获取一个类里的所有成员变量.

```c++
class_copyIvarList(Class cls, int *outCount);
```

如:

```objc
// 获取所有的成员变量信息
// 成员变量的数量
unsigned int count;
Ivar *ivars = class_copyIvarList([TYPerson class], &count);
for (int i = 0; i<count; i++) {
  // 取出 i 位置的成员变量
  Ivar ivar = ivars[i];
  NSLog(@"%s  %s", ivar_getName(ivar), ivar_getTypeEncoding(ivar));
}
// 释放
free(ivars);
```

打印信息:

```c
_age  i
_name  @"NSString"
```

这个方法,在 iOS 中很有用,举个例子, 修改`UITextField`的占位文字颜色.

修改这个颜色,先举出最常用的办法:

```objc
// 方法一:
// 一般正常改变 TextField 的占位文字颜色
self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入姓名:" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
```

下面是通过这个 runtime API 的方式去修改, 使用这个方法的前提,是我们要知道`UITextField`中的成员变量信息. 文字颜色很有可能和 `UILabel` 有关, 所以先看下其成员变量都有什么:

```objc
self.textField.placeholder = @"请输入姓名:";
// 查看其所有的成员变量
unsigned int count;
Ivar *ivars = class_copyIvarList([UITextField class], &count);
for (int i = 0; i < count; i++) {
   Ivar ivar = ivars[i];
   NSLog(@"%s %s",ivar_getName(ivar), ivar_getTypeEncoding(ivar));
}
```

从上面的打印,可以获取到其中有个成员变量信息如下:

```c
_placeholderLabel @"UITextFieldLabel"
```

知道其成员变量,根据 `kvc` 取出这个类型,改变颜色

```objc
// 方法二:
// 通过 kvc 根据成员变量取出这个 label
UILabel *placeholderLabel = [self.textField valueForKeyPath:@"_placeholderLabel"];
placeholderLabel.textColor = [UIColor blueColor];
```

另一个直接的方法

```objc
// 方法三:
[self.textField setValue:[UIColor orangeColor] forKeyPath:@"_placeholderLabel.textColor"];
```

#### 4.一个简单的字典转模型例子.

主要用到 runtime 的 `class_copyIvarList` 方法

为`NSObject` 新建一个分类`NSObject+JSONModel`

```objc
// 定义接口
+ (instancetype)ty_objectWithJSON:(NSDictionary *)jsonDict;

// 实现接口
// 导入runtime
#import <objc/runtime.h>
+ (instancetype)ty_objectWithJSON:(NSDictionary *)jsonDict {
    NSObject *obj = [[self alloc] init];
    unsigned int count;
    // 取出当前类的所有成员变量
    Ivar *ivars = class_copyIvarList(self, &count);
    // 遍历成员变量
    for(int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        // 将 C 语言字符串转成 OC 字符串
        NSMutableString *name = [NSMutableString stringWithUTF8String:ivar_getName(ivar)];
        // 去掉成员变量的首个下划线
        NSString *newName = [name substringFromIndex:1];
        // 赋值
        [obj setValue:jsonDict[newName] forKey:newName];
    }
    return obj;
}
```

定义一个简单的模型

```objc
// TYTestModel.h
@interface TYTestModel : NSObject
@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) int no;
@end
```

使用

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSDictionary *testJson = @{
                               @"name" : @"ty",
                               @"age" : @10,
                               @"no" : @1388994
                               };

    TYTestModel *testModel = [TYTestModel ty_objectWithJSON:testJson];
    NSLog(@"%@",testModel);
    
}
```

### 其他 API

#### 1. 交换方法

```objc
method_exchangeImplementations(method_1, method_2)
```

```objc
// 取出 TYPerson 中的对象方法 eat
Method playMethod = class_getInstanceMethod([TYPerson class], @selector(eat));
// 取出 TYPerson 中的对象方法 run
Method runMethod = class_getInstanceMethod([TYPerson class], @selector(run));
// 交换 eat 和 run 的方法实现
method_exchangeImplementations(playMethod, runMethod);
```

#### 2.交换方法实现简单示例

> 想要监听一个项目中的所有按钮的点击情况.

- `UIButton` 继承自 `UIControl`.
- 真正处理点击事件的是 `UIControl` 中的这个方法:

```objc
- (void)sendAction:(SEL)action to:(nullable id)target forEvent:(nullable UIEvent *)event;
```

- 所以如果要监听到所有按钮的点击情况,我们要拦截这个方法.

通过 `method_exchangeImplementations` 这个方法来将系统的方法实现和我们自己的方法实现来交换一下:

首先创建一个 `UIControl` 的分类: `UIControl+Extension`.

```objc
#import "UIControl+Extension.h"
#import <objc/runtime.h>

@implementation UIControl (Extension)

+ (void)load {
    
    Method systemMethod = class_getInstanceMethod(self, @selector(sendAction:to:forEvent:));
    Method myMethod = class_getInstanceMethod(self, @selector(ty_sendAction:to:forEvent:));
    method_exchangeImplementations(systemMethod, myMethod);
    
}

- (void)ty_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    NSLog(@"监听按钮点击操作--%s",__func__);
    
    // 如果要执行 button 之前的点击操作,那么就要执行这个.来执行原来的方法.
    [self ty_sendAction:action to:target forEvent:event];
    
}

@end
```

##### 解析

```objc
void method_exchangeImplementations(Method m1, Method m2)
{
    if (!m1  ||  !m2) return;

    rwlock_writer_t lock(runtimeLock);

    IMP m1_imp = m1->imp;
    m1->imp = m2->imp;
    m2->imp = m1_imp;


    // RR/AWZ updates are slow because class is unknown
    // Cache updates are slow because class is unknown
    // fixme build list of classes whose Methods are known externally?

    // 清除缓存的操作.
    flushCaches(nil);

    updateCustomRR_AWZ(nil, m1);
    updateCustomRR_AWZ(nil, m2);
}
```

找到 method 中 方法的实现,然后将这两个方法的实现交换了位置.所以我们上边如果要调 UIButton 之前的点击操作,那么就要调用我们这个自己的方法,看似死循环,其实我们这个方法存的是系统的那个方法.



