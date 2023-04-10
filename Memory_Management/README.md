# 内存管理

## 使用 CADisplayLink, NSTimer 注意什么?

使用 CADisplayLink, NSTimer 时会对 target 产生强引用, 如果 target 又对他们产生强引用, 那么就会引发`循环引用`.

```objc
@property (nonatomic, strong) CADisplayLink *link;

@property (nonatomic, strong) NSTimer *timer;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 保证调用频率和屏幕刷帧频率一致, 一般情况下 60FPS
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkAction)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    // scheduled... 表示已经默认开启 Runloop 了, 不需要再添加到 Runloop 启动定时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selecor:@selector(timerAction) userInfo:nil repeats:YES];
}

- (void)linkAction {
    NSLog(@"%s",__func__);
}

- (void)timerAction {
    NSLog(@"%s",__func__);
}
```

- self 对 link 强引用
- link 对 target (self) 也有强引用, 二者会引发 循环引用, 导致 CADisplayLink 没有销毁.
- NSTimer 同理会发生循环引用

### 解决定时器循环引用

如果用下面方法能否解决循环引用?

```objc
__weak typeof(self) weakSelf = self;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(timerAction) userInfo:nil repeats:YES];
```

答案不能.

- __weak 一般用在 block 中
- weakSelf 也是传对象地址进去.
- NSTimer 内部会有个强引用引用 target

**方法 1 :** 用带 Block 的方法, block 内部用 weakSelf 调用定时器方法, 可以解决循环引用.

- NSTimer 对 block 强引用
- block 对 self 弱引用
- self 对 timer 强引用

```objc
__weak typeof(self) weakSelf = self;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer){
    [weakSelf timerAction];
}];
```

**方法 2 :** 自定义对象, 其中弱引用原 target, 并在自定义对象中利用`消息转发`, 将方法实现转发到原 target 中调用

```objc
// 自定义 TYProxy 继承自 NSObject
@interface TYProxy : NSObject
// 弱引用 target
@property (nonatomic, weak) id target;
+ (instancetype)proxyWithTarget:(id)target;
@end

@implementation TYProxy

+ (instancetype)proxyWithTarget:(id)target {
    TYProxy p = [[TYProxy alloc] init];
    p.target = target;
    return p;
}

@end

// 定时器中传入 TYProxy
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[TYProxy proxyWithTarget:self] selector:@selector(timerAction) userInfo:nil repeats:YES];

如果此时调用会报找不到 [TYProxy timerAction] 方法.

```

消息转发.

```objc
@implementation TYProxy

+ (instancetype)proxyWithTarget:(id)target {
    TYProxy p = [[TYProxy alloc] init];
    p.target = target;
    return p;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // 将方法调用转发到 target 对象上 objc_msgSend(self.target, aSelector)
    // 就会调用 target(ViewController) 中的 timerAction 方法
    return self.target;
}

@end
```

**方法 3 :** NSProxy

NSProxy 本身就是个基类, `不继承`自 NSObject;

它本身就是做消息转发用的类.

```objc
@interface NSObject <NSObject> {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
    Class isa  OBJC_ISA_AVAILABILITY;
#pragma clang diagnostic pop
}
```

```objc
#import <Foundation/NSObject.h>

@class NSMethodSignature, NSInvocation;

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

NS_ROOT_CLASS
@interface NSProxy <NSObject> {
    __ptrauth_objc_isa_pointer Class	isa;
}

+ (id)alloc;
+ (id)allocWithZone:(nullable NSZone *)zone NS_AUTOMATED_REFCOUNT_UNAVAILABLE;
+ (Class)class;

- (void)forwardInvocation:(NSInvocation *)invocation;
- (nullable NSMethodSignature *)methodSignatureForSelector:(SEL)sel NS_SWIFT_UNAVAILABLE("NSInvocation and related APIs not available");
- (void)dealloc;
- (void)finalize;
@property (readonly, copy) NSString *description;
@property (readonly, copy) NSString *debugDescription;
+ (BOOL)respondsToSelector:(SEL)aSelector;

- (BOOL)allowsWeakReference API_UNAVAILABLE(macos, ios, watchos, tvos);
- (BOOL)retainWeakReference API_UNAVAILABLE(macos, ios, watchos, tvos);

// - (id)forwardingTargetForSelector:(SEL)aSelector;

@end

NS_HEADER_AUDIT_END(nullability, sendability)
```


