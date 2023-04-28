[TOC]

### 一. Objective-C 对象在内存中的表现形式 ?

#### 1. OC 对象, 主要分 3 种:

- instance 对象 (实例对象)
  - 通过类 alloc 出来的对象, 每次调用 alloc 方法都会产生新的 instance 对象
- class 对象 (类对象)
- meta-class 对象 (元类对象)

#### 2. NSObject 对象在内存中占用的大小?

OC 代码:

```objc
@interface NSObject <NSObject> {
    Class isa;
}
```

C++ 代码:

```c++
struct NSObject_IMPL {
	Class isa;
};
```

#### 3. isa的构成, 是一个`指向结构体的指针`. 

- 所以 64 位环境中, 一个指针在内存占 8 个字节(32 位下则 4 个字节)

```c++
typedef stuct objc_class *Class
```

#### 4. 解读下面代码:

- `[NSObject alloc]`. 指向`alloc`, 申请堆空间. 分配内存空间给 NSObject. 即上面的结构体, 结构体中只有`isa`成员, 所以其内存地址就是这个结构体的地址.
- `init` 初始化
- `NSObject *obj` , 指针指向上面申请的堆空间地址. 所以 `obj` 存的地址就是 `isa`的内存地址

```objc
NSObject *obj = [[NSObject alloc] init];
```

- 获取 NSObject `instance` 对象在内存中占用的大小.

```Objc
#import <objc/runtime.h>
NSUInteger ivarSize = class_getInstanceSize([NSObject class]);
NSLog(@"%zd", ivarSize);
// 打印结果: 8
```

- obj 指针指向内存的大小:

```objc
#import <malloc/malloc.h>
NSUInteger pointAddr = malloc_size((__bridge const void*)(obj));
// 打印结果: 16
```

NSObject 对象创建时内存为其开辟 16 字节的空间, 其中 isa 占用 8 个字节.

#### 5. 继承下的 NSObject

```objc
@interface Person : NSObject
{
  @public
  int no;
  int age;
}
@end
```

对应的 C++ 文件:

```C++
struct Person_IMPL {
  struct NSObject_IMPL NSObject_IVARS;
  int no;
  int age;
}
```

其中 `NSObjct_IMPL` :

```c++
struct NSObject_IMPL {
  Class isa;
}
```

#### 6. 添加属性后

```objc
@interface Person : NSObject
{
  @public
  int no;
  int age;
}

@property (nonatomic, assign) int height;

@end
```

对应 C++文件

```C++
struct Person_IMPL {
  struct NSObject_IMPL NSObject_IVARS;
  int no;
  int age;
  int _height;
}
```

- 属性会自动生成 `_height`带下划线的成员变量及 set / get 方法.

#### 7. isa 指针

`instance 对象`/ `class 对象`/ `meta-class 对象`中均还有 `isa` 指针.

`class 对象`/ `meta-class对象` 中还有`superclass` 指针.

-  `instance对象的 isa 指针指向 class 对象`.
  - 当调用`对象方法`时, 通过 instance 对象的 isa 指针, 找到 class 对象, 然后在 class 对象的方法列表中找到对应的`对象方法`.
- `class 对象的 isa 指针指向 meta-class 对象`.
  - 当调用`类方法`时, 通过 class 对象的 isa 指针, 找到 meta-class 对象, 然后在 meta-class 的方法列表中找到对应的`类方法`.

#### 8. superclass 指针

子类 class 对象的 superclass 指针, 指向其父类的 class 对象, 父类的 class 对象的 superclass 指针, 指向其基类的 class 对象.

子类的 meta-class 对象的 superclass 指针, 指向其父类的 meta-class 对象, 父类的 meta-class 对象的 superclass 指针, 指向其基类的 meta-class 对象.



### 二. KVO

Key-Value Observing.

监听某个对象`属性值`的改变.

```objc
@interface Person : NSObject
@property (nonatomic, assign) int age;
@end
  
- (void)viewDidLoad {
  [super viewDidLoad];
  
  Person *p = [[Person alloc] init];
  self.p = p;
  p.age = 10;
  
  [p addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew 
 NSKeyValueObservingOptionOld context:@"age_context"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.p setage:20];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
  if (context == @"age_context") {
    	NSLog(@"监听到 %@ 属性的改变: %@", object, change);
  }
}

// 打印:
监听到<Person: 0x600000200440>属性的改变:{
    kind = 1;
    new = 20;
    old = 10;
}
```

#### 1. KVO 实现原理:

- 当一个属性的值被 KVO 监听后, 触发属性值改变时, 会动态派生出一个类 `NSKVONotifying_XXX`. 此时这个类的 instance 对象的 `isa`指针, 指向了 `NSKVONotifying_XXX` 这个类.
- `NSKVONotifying_XXX` 这个类时 `XXX`这个类的子类.包含如下信息:
  - isa
  - superclass
  - setAge:
  - class
  - dealloc
  - _isKVOA
