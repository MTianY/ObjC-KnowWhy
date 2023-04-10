# block 的循环引用

## 一.循环引用产生的原因分析

首先看一段产生循环引用的代码:

- `TYPerson` 对象中定义了2个属性

```objc
typedef void(^Test1Block)(void);
@interface TYPerson : NSObject
@property (nonatomic, copy) Test1Block test1Block;
@property (nonatomic, assign) int age;
@end
```

- 下面代码的写法则会产生循环引用.
    - 打印只有 `-------`
    - 并没有执行 person 的 dealloc, 说明 person 没有被释放掉 

```objc
int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        {
            TYPerson *person = [TYPerson new];
            person.age = 20;
            person.test1Block = ^{
                NSLog(@"age = %d",person.age);
            };
        }
        
        NSLog(@"-------");
        
    }

    return 0;
}
```

循环引用的原因分析

- 首先看下 block 内部

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  TYPerson *__strong person;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, TYPerson *__strong _person, int flags=0) : person(_person) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- 可以看到 block 内部对 person 对象是有个强引用的`TYPerson *_strong person`.
- 而看`TYPerson`.它的属性 `@property (nonatomic, copy) Test1Block test1Block;` 
    - 表明它的成员变量 `_test1Block` 会对 block 产生一个强引用.
- 所以上面循环引用产生的原因就是:
    - 首先 `TYPerson *person = [TYPerson new];`  有个 person 的指针指向 TYPerson
    - `person`的`test1Block`在堆上.`test1Block`内部有个 `TYPerson *_strong person`,block 对 person 又有个强引用.
    - 而`TYPerson`的成员变量`_test1Block`又对 block 有个强引用.
    - 所以当上面的代码大括号执行完成后,`TYPerson 对 person 的强引用会断开`,但是 `block 对 person 和 person 内部的成员变量 _test1Block 对 block 的强引用还没有断开`,所以产生了循环引用
- 如下图:

![WechatIMG25](https://lh3.googleusercontent.com/-NY89OsfWV18/W5G4nMka_fI/AAAAAAAAAJk/3Kk5k-W79JkkaNo5L2UYlJTYaNpEGz7xACHMYCw/I/WechatIMG25.jpeg)


## 二.解决循环引用问题

### 2.1 ARC 环境下

在 ARC 环境下,常用的解决方式有2种,一是`__weak`,另一个是`__unsafe_unretained`.

- 将 block 指向 person 的线打断,变成弱引用,就可以解决循环引用.
- `__weak` 是弱引用,同时被其修饰的指针指向的对象销毁时,会自动让这个指针等于 nil. 防止野指针错误.
- `__unsafe_unretained` 也不会产生强引用,但是当它修饰的指针指向的对象销毁时, 该指针仍旧会指向那个内存地址.会造成野指针错误,所以是不安全的,使用率不高.

```objc
int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        {
            TYPerson *person = [TYPerson new];
            person.age = 20;
            //   __weak TYPerson *weakPerson = person;
            //   __unsafe_unretained TYPerson *weakPerson = person;
            __weak typeof(person) weakPerson = person;
person.test1Block = ^{
                NSLog(@"age = %d",weakPerson.age);
            };
        }
        
        NSLog(@"-------");
        
    }

    return 0;
}
```

还有另一种方式解决循环引用,使用率也不是很高.因为其存在弊端:

- 必须要用 __block 修饰对象,因为我们要在 block 内部 `person = nil`;
- 必须要执行 `person.test1Block()`

```objc
int main(int argc, const char * argv[]) {
    
    @autoreleasepool {

        {
            __block TYPerson *person = [TYPerson new];
            person.age = 20;
            
            person.test1Block = ^{
                NSLog(@"age = %d",person.age);
                person = nil;
            };
            person.test1Block();
            
        }
       
        NSLog(@"-------");
        
        
        
    }

    return 0;
}
```

上面这种,首先

- person 对 TYPerson 有一层强引用.
- 然后 `__block`修饰之后,生成的对象,又对 person 有个强引用.
- 然后 person 内部的 `_test1Block` 又对 block 有个强引用.其间关系如下图

![](https://lh3.googleusercontent.com/t2HrBiJfHRYQGYbI9Aip-WGHzxTzZpDYJw0kivSu8_JLqT2yQvM2F7McqpAP0G-8LBiowBEyHvQlUBSfqAE81G4FPmqrHXozKqRWuQNlT00jJlUtbS5FyZnqrmclH9FovCginNvWZj0jBUhNq3Td8PnsLQf6kG3L463YYgSnt20OwN7Hicz8yB9Ilrnbz0mSheCWzKMk89vd8bGR4D_-TdUScXXxyUDCdjpkv7jkuG3eGnIaeCPv7ZA2QWpChHMHfEwoA6wsaQ7_Va8gVl9dYAbzR5YIY-Jntt7PIYchpegr7iqK_JEN9A0njlvOmfVLKthd1D7lnQtj3GdQwAP29j3DQ1h84Orya3HZUgyXuq9inUZNDaw72i54fNiFJTZU2_6acNxPj52yJdky803KRFbXAWwFlFjSIfxhdz2LEw1WOkSmadIbKgMb5XasGrMXQLsrj_UeAUdcJ2hAl8SyKVFFoowr1eMeWKpDXhHyIOdWisapFVz8OO2PcJIgKOygJutmv0Y1Gl-_3U16k2bjCxwfaTwwSCU1cw6gn9X0wy02oP5VvcQMF7ARIZs5k1EDJ-Y0CJmI5-AzqCsCo9OJKduGzljn5wn3mzebCYER4SqH3_RuiGW8MdjHT9gfsjE=w2400-h1288-no)

### 2.2 MRC 环境下

MRC 环境下不支持 `__weak`.所以只能通过 `__unsafe_unretained`来解决. 被它修饰,弱引用,引用计数不会加1.

还以通过另一种方法解决,`__block`.因为在 MRC 环境下,被`__block`修饰,生成的对象也不会对被修饰的对象产生强引用.