自定义对象继承 NSProxy

```objc
@interface TYProxy : NSProxy

@property (nonatomic, weak) id target;
+ (instancetype)proxyWithTarget:(id)target;

@end

@implementation TYProxy

+ (instancetype)proxyWithTarget:(id)target {
    // NSProxy 对象不需要调用 init, 本身就是基类, 没有 init 方法.
    // 不需要像继承 NSObject 的类那样, 在 init 做些初始化操作
    TYProxy *p = [TYProxy alloc];
    p.target = target;
    return p;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    // 拿到 target, 返回它的方法签名 
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // 直接调用 target 中的方法
    [invocation invokeWithTarget:self.target];
}

@end
```

**NSProxy 对比 NSObject**

- 执行流程不同, 如果继承自 NSObject
- 寻找方法会先搜索, 类对象,元类对象等
- 如果继承自 NSProxy, 少了搜索方法的流程, 首先看 NSProxy 自己的类中有没有这个方法, 没有直接做消息转发

## GCD 定时器

NSTimer 依赖 RunLoop, 如果 RunLoop 任务过多, 会导致不准时.

RunLoop 每跑一圈所花费的时间, 不固定, 其内部每跑一圈会计算下时间.

- 比如定时器每隔 1s 触发
- RunLoop 第一圈 0.2s, 第二圈 0.4s, 第三圈 0.5, 那么会超过 1s, 才能处理定时器任务, 导致不准时.

使用 GCD 定时器就可以保证准时, 它不依赖 RunLoop, 和系统内核挂钩.

```objc
@property (nonatomic, strong) dispatch_source_t gcdTimer;

dispatch_queue_t queue = dispatch_get_main_queue();
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
dispatch_source_set_event_handler(timer, ^{
   
});
self.gcdTimer = timer;
dispatch_resume(timer);
```

GCD 创建的对象,在 ARC 环境下不需要手动去销毁.

## iOS 程序的内存布局

由低到高

- 保留内存
- 代码段 __TEXT
    - 编译之后的代码 
- 数据段 __DATA
    - 字符串常量, 如 NSString *str = @"xx";
    - 已初始化数据, 已初始化的全局变量、静态变量等
    - 未初始化数据 , 如 int a; static int b;
- 栈 stack
    - 函数调用开销, 比如局部变量. 分配的内存空间地址越来越小
- 堆 heap
    - 通过 alloc, malloc, calloc 等动态分配的空间, 分配的内存空间地址越来越大. 
- 内核区

## Tagged Pointer

从 64bit 开始, iOS 引入 Tagged Pointer 技术, 用来优化 `NSNumber, NSDate, NSString 等小对象的存储`.

在没有使用 Tagged Pointer 之前, NSNumber 等对象需要动态分配内存, 维护引用计数等, NSNumber 指针存储的是堆中 NSNumber 对象的地址值.

如:

```objc
NSNumber *num1 = @4;
NSNumber *num2 = @5;
NSNumber *num3 = @6;

NSLog(@"%p %p %p", num1, num2, num3);
// 打印结果: 0x427 0x527 0x627
```

没有使用 Tagged Pointer 之前, 其内存中布局如下:

- num 指针, 指向堆空间中的 NSNumber 对象, 其中存储值 4.
- 这样存储, 指针要 8 个字节, 一个 NSObject 对象要差不多 16 个字节

使用 Tagged Pointer 之后, NSNumber 指针里面存储的数据变成了: Tag + Data, 也就是讲数据直接存储在了指针中.

- 如 num 指针地址. num = 0x427, 该地址中存储了 tag 和数据的大小. 如 4 存储成 4, 27是 tag,标记
- 所以只用 8 个字节就存储了, 节省内存空间

如果 NSNumber 中存储的数据过大, 那么会恢复成在堆空间中存储

```objc
NSNumber *num = @(0xFFFFFFFFFFFF);
NSLog(@"%p",num);
// 打印地址: 0x103b298c0
```

### 判断是否是 tagged pointer

```objc
// 如果是 iOS 平台, 指针最高有效位是 1, 就是 tagger pointer
#define _OBJC_TAG_MASK (1UL<<63)    // 1左移 63 位

// Mac 平台, 指针最低有效位是 1, 就是 tagger pointer
#define _OBJC_TAG_MASK 1UL

BOOL isTaggedPointer(id pointer) {
    return ((uintptr_t))pointer & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

NSNumber *num1 = @4;
NSNumber *num2 = @5;
NSNumber *num3 = @6;

NSLog(@"%d", isTaggedPointer(num1));
```