- 其中 `setAge:` 方法底层还行如下:

```objc
void _NSSetIntValueAndNotify() {
  [self willChangeValueForKey:@"age"];
  [super setAge:age];
  [self didChangeValueForKey:@"age"];
}

- (void)didChangeValueForKey:(NSString *)key {
  // 通知监听器, 属性值的改变

```

#### 2. KVO 本质总结:

- 当被监听的属性值发生改变时, instance 对象的 isa 指针, 此时不会去找对应 class 对象的 set 方法了. 
- 而是此时 isa 指针, 指向了一个新派生出的子类 `NSKVONotifying_XXX`. 找到它的 set 方法.
- 其 set 方法底层实现先 `willChange:`再调用原`super set:`去改变这个值, 最后调用`didChange:`来通知监听器.

### 三. KVC

Key-Value Coding

通过`key`访问某个属性.

```objc
setValue:forKeyPath:
setValue:forKey:
valueForKeyPath:
valueForKey:
```

`forKey:` 和`forKeyPath:`区别?

- key 根据对象的属性去找
- keyPath 根据对象的属性路径去找. 更精确

#### setValue:forKey: 原理

- 先找 `setKey:`方法. 
  - 找到, 则传递参数, 调用
- 没找到的话, 继续找 `_setKey:` 方法. 
  - 找到, 则传递参数, 调用
- 都没找到, 调用 `+ (BOOL)accessInstanceVariableDirectly`方法. 是否可以访问成员变量.
  - 返回 YES, 将严格按照顺序查找成员变量, 找到则直接赋值, 找不到则 `setValueForUndefinedKey:` ,抛异常
    - _key
    - _isKey
    - key
    - isKey
  - 返回 NO, 直接调用 `setValueForUndefinedKey:`, 抛异常.

#### KVC 触发 KVO

- 属性的 `set`修改调用, 则会触发 KVO.
- 如果没有 set 方法修改调用, 用 KVC 直接访问成员变量, 依然可以触发 KVO.

#### valueForKey: 原理

- 有属性的话, 调属性的`getKey:`
- 没属性的话
  - 优先找 `-(id)getKey`
  - 找不到再找 `-(id)key`
  - 找不到再找 `-(id)isKey`
  - 找不到再找 `-(id)_key`
  - 都找不到, 调用 `accessInstanceVariablesDirectly`.
    - 返回 YES, 按顺序找成员变量. 找不到抛异常 调用`valueForUndefinedKey:`
      - _key
      - _isKey
      - key
      - isKey 
    - 返回 NO, 直接抛异常, 调用`valueForUndefinedKey:`

### 四.Block

OC

```objc
void(^blockName)(void) = ^{
  NSLog(@"Hello world");
};
```

对应 C++

```c++
void (^blockName)(void) = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);
```

OC

```objc
blockName()
```

对应 C++

```c++
blockName->FuncPtr(blockName);
```

#### __main_block_impl_0 函数

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0 *Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

#### __main_block_func_0

```c++
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  NSLog(@"");
}
```

#### blockName->FuncPtr(blockName)

强制转换为`__block_impl`

```C++
struct __blockName_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
}
```

#### block 变量捕获

**auto 变量**可以捕获

- 自动变量, 离开大括号作用域自动销毁

```c
int a = 30;
等同于
auto int a = 30; // auto 可省略
```

- 可以被 block捕获
- 值传递

```objc
int a = 30;

void(^testBlock)(void) = ^{
  NSLog(@"a = %d",a);
};

testBlock();
```

对应 C++

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0 *Desc;
  
  int a;
  
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _a, int flags=0) : a(_a) {
    impl.isa = $_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
}

void(*testBlock)(void) = __main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, a);
对应 C++代码:
static void __main_block_func_0(struct __main_block_impl_0 *_cself){
  int a = __cself->a;
}
```

**static 变量**

**static 局部变量**可以捕获

```objc
static int b = 30;
void(^testBlock)(void) = ^{
  NSLog(@"b = %d",b);
}
```

C++

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0 *Desc;
  int *b;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_b, int flags=0) : b(_b) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
}
```

**static 全局变量** 不能捕获

C++ 对应 block 结构体中没有捕获变量.

直接取的值调用;

```c++
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  NSLog(@"");
}
```

#### 捕获 self

#### block 类型

- `__NSGlobalBlock__`
- `__NSStackBlock__`
- `__NSMallocBlock__`

内存分配

- .text 区
  - 代码段

- .data 区
  - 数据段, 全局变量
- 堆
  - 动态分配的内存
- 栈
  - 局部变量

#### `__NSGlobalBlock__`

- 没有访问 auto 变量的 block. 都是`__NSGlobalBlock__`类型. 存放在内存中的数据段.
- 访问 static 变量的.
- 访问全局变量的

#### `__NSStackBlock__`

- MRC下访问 auto 变量的
- ARC 会自动 copy 到堆上, 变成 `__NSMallocBlock__`
- `__NSStackBlock__`保存在栈上, 作用域结束会自动销毁.如果捕获变量, 再次调用 block 可能会导致捕获的值错乱.
- 所以想让栈的 block 不销毁, copy 到堆上.

#### `__NSMallocBlock__`

#### ARC 环境下, 编译器会自动 copy 到堆上.

- block 作为函数返回值
- block 强指针引用
- block 方法名中有 usingBlock
- GCD 方法的参数

#### `__weak` , ` __block`

无论是 `__weak`还是`__block`, ARC 环境下, 只要 block 在栈空间, 没有被强引用. 都不会对 Person 对象进行强引用

#### copy

block 执行 copy, 会自动调用`__main_block_copy_0`.

```c++
static void __main_block_copy_0(struct __main_block_impl_0 *dst, struct __main_block_impl_0 *src) {
  // 根据外面 __weak 还是__Strong 进行强引用和弱引用操作
  _Block_object_assign((void*)&dst->weakPerson, (void*)src->weakPerson, 3/*BLOCK_FIELD_IS_OBJECT*/);
}
```

#### __block

static 修饰的局部变量或全局变量, block 捕获后可以修改值, 但缺点是在内存中不会销毁.

**__block 可以修饰 auto 变量**.

**__block 不能修饰全局变量和静态变量 static**

```C++
struct __Block_byref_age_0 {
  void *__isa;
  __Block_byref_age_0 *__forwarding;
  int __flags;
  int __Size;
  int age;
}
```

修改 age

```c++
struct __main_block_impl_0 {
  ...
  __Block_byref_age_0 *age; //by ref
  ...
}

static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_age_0 *age = __cself->age;
  (age-> __forwarding->age) = 20;
}
```

- block 通过内部成员 `__Block_byref_age_0 *age` 找到`__Block_byref_age_0` 结构体.
- 通过结构体中的`__forwarding`指针, 拿到其内部成员 age
- 从而修改 age 的值.

#### __block 内存管理

修改 auto 变量时

- block 在栈上时, 不会对 `__block` 产生强引用
- copy 到堆上
  - 调用 block内部的 `__main_block_copy_0`函数
  - `__main_block_copy_0` 函数内部调用`__Block_object_assign` 函数
  - `__Block_object_assign` 对`__block` 变量形成强引用.

- 堆中移除
  - 调用block 内部的`__main_block_dispose_0`函数
  - `__main_block_dispose_0`内部调用`_Block_object_dispose`, 从而释放`__block`变量

修饰对象类型变量时

- block 在栈上时, 不会对指向的对象产生强引用
- copy 到堆上时
  - 同上, 最后会根据对象的修饰符做出相应操作(`__strong`, __`__weak`, `__unsafe_unretained`)
- 堆中移除
  - 同上

#### block 循环引用

原因:

- block 内部对 Person 强引用
- person 属性对 block 强引用

ARC 环境下

- __weak
  - 弱引用, 被其修饰的指针指向的对象销毁时, 自动让这个指针置为 nil, 防止野指针错误(指针指向的位置不可知的, 指针没有被初始化.)
- __unsafe_unretained
  - 弱引用, 但当期修饰的指针指向对象销毁时, 指针指向不变, 不会置为 nil, 会发生野指针错误.

- __block 修饰的对象, 在 block 内部将其置为 nil. 这种使用率不高.

### 五. Category

```c++
	struct _category_t {
    const char *name;
    struct _class_t *cls;
    const struct _method_list_t *instance_methods;
    const struct _method_list_t *class_methods;
    const struct _protocol_list_t *protocols;
    const struct _prop_list_t *properties;
  }
```

- 分类编译完后, 所有信息都会整合到 `_category_t` 结构体中.

运行时, 会将分类 `_category_t`中的`intance_methods`合并到`class 对象`中去.

会将分类`_category_t`中的`class_methods`合并到`meta-class对象`中去.

```C++
void objc_init(void) {
  ...
  _dyld_objc_notify_register(&map_images, load_images, unmap_images);
}
```

- map_images; 
  - dyld 动态加载器将 `image` 加载到内存时会触发
- load_images
  - dyld 初始化 `image`会触发.(+load方法此时会调用)
- unmap_images;
  - dyld将`image`移除时会触发.