### tagger pointer 和 objc_msgSend

如

```objc
NSNumber *num = @1;

int a = [num intValue];
```

- `[num intValue]` 会走 `objc_msgSend(num, @selecor(intValue))`.
- 但是 num 这里是 tagger pointer , 不是 OC 对象, 没办法通过 `isa` 去找到 `intValue` 方法.
- 这里 `objc_msgSend` 方法内部会判断是否是 tagger pointer 类型, 如果是, 则会直接从指针那里取出它的值


### 思路下面 2 段代码会发生什么事情? 有什么区别?

只有字符串不同.

```objc
@property (nonatomic, copy) NSString *name;

// 这个会闪退, 报错 objc_release . EXC_BAD_ACCESS 坏内存访问.
dispatch_queue_t queue1 = dispatch_get_global_queue(0, 0);
for (int i = 0; i < 1000; i ++) {
   dispatch_async(queue1, ^{
       self.name = [NSString stringWithFormat:@"abcdefjhijk"];
   });
}

// 因为 self.name 本质调用其 set 方法, Set 方法本质就是先 release,再 retain
// 当有多条线程同时访问时, 线程 1 已经 release 了, 线程 2 又 release, 则会报释放错误.
- (void)setName:(NSString *)name {
    if (_name != name) {
        [_name release];
        _name = [name retain];
    }
}

// 解决方案可以改成 atomic 修饰;
// 或者用 nanatomic, 在多线程内部加锁. 解锁 (推荐)


// 这个不会崩溃.
// 字符串少, 会变成 tagger pointer, 存在指针地址中. 不是 OC 对象了
dispatch_queue_t queue2 = dispatch_get_global_queue(0, 0);
for (int i = 0; i < 1000; i ++) {
   dispatch_async(queue2, ^{
       self.name = [NSString stringWithFormat:@"abc"];
   });
}
```

## OC 对象的内存管理

- 在 iOS 中, 使用 `引用计数` 来管理 OC 对象的内存.
- 一个新创建的 OC 对象引用计数默认是 1, 当引用计数减为 0, OC 对象就会销毁, 释放其占用的内存空间
- 调用 `retain` 会让 OC 对象的引用计数 `+1`. 调用 `release` 会让 OC 对象的引用计数 `-1`.

模拟 MRC, 可以在 Xcode 中关闭 ARC.

- Build Settings -> 搜索 automatic re, Object-C Automatic Reference Counting 设置为 NO.

```objc
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *p = [[Person alloc] init];  // 创建完对象, 引用计算加 1
        NSLog(@"%d",p.retainCount); // 打印对象的引用计数
        [p release];    // 引用计数减 1. 引用计数为 0, 对象释放
        
        
        // 如果不想写 release, 可以在创建完对象后, 写 autorelease. 在恰当时候, 会为调用过 autorelease 对象调用 release, 自动释放
        Person *p1 = [[[Person alloc] init] autorelease];
    }
    
}
```

### copy

拷贝的目的: 产生一个副本对象,跟原对象互不影响.

- `copy`: 不可变拷贝, 产生不可变副本.
- `mutableCopy`: 可变拷贝, 产生可变副本.

1.创建一个不可变字符串

```objc
NSString *str1 = [NSString stringWithFormat:@"test"];
// 返回不可变字符串 NSString
NSString *str2 = [str1 copy];

// 返回可变字符串 NSMutableString
NSMutableString *str3 = [str1 mutableCopy];

// 如 str3 可以拼接其他字符串
[str3 appendString:@"123"];

// 这样 str3 就是 test123
```

2.创建一个可变的字符串

```objc
NSMutableString *str1 = [NSMutableString stringWithFormat:@"test"];
// 返回一个不可变字符串
NSString *str2 = [str1 copy];
// 返回一个可变的字符串
NSMutableString *str3 = [str1 mutableCopy];
```

所以得出结论: 

- 调用 `copy` 返回的就是不可变的.
- 调用 `mutableCopy` 返回的就是可变的.

### copy 内存管理

`MRC`环境下,`copy`后要记得`release`操作.

### 深拷贝、浅拷贝

##### 深拷贝:

- 内容拷贝, 产生新的对象

##### 浅拷贝:

- 指针拷贝, 没有产生新的对象

##### 1. NSString 和 NSMutableString 为例:

1. 先定义一个不可变字符串

```objc
NSString *string1 = [NSString stringWithFormat:@"test"];
```

```objc
// copy
// 返回一个不可变字符串
// 浅拷贝
NSString *string2 = [string1 copy];

// mutableCopy
// 返回一个可变字符串
// 深拷贝
NSMutableString *string3 = [string1 mutableCopy];
```

内存图:
![](https://lh3.googleusercontent.com/-dDUQdGv4X7w/W9fjm91elOI/AAAAAAAAAQM/5qxLAReH-q8FP8JV4TavJMhRzL5tWDaLgCHMYCw/I/15408751568928.jpg)



2. 定义一个可变字符串

```objc
NSMutableString *string1 = [NSMutableString stringWithFormat:@"test"];
```

```objc
// copy
// 返回一个不可变字符串
// 深拷贝
NSString *string2 = [string1 copy];

// mutableCopy
// 返回一个可变字符串
// 浅拷贝
NSMutableString *string3 = [string1 mutableCopy];
```

内存图:

![](https://lh3.googleusercontent.com/-CotZm8O0gX0/W9fj9M19ngI/AAAAAAAAAQU/JkLux0ZHG0guz7CuJauuW3qj8fD3s_6uACHMYCw/I/15408752455424.jpg)


##### 总结:

- 如果一开始就是不可变的, 那么执行`copy`操作,会返回一个不可变,既然都是不可变的,那么就拷贝指针就好,不用另开辟内存去存同一个不可变的东西,因为不可变别人本来也不能改变它.所以是浅拷贝,指针拷贝
- 深拷贝,内容拷贝,拷贝后在内存另开辟了一个空间存新拷贝的东西.


##### 2. NSArray 、 NSMutableArray 为例(NSDictionary 和 NSMutableDictionary 与这个都类似)

```objc
NSArray *array1 = [[NSArray alloc] initWithObjects:@"a", @"b", nil];

// 浅拷贝
NSArray *arr2 = [array1 copy];

// 深拷贝
NSMutableArray *arr3 = [array1 mutableCopy];
```

## @property 的 修饰

都是对 set 方法的管理不一样

- `assign`

直接返回值

- `retain`

在 set 先 release 掉之前的值,然后 retain 新的值.

- `copy`

举例

```objc
// TYPerson 有个属性
@property (nonatomic, copy) NSArray *data;

TYPerson *p = [[TYPerson alloc] init];
p.data = @[@"jack", @"ros"];

那么其本质就是
- (void)setData:(NSArray *)data {
    if(_data != data) {
        [_data release];
        _data = [data copy];
    }
}

- (void)dealloc {
    self.data = nil;
    [super dealloc];
}
```

所以用下面这个属性定义,如果使用 set 方法就会报错

```objc
@property (nonatomic, copy) NSMutableArray *array;
```

如果使用这个 `array` 的 `set` 方法,那么会先 `release`, 然后 `copy`, 为一个不可变的数组,如果再往里加东西,直接崩,找不到 `addObject:` 的方法.

### 引用计数

从`arm64`开始,对`isa`有了优化,`引用计数`就存储在这个`isa`指针中.

- `isa`中只有19位.如果不够存储的话,那么就会存到 `SideTable`类中.里面有个散列表,用来存

```objc
> NSObject.mm

struct SideTable {
    spinlock_t slock;
    RefcountMap refcnts;    // 存放着对象引用计数的散列表
    weak_table_t weak_table;
}
```

**release**

```objc
-(oneway void)release {
    _objc_rootRelease(self);
}

sidetable_release(bool locked, bool performDealloc) {
    SideTable& table = SideTables()[this];
    
    //...
    
    if (do_dealloc  &&  performDealloc) {
        // 发送 dealloc 信息
        this->performDealloc();
    }
}
```

**retain**

```objc
// 同 release 类似. 调用
sidetable_retain()
```

### weak 指针的原理

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    __strong Person *p1;    // 强引用
    __weak Person *p2;      // 弱引用
    __unsafe_unretained Person *p3; // 弱引用
    
    NSLog(@"1");
    
    {
        Person *p = [[Person alloc] init];
        p1 = p;
    }
    
    NSLog(@"2");
    
}

// 如果 p1 = p, 强引用, 那么打印结果: 1, 2 , [Person dealloc]
// 如果 p2 = p 或者 p3 = p, 弱引用, 那么打印结果: 1, [Person dealloc], 2
```

__weak 与 __unsafe_unretained 区别:

- 都是弱引用
- 但是 __weak 销毁时会将对象赋值为 nil, __unsafe_unretained 不会.

__weak 底层原理:

```objc
clearDeallocating_slow() 函数内部:

objc_object::clearDeallocating_slow()
{
    ASSERT(isa().nonpointer  &&  (isa().weakly_referenced || isa().has_sidetable_rc));
    // sideTable
    SideTable& table = SideTables()[this];
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

void weak_clear_no_lock(weak_table_t *weak_table, id referent_id) {

    objc_object *referent = (objc_object *)referent_id;
    // 取出 entry
    weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
    
    // ...
    for (size_t i = 0; i < count; ++i) {
        objc_object **referrer = referrers[i];
        if (referrer) {
            if (*referrer == referent) {
                 // 引用计数清空
                *referrer = nil;
            }
         //...
    }
    
    // 移除
    weak_entry_remove(weak_table, entry);
}
```

程序运行过程中,将弱引用存在哈希表中,将来销毁时取出销毁,然后将当前对象置为 nil.

weak 需要 runtime 的.

### ARC 帮我们做了什么?

- ARC 是 LLVM 和 runtime 互相协作的结果
- LLVM 编译器可以在我们代码大括号结束之后, 自动帮我们补全 release 操作. 还有 retain, autorelease 操作.
- 像 __weak 这种就需要 runtime 阶段处理. 程序运行中监控到对象销毁时, 处理弱引用.

### Autorelease 什么时候释放?

MRC 环境下代码:

```objc
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *p = [[[Person alloc] init] autorelease];
    }   // 大括号结束, p 就会被释放
    return 0;
}

// 另一种
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"1");
        @autoreleasepool {
            Person *p = [[[Person alloc] init] autorelease];
        }
        NSLog(@"2");
    }  
    return 0;
}
// 打印结果: 1 [Person dealloc] 2

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"1");
        @autoreleasepool {
            // 不调用 autorelease 则不会被释放.
            Person *p = [[Person alloc] init];
        }
        NSLog(@"2");
    }  
    return 0;
}
// 打印结果: 1 2
```

`autoreleasePool` 本质是:

```objc
{
    @autoreleasepool {
        Person *p = [[[Person alloc] init] autorelease];
    }   
}
上面这段代码生成 C++ 代码后:

{
    __AtAutoreleasePool __autoreleasepool;
    Person *p = [[[Person alloc] init] autorelease];
}

而 __AtAutoreleasePool 结构如下:

struct __AtAutoreleasePool {
    __AtAutoreleasePool() {atautoreleasepoolobj = objc_autoreleasePoolPush();}
    ~__AtAutoreleasePool() {objc_autoreleasePoolPop(atautoreleasepoolobjc);}
    void * atautoreleasepoolobj;
}

所以
@autoreleasepool {

}

大括号开始, 调用构造函数,里面调用 objc_autoreleasePoolPush();
大括号结束, 调用析构函数, 里面调用 objc_autoreleasePoolPop()
```

- 开始调用一个 `objc_autoreleasePoolPush()` 
- 并在结束时调用 `objc_autoreleasePoolPop(atautoreleasepoolobj)`

```objc
void * objc_autoreleasePoolPush(void) {
    return AutoreleasePoolPage::push();
}

void objc_autoreleasePoolPop(void *ctxt) {
    AutoreleasePoolPage::pop(ctxt);
}
```

可以看出, 自动释放池 autoreleasePool 主要底层数据结构是: `__AtAutoreleasePool, AutoreleasePoolPage`.

调用了`autorelease` 的对象最终都是通过 `AutoreleasePoolPage` 对象来管理的. 下面看下 AutoreleasePoolPage 如何管理.

简化后的 `AutoreleasePoolPage` 对象如下:

```C++
class AutoreleasePoolPage {
    magic_t const magic;
    id *next;
    pthread_t const thread;  // 线程
    AutoreleasePoolPage * const parent;
    AutoreleasePoolPage *child;
    unit32_t const depth;
    unit32_t hiwat;
}   
```

- `AutoreleasePoolPage` 对象占 `4096` 个字节内存,除了存放自己的成员变量,剩下的空间存 `autorelease` 对象的地址(如果上面调用了 autorelease 的 Person 对象地址值).
- 所有的`AutoreleasePoolPage` 对象通过双向链表的形式连接在一起, 因为 AutoreleasePoolPage 除自身成员变量, 剩余空间都存的调用 autorelease 对象的地址, 如果 4096 字节存放不下了, 那么就会重新创建一个对象存储.

**调用 push 时**

- 调用`push`方法会将一个`POOL_BOUNDARY`入栈, 并且返回其存的内存地址. (POOL_BOUNDARY 类似边界)

```objc
#define POOL_BOUNDARY nil
```


| 内存地址 | AutoreleasePoolPage |
| --- | --- |
| 0x1000 | magic_t magic; |
|  | id *next; |
|  | pthread_t thread; |
|  | AutoreleasePoolPage *parent; |
|  | AutoreleasePoolPage *child; |
|  | uint32_t depth; |
|  | uint32_t hiwat; |
| 0x1038 | POOL_BOUNDARY (begin()) |
|  | person1 |
|  | person2 |
|  | … (如果最后存不下, 新建对象接着存) |
| 0x2000 | …(end()) |


**调用 pop 时**

- 调用`pop`时会传入之前 push 进去的 `POOL_BOUNDARY`的内存地址,从最后一个入栈的对象开始,发送 `release`消息,直到遇到这个`POOL_BOUNDARY`. 比如从 Person1000 对象开始 release, 直到 Person1 对象 release,然后遇到 POOL_BOUNDARY 了结束.
- `id *next` 指向了下一个能存放 `autorelease` 对象地址的区域.

看下面代码, 嵌套的 autoreleasePool

```objc
int main(int argc, const char * argv[]) {
    @autoreleasePool {  // r1 = push()
    
        Person p1 = [[[Person alloc] init] autorelease];
        
        @autoreleasepool {  // r2 = push()
            Person *p2 = [[[Person alloc] init] autorelease];
            
            @autoreleasepool {  // r3 = push()
                Person *p3 = [[[Person alloc] init] autorelease];
            }   // pop(r3)
            
        } // pop(r2)
        
    }   // pop(r1)
    return 0;
}
```

- AutoreleasePoolPage 结构体内存储:
    - POOL_BOUNDARY (第一个pool 的, r1)
    - p1 对象
    - POOL_BOUNDARY (第二个 pool 的, r2)
    - p2 对象
    - POOL_BOUNDARY (第三个 pool 的, r3)
    - p3 对象
   
 - 释放时则依次调用 pop(r3), 找到 POOL_BOUNDARY 结束
 - pop(r2), 找到 POOL_BOUNDARY 结束
 - pop(r1). 找到 POOL_BOUNDARY 结束.

#### autorelease对象 在什么时候调用 release?
#### 问: autoreleasePool 对象什么时候执行 release 操作?

如果是下面这种被 `@autoreleasepool` 包住的,那么就是当大括号结束了就释放.大括号结束会调用 pop()操作, 执行 release.

```objc
@autoreleasepool {
    
}
```

下面 person 对象,调用 autorelease, 什么时候释放的?

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Person 调用 release 由 Runloop 控制
    // 肯呢个在所属的某次 Runloop 循环中, Runloop 休眠之前调用了 release.
    Person *p = [[[Person alloc] init] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%s",__func__);
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%s",__func__);
}

// 打印结果: 
-[ViewController viewDidLoad]
-[ViewController viewWillAppear:]
-[Person dealloc]
-[ViewController viewDidAppear:]
```

#### RunLoop 和 Autorelease

- 因为 `iOS` 默认在主线程的 `RunLoop` 中注册了 `2个Observer`.
- 第一个`Observer`监听了 `KCFRunLoopEntry` 事件,会调用 `objc_autoreleasePoolPush()`.
- 第二个`Observer`监听`KCFRunLoopBeforeWaiting (即将休眠)` 事件,这时会调用 `objc_autoreleasePoolPop()`, `objc_autoreleasePoolPush()`操作.
- 同时第二个`Observer`也监听了`KCFRunLoopBeforeExit(即将退出)`事件,会调用`objc_autoreleasePoolPop()` .

    
所以,如果问局部变量什么时候释放? 那要看`ARC(现在都是 ARC)`是用`autoreleasePool` 技术还是`release`技术,如果是前者,那么要看 RunLoop, 如果是后者,大括号结束就立即释放.xin