```c++
void map_images(unsigned count, const char *const paths[]. const struct mach_header *const mhdrs[]) {
  return map_images_nolock(count, paths, mhdrs);
}

void map_images_nolock(unsigned mhCount, const char * const mhPaths[], const struct mach_header *const mhdrs[]) {
  //...
  if (hCount > 0) {
    _read_images(hList, hCount, totalClasses, unoptimizedTotalClasses);
  }
}

void _read_images(header_info **hList, uint32_t hCount, int totalClasses, int unoptimizedTotalClasses) {
  for (EACH_HEADER) {
    // 二维数组
    category_t **catlist = _getObjc2CategoryList(hi, &count);
    
    for (int i = 0; i<count; i++) {
    	category_t *cat = catlist[i];
      Class cls = remapClass(cat->cls);
      
      if (cat->instanceMethods || cat->protocols || cat->instanceProperties) {
        // 重新组织 class 对象的方法
        remethodizeClass(cls);
      }
      
      if (cat->classMethods || cat->protocols || (hasClassProperties && cat->_classProperties)) {
        // 重新组合下 meta-class 对象的方法
        remethodizeClass(cls->ISA);
      }
      
    }
    
  }
}

static void remethodizeClass(Class cls) {
  category_list *cats;
  if (cats = unattachedCategoriesForClass(cls, false)) {
    // 核心方法, 将 cats 附加到 cls 中
    attachCategories(cls, cats, true);
  }
}

static void attachCategories(Class cls, category_list *cats, bool flush_caches) {
  bool isMeta = cls->isMetaClass();
  
  method_list_t **mlists = (method_list_t **)malloc(cats->count * sizeof(*mlists));
  propery_list_t **proplists = (propery_list_t **)malloc(cats->count * sizeof(*proplists));
  protocol_list_t **protolists = (protocol_list_t **)malloc(cats->count *sizeof(**protolists));
  
  int mcount = 0;
  int propcount = 0;
  int protocount = 0;
  
  int i = cats->count;
  while(i--) {
    // 取出某个分类
    auto& entry = cats->list[i];
    
    // 根据 isMeta 决定取出类方法还是对象方法.
    method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
    if (mlist) {
      mlists[mcount++] = mlist;
    }
    
    // 取属性
    property_list_t *proplist = entry.cat->propertiesForMeta(isMeta);
    if (proplist) {
      proplists[propcount++] = proplist;
    }
    
    // 取协议
    protocol_list_t *protolist = entry.cat->protocols;
    if (protolist) {
      protolists[protocount++] = protolist;
    }
    
  }
  
  // 类对象数据
  auto rw = cls->data();
  
  // 取出类对象中的方法列表, 将所有分类的对象方法加进去
  rw->methods.attachLists(mlists, mcount);
  // 加属性
  rw->properties.attachLists(proplists, propcount);
  // 加协议
  rw->protocols.attachLists(protolists, protocount);
  
}

void attachLists(List *const *addedLists, uint32_t addedCount) {
  if (hasArray()) {
    uint32_t oldCount = array() -> count;
    uint32_t newCount = oldCount + addedCount;
    // 重新分配内存
    setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
    
    // 将原类对象的信息列表, 在内存中向后移动 addedCount位
    memmove(array()->lists + addedCount, array()->lists, 
                    oldCount * sizeof(array()->lists[0]));
    // 将分类总信息列表 copy 到原先类的信息列表中
    memcpy(array()->lists, addedLists, 
                   addedCount * sizeof(array()->lists[0]));
  }
}
```

- 分类方法优先调用.
- 最后编译的分类, 找到方法则优先调用

#### 分类和类拓展的区别

- 分类是`运行时`将数据合并到类信息中
- 类拓展是`编译时`, 数据已经包含在类信息中了.

```objc
@interface Person()

@end
```

#### 分类添加成员变量

- 用关联对象

#### 关联对象原理:

```objc
objc_setAssociatedObject(id object, const void* key, id value, objc_AssociationPolicy policy);
```

- `id object` . 需要关联对象的对象. 如果是当前对象,传 self
- `const void * key`. 存值取值的 key
- `id value`: 关联什么值.
- `objc_AssociationPolicy policy`: 关联策略.涉及到内存管理

```objc
void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy) {
  _object_set_associative_reference(object, key, value, policy);
}

void _object_set_associative_refrence(id object, const void *key, id value, uintptr_t policy) {
  {
    AssociationsManager manager;
    AssociationsHashMap &associations(manager.get());
  }
}

class AssociationsManager {
    using Storage = ExplicitInitDenseMap<DisguisedPtr<objc_object>, ObjectAssociationMap>;
    static Storage _mapStorage;

public:
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }

    AssociationsHashMap &get() {
        return _mapStorage.get();
    }

    static void init() {
        _mapStorage.init();
    }
};

typedef DenseMap<DisguisedPtr<objc_object>, ObjectAssociationMap> AssociationsHashMap;

typedef DenseMap<const void *, ObjcAssociation> ObjectAssociationMap;

class ObjcAssociation {
  uintptr_t _policy;
  id _value;
  ...
}
```

- `AssociationsManager` 内部有个` AssociationsHashMap`.
- 通过 `key (即第一个参数 id object, 用它的内存地址做 key)`, 在 `AssociationsHashMap` 中找到`ObjectAssociationMap`.
- 通过`key (即第二个参数, const void*key)`,  在`ObjectAssociationMap` 中找到`ObjcAssociation`.从而找到`_policy 和 _value`.

关联对象并不是存储在被关联对象本身内存中 , 而是存储在一个全局的 `AssociationsManager` 中.

设置关联对象为 nil, 可以移除关联对象.

被关联对象释放的话, 那么关联对象也会被自动移除.

### 六. @dynamic 和 @synthesize

首先声明一个属性,如

```objc
@property (nonatomic, assign) int age;
```

- 默认会生成属性的成员变量 `_age`
- 对应的 `setAge:` 及`-(int)age` 声明及实现.

能自动生成, 本质是` @synthesize`关键字.

`@dynamic`作用:

```objc
@dynamic age;
```

- 告诉编译器, 不要自动生成`setter`和`getter`方法的实现.
- 不要自动生成成员变量.

###  七. RunLoop

[参考文章](https://blog.ibireme.com/2015/05/18/runloop/)

#### RunLoop 概念

一般一个线程一次只能执行一个任务, 执行完后线程就会退出, 需要一个机制, 让线程能随时处理事件但并不退出. 这种模型成为 `EventLoop`.

所以 RunLoop 其实就一个对象

- 管理了其需要处理的事件和消息.
- 提供一个入口函数来执行上面 EventLoop 的逻辑.
- 线程执行这个函数后, 就会一直处于这个函数内部的循环中, 直到循环结束, 函数返回.

`NSRunLoop`是对`CFRunLoopRef`的一个封装, 提供了面向对象的 API, 但是这些 API 不是线程安全的.

`CFRunLoopRef`提供了纯 C 函数的 API, 是线程安全的.

#### RunLoop 和线程的关系.

- RunLoop 和线程一一对应的
- 线程刚创建时并没有 RunLoop, 如果你不主动获取, 那么它一直不会有.
- RunLoop 的创建是发生在第一次获取时
- RunLoop 的销毁时发生在线程结束时.
- 除了主线程, 你只能在一个线程的内部获取其 RunLoop.

iOS 中遇到的两个线程对象:

- `pthread_t`
- `NSThread`

```objc
// 获取主线程
[NSThread mainThread]
或者
pthread_main_thread_np()
  
// 获取当前线程
[NSThread currentThread]
 或者
pthread_self()
```

- CFRunLoop 是基于 pthread 来管理的.

苹果不允许直接创建 RunLoop, 只提供了两个自动获取的函数:

- `CFRunLoopGetMain()`
- `CFRunLoopGetCurrent()`

内部逻辑大致:

```c++
// 全局字典, key 是 pthread_t, value 是 CFRunLoopRef
static CFMutableDictionaryRef loopsDic;
// 访问 loopsDic 时的锁
static CFSpinLock_t loopsLock;

// 获取一个 pthread 对应的 RunLoop
CFRunLoopRef _CFRunLoopGet(pthread_t thread) {
  OSSpinLockLock(&loopsLock);
  if (!loosDic) {
    // 第一次进出, 初始全局 Dic, 并先为主线程创建 RunLoop
    loopsDic = CFDictionaryCreateMutable();
    CFRunLoopRef mainLoop = _CFRunLoopCreate();
    CFDictionarySetValue(loopsDic, pthread_main_thread_np(), mainLoop);
  }
  // 取出 RunLoop
  CFRunLoopRef loop = CFDictionaryGetValue(loopsDic, thread);
  if (!loop) {
    // 取不到就创建
    loop = _CFRunLoopCreate();
    // 存到字典中
    CFDictionarySetValue(loopsDic, thread, loop);
    // 注册一个回调,  当线程销毁时, 销毁对应的 RunLoop
    _CFSetTSD(..., thread, loop, __CFFinalizeRunLoop);
  }
  OSSpinLockUnLock(&loopsLock);
  return loop;
}

CFRunLoopRef CFRunLoopGetMain () {
  return _CFRunLoopGet(pthread_main_thread_np);
}

CFRunLoopRef CFRunLoopGetCurrent() {
  return _CFRunLoopGet(pthread_self());
}
```

#### RunLoop 对外接口

一个 RunLoop 中包含若干个`Mode`.

每个`Mode`包含:

- Source
- Timer
- Observer

RunLoop 每次被调用时, 只能指定其中一个 Mode, 这个就是`CurrentMode`.

如果要切换 Mode, 只能退出当前 Loop 并重新指定一个 Mode 进入.

**CFRunLoopSourceRef**

- 事件产生的地方
- Source0
  - 只包含一个回调(函数指针). 不会主动触发事件.
- Source1
  - 包含一个`mach_port` 和一个回调 (函数指针). 
  - 用来通过内核和其他线程互发消息.
  - 能主动唤醒 RunLoop 的线程.

**CFRunLoopTimerRef**

- 基于时间触发器.
- 包含一个时间长度和回调(函数指针).
- 加入 RunLoop 后, RunLoop 会注册对应的时间点, 时间点到了 RunLoop 会被唤醒执行回调.

**CFRunLoopObserverRef**

- 观察者.
- 包含一个回调(函数指针)
- RunLoop 状态发生变化时, 观察左可以通过回调接收到变化.
- 时间节点如下:

```objc
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
  kCFRunLoopEntry						= (1UL << 0)	// 即将进入 Loop
  kCFRunLoopBeforeTimers	  = (1UL << 1)	// 即将处理 timer
  kCFRunLoopBeforeSources   = (1UL << 2)	// 即将处理 source
  kCFRunLoopBeforeWaiting		= (1UL << 5)	// 即将进入休眠
  kCFRunLoopAfterWaiting		= (1UL << 6)	// 即将从休眠中唤醒
  kCFRunLoopExit						= (1UL << 7)	// 即将退出 Loop
}
```

source/Timer/Observer被统称为**mode item**; 一个 item 可以同时被加入多个 Mode, 但一个 item 被重复加入同一个 Mode 是不会有效果的.

如果一个 Mode 中一个 item 都没有, 则 RunLoop 会直接退出.不进入循环

#### Mode

```objc
struct __CFRunLoopMode {
  CFStringRef _name;
  CFMutableSetRef _source0;
  CFMutableSetRef _source1;
  CFMutableArrayRef _observers;
  CFMutableArrayRef _timers;
  ...
}

struct _CFRunLoop {
  CFMutableSetRef _commonModes;	
  CFMutableSetRef _commonModeItems;	// Set<Source/Observer/Timer>
  CFRunLoopModeRef _currentMode;
  CFMutableSetRef _modes;
}
```

- 一个 Mode 可以将自己标记为`common`.属性. 每当 RunLoop 内容发生变化时, RunLoop 都会自动将 _commonModeItems 里的 Source/Observer/Timer 同步到具有`common` 标记的所有 Mode 里.
- 比如主线程 RunLoop 有两个预置的 Model, 均都被标记为`common`.
  - kCFRunLoopDefaultMode (NSDefaultRunLoopMode)
  - UITrackingRunLoopMode

- 苹果同时还提供一个操作 common 标记的字符串.
  - kCFRunLoopCommonModes (NSRunLoopCommonModes)

#### RunLoop 的内部逻辑

![RunLoop_1](https://blog.ibireme.com/wp-content/uploads/2015/05/RunLoop_1.png)

RunLoop 核心基于 mach port. 其进入休眠时调用的函数是 `mach_msg()`.

- RunLoop 调用 `mach_msg()` 函数去接收消息. 
- 如果没人发送 port 消息过来, 内核将线程置于等待状态.

#### AutoreleasePool

App 启动后, 苹果在主线程 RunLoop 里注册了两个 Observer, 回调都是 `_wrapRunLoopWithAutoreleasePoolHandler()`.

- 第一个监视 `Entry`事件.
  - 其回调内调用 `_objc_autoreleasePoolPush()` 创建自动释放池. 优先级高.
- 第二个监视了 2 个事件. 
  - `BeforeWaiting` 时调用`_objc_autoreleasePoolPop()` 和 `_objc_autoreleasePoolPush()` 释放旧的池并创建新池.
  - `Exit` 时调用 `_objc_autoreleasePoolPop()` 释放自动释放池.

### 八 isMemberOfClass: 和 isKindOfClass:

```objc
+ (BOOL)isMemberOfClass:(Class)cls {
  return object_getClass((id)self) == cls;
}

- (BOOL)isMemberOfClass:(Class)cls {
  return [self class] == cls;
}

+ (BOOL)isKindOfClass:(Class)cls {
  for (Class tcls = object_getClass((id)self); tcls; tcls=tcls->superclass) {
    if (tcls == cls) return YES;
  }
  return NO;
}

- (BOOL)isKindOfClass:(Class)cls {
  for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
    if (tcls == cls) return YES;
  }
  return NO;
}
```

### 九. runtime

#### isa

```c++
struct objc_object {
  isa_t isa;
}

```

#### Class

```c++
typedef struct objc_object *id;
typedef struct objc_class *Class;

struct objc_class : objc_object {
  Class superclass;
  cache_t cache;
  class_data_bits_t bits;
}

struct objc_object {
private: 
  isa_t isa;
public:
  Class ISA();
  Class getIsa();
}

struct class_data_bits_t {
  uintptr_t bits;
  
  class_rw_t * data() {
    return (class_rw_t *)(bits & FAST_DATA_MASK);
  }
}
```

#### class_rw_t

```c++
struct class_rw_t {
  const class_ro_t *ro;
  method_array_t methods;
  property_array_t properties;
  protocol_array_t protocols;
}
```

#### class_ro_t 

```c++
struct class_ro_t {
  const uint8_t *ivarLayout;
  const char *name;
  method_list_t *baseMethodList;
  protocol_list_t *baseProtocols;
  const ivar_list_t *ivars;
  
  const uint8_t *weakIvarLayout;
  property_list_t *baseProperties;
}
```

#### class_rw_t 与 class_ro_t 关系

- `class_rw_t`, 即 `read write`
- `class_ro_t` 即 `read only`

- `ro` 数据在 runtime 阶段会拷贝到`rw`中.
- 类的结构体在编译器`ro`的数据已经处理完毕.

#### method_t

`method_array_t`

- 里面是 `method_list_t`
  - 里面是 `method_t`

```c++
struct method_t {
  SEL name;
  const char *types;
  IMP imp;
}
```

#### cache_t

```C++
struct cache_t {
  struct bucket_t *_buckets;	// 数组, 里面装的散列表
  mask_t mask;	// 散列表长度
  mask_t _occupied;	// 已缓存的方法数量
}
```

- `struct bucket_t`
  - 找到 key, 如果和 `SEL` 相同, 直接拿函数地址进行调用.

```c++
struct bucket_t {
private:
  cache_key_t _key;	// SEL 作为 key
  IMP _imp;	// 函数内存地址
}
```

### 十. NSProxy

做消息转发的类

```objc
@interface TYProxy : NSProxy 

@property (nonatomic, weak) id target;
+ (instancetype)proxyWithTarget:(id)target

@end
  
@implementation TYProxy
  
+ (instancetype)proxyWithTarget:(id)target {
  TYProxy *p = [[TYProxy alloc] init];
  p.target = target;
  return p;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  [invocation invokeWithTarget:self.target];
}
  
@end
```

### 十一. super

```objc
struct objc_super {
  __unsafe_unretained id receiver;	// 消息接收者
  __unsafe_unretained Class super_class;	// 消息接收者的父类
}
```



### 十二. 内存管理

#### Tagged Pointer

小对象. 如优化 NSNumber, NSDate, NSString 等小对象存储.

```objc
NSNumber *num= @1;
int a = [num intValue];
```

- `[num intValue]` 会走 `objc_msgSend(num, @selector(intValue))`.
- 但是 `num` 这里是 `tagged Pointer`, 不是 OC 对象. 没办法通过 `isa` 去找到 `intValue`方法
- `objc_msgSend`内部会判断是否是`tagger pointer`类型, 如果是, 直接从指针取出它的值.

#### OC 对象内存管理

- 引用计数
- 新创建的 OC 对象引用计数默认为 1, 当减为 0 时, 对象自动销毁. 释放内存
- `retain`加 1, `release`减 1.

**copy**

- 不可变拷贝. 产生不可变副本
- 浅拷贝, 指针拷贝, 不产生新的对象

**mutableCopy**

- 可变拷贝, 产生可变副本.
- 深拷贝, 内容拷贝, 产生新的对象

**property** 修饰

copy 本质

```objc
- (void)setData:(NSArray *)data {
  if (_data != data) {
    [data release];
    _data = [data copy];
  }
}
```

**引用计数**

- 存在`isa` 中.
- `isa` 中存不下, 存到`SideTable` 中, 里面有个散列表

```c++
struct SideTable {
  spinlock_t slock;
  RefcountMap refcnts; 			// 引用计数表
  weak_table_t weak_table;	// 弱引用表
}
```

- release

```objc
- (void)release {
  _objc_rootRelease(self);
}

sidetable_release() {
  
}
```

- retain

```objc
sidetable_retain() {
  
}
```

**weak 原理**

```c++
objc_object::	clearDeallocating_slow() {
  SideTable &table = SideTables()[this];
  table.lock();
  if (isa().weakly_referenced) {
        // sideTable中的 weak_table
      weak_clear_no_lock(&table.weak_table, (id)this);
  }
  if (isa().has_sidetable_rc) {
      table.refcnts.erase(this);
  }
  table.unlock();
}

void weak_clear_no_lock(weak_table_t *weak_table, id referent_id){ 
  objc_object *referent = (objc_object *)referent_id;
  weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
  
  for (size_t i = 0; i < count; ++i) {
    objc_object **ref = referrers[i];
    if (ref) {
      if (*ref == ref) {
        // 引用计数清空
        *ref = nil;
      }
    }
  }
  // 移除
  weak_entry_remove(weak_table, entry);
}
```

#### autoreleasePool

```C++
struct _AtAutoreleasePool {
  _AtAutoreleasePool() {
    atautoreleasepoolobj = objc_autoreleasePoolPush();
  }
  ~_AtAutoreleasePool() {
    objc_autoreleasePoolPop(atautoreleasepoolobjc);
  }
  void * atautoreleasepoolobj;
}

void * objc_autoreleasePoolPush(void) {
  return AutoreleasePoolPage::push();
}

void objc_autoreleasePoolPop(void *ctxt) {
  AutoreleasePoolPage::pop(ctxt);
}

class AutoreleasePoolPage {
  ...
  id *next;
  pthread_t const thread;
  AutoreleasePoolPage *const parent;
  AutoreleasePoolPage *child;
  ...
}
```

```objc
@autoreleasepool {
  
}

// 大括号开始, 调用构造函数
// 大括号结束, 调用析构函数
```

**调用 push** 时.

- 将一个`POOL_BOUNDARY` 入栈. `#define POOL_BOUNDARY nil`.

- 然后将`autorelease`对象入栈.

  

**调用 pop 时**

- 最后一个入栈的对象开始, 发送 `release`消息, 直到遇到`POOL_BOUNDARY`结束.
- `id *next` 指向了下一个能存放`autorelease`对象地址的区域.

### 十三. GCD

**同步**

- 立马在`当前线程`执行任务, 且执行完毕才能继续往下执行

```objc
dispatch_sync(dispatch_queue_t queue, dispatch_block_t block);
```

**异步**

- 可以开启`子线程`,但主队列还是在主线程

```objc
dispatch_async(dispatch_queue_t queue, dispatch_block_t block);
```

**并发队列**

- 让任务`并发(同时)`执行
- 自动开启多个线程同时执行
- 只在异步函数下有效

**串行队列**

- 任务一个接一个执行

**死锁**

- 使用`sync` 函数, 往`当前串行队列`中添加任务. 就会产生死锁, 会卡住当前的串行队列.

**队列组**

```objc
dispatch_group_t group = dispatch_group_create();
  dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
      for (int i = 0; i < 10; i++) {
          NSLog(@"执行任务1");
      }
  });

  dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
      for (int i = 0; i < 10; i++) {
          NSLog(@"执行任务2");
      }
  });

  // 等上面的执行完了
  dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
      for (int i = 0; i < 10; i++) {
          NSLog(@"执行任务3");
      }
  });
```

#### 多线程安全隐患

- 资源共享, 被多条线程同时访问一个资源, 资源抢夺. 数据容易错乱

使用`线程同步`技术. 如加锁

**OSSpinLock**

```objc
OSSpinLockLock(&_lock);
OSSpinLockUnLock(&_lock);
```

- 加锁后, 其他线程访问时则处于忙等状态.一直占用 CPU 资源.
- 目前不安全. 会出现优先级反转问题.
  - 开始低优先级线程先进来了, 加锁.
  - 后面高优先级线程进来, 系统为其分配任务, 因为有锁,则会一直处于忙等状态.
  - 低优先级因为没有被分配任务, 所以不执行, 这个锁就不会被打开.

**_unfair_lock**

- iOS 10 之后用来取代 `OSSpinLock`.

- 休眠. 非忙等.

```objc
os_unfair_lock_lock(&lock);
os_unfair_lock_unlock(&lock);
```

**pthread_mutex**

```objc
pthread_mutex_init(&_mutex, &attr);
pthread_mutex_lock(&_mutex);
pthread_mutex_unlock(&_mutex);
pthread_mutexattr_destroy(&attr);
```

**NSLock**

```objc
- (void)lock;
- (void)unlock;
```

**dispatch_semaphore信号量**

- 初始值, 可以用来控制线程并发访问的最大数量.
- 初始值为 1, 效果同 pthread_mutex

```objc
// 初始化
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
// 信号量的值 <=0, 线程进入休眠
// 信号量值> 0, 减 1, 然后往下执行后面的代码
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
// 信号量值加 1
dispatch_semaphore_signal(semaphore);
```

**@synchronized**

对`mutex`锁封装.

**atomic**

- 原子的
- 保证 setter 和 getter 方法内部是线程同步的.

