# isEqual

[参考文章: NShipster.cn/Equality](https://nshipster.cn/equality/)

`isEqual` 是 `NSObject`的一个协议方法.

```objc
@protocol NSObject

- (BOOL)isEqual:(id)object;

@property (readonly) NSUInteger hash;

- (instancetype)self;

@end
```

其底层实现:

```objective-c
- (id)self {
  return self;
}

+ (id)self {
	return (id)self;
}

+ (NSUInteger)hash {
  return _objc_rootHash(self);
}

- (NSUInteger)hash {
  return _objc_rootHash(self);
}

- (BOOL)isEqual:(id)obj {
  return obj == self;
}

+ (BOOL)isEqual:(id)obj {
 	return obj == (id)self; 
}
```

对于基本数据类型如`int`等, `==`比较的值大小. 对于对象`id`, `==`比较的则是对象的地址是否相同.

### Equality & Identity

当两个物体有一系列相同的可观测的属性时, 两个物体可能是互相 **相等**或者**等价**的. 但这两个物体本身仍然是**不同的**, 它们各自有自己的**本体**.

在编程中, 一个对象的本体和它的内存地址是相关联的.

**NSObject** 使用 **isEqual:** 这个方法来测试和其他对象的相等性. 两个**NSObject** 如果指向了同一个内存地址, 那它们就被认为是相同的.

```objective-c
- (BOOL)isEqual:(id)obj {
  return obj == self;
}
```

在**Foundation**框架中, 下面这些**NSObject**的子类都有自己的相等性检查实现, 分别使用下面这些方法:

- 对下面这些类来说, 当需要对它们的两个实例进行比较时, 推荐使用这个高层方法而不是直接使用**isEqual:**

```objective-c
// NSAttributedString
- isEqualToAttributedString:

// NSData
- isEqualToData:

// NSDate
- isEqualToDate:

// NSDictionary
- isEqualToDictionary:

// NSHashTable
- isEqualToHashTable:

// NSIndexSet
- isEqualToIndexSet:

// NSNumber
- isEqualToNumber:

// NSOrderedSet
- isEqualToOrderedSet:

// NSSet
- isEqualToSet:

// NSString
- isEqualToString:

// NSTimeZone
- isEqualToTimeZone:

// NSValue
- isEqualToValue:
```

### 古怪的 NSString

```objective-c
NSString *a = @"Hello";
NSString *b = @"Hello";
BOOL wtf = (a == b); // YES
```

**明确一点, 比较 NSString 对象的正确方法是 -isEqualToString:**, 任何情况下都不要使用 `==`来对 NSString 进行比较.

上面使用 `==` 比较相等, 是因为**字符串驻留**技术:

- 它包一个`不可变字符串`对象的值拷贝给各个不同的指针.
- `NSString *a` 和 `*b` 都指向同样一个驻留字符串值`@"Hello"`.
- **注意所有这些针对的都是静态定义的不可变字符串**.

字符串驻留:

- 仅保存一份相同且不可变字符串的方法, 不同的值被存放在字符串的驻留池中.

### Tagged Pointers (标记指针)

```objective-c
NSTimeInterval timeInterval = 556035120;
NSDate *aDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
NSDate *bDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
BOOL valuesHaveSameIdentity = (aDate== bDate);	// YES
BOOL valuesAreEqual = [aDate isEqual:bDate];		// YES
```

- 另一种优化技术, 指针标记.
- Objective-C runtime, 在 64-bit 模式下运行时, 使用 64-bit 整数表示对象指针 , 通常这个整数值指向内存中存储对象的地址.
- 但作为一种优化, 一些小的值可以直接存储在指针本身中.

### Hashing

对象相等性最重要的应用之一就是确定集合成员关系. 为了让 `NSDictionary` 和 `NSSet` 保持这个速度, 子类实现自定义相等实现时需满足一下条件.

- 对象相等可交换性 .`[a isEqual:b] => [b isEqual:a]`
- 如果对象相等, 那么他们的哈希值也必须相等. `[a isEqual:b] => [a hash] == [b hash]`
- 但是, 反过来则不成立. 两个对象可以具有相同的哈希值, 但彼此不一定相等

**hash table 对比 Lists**

- `Lists(列表)` 按顺序存储元素. 如果要查看某个特定对象是否包含在列表中. 则必须依次检查列表中的每个元素, 直到找到要找到的对象或用光所有项为止. 因此, 执行查找所需的时间与列表中的元素数量呈线性关系 (`O(n)`).
  - `NSArray` 是 Foundation 中的主要列表类型.
- `Hash tables(哈希表)`采用了稍微不同的方法. 哈希表不是按顺序存储元素, 而是在内存中分配固定数量的位置, 并在插入每个对象时使用函数计算该范围内的位置.
  - 哈希函数是确定的, 一个好的哈希函数在一个相对均匀的分布中生成值, 而不需要太大的计算开销.
  - 理想情况下, 在哈希表中找到一个元素所需的时间是常数 (`O(1)`), 与存储的元素数量无关.
  - `NSSet` 和`NSDictionary` 是 Foundation 中实现哈希表的主要集合.
  - 如果两个不同的对象,产生相同的哈希值, 则会出现哈希碰撞. 底层的话用链表和红黑树处理. 当哈希表变得更加拥挤时, 碰撞的可能性就会增加, 这会导致花费更多的时间寻找空闲空间(这也是为什么要具有均匀分布的哈希函数的原因).

### 实现自定义 Equal 的最佳实践

如果你正在实现一个自定义类型, 并且想要它遵循值语义. 请执行以下操作:

- 实现一个新的  **isEqualTo`ClassName`:** 方法来测试值是否相等.
- 重写 `isEqual:` 方法, 开始检查是否为`nil`, 和对象的标识, 最后退回到上面一步
- 重写哈希方法, 使相同的对象产生相同的哈希值.

如下示例:

```objective-c
@interface Color : NSObject

@property (nonatomic, strong) NSNumber *red;
@property (nonatomic, strong) NSNumber *green;
@property (nonatomic, strong) NSNumber *blue;

@end
```

**实现 isEqualTo`ClassName:`**

```objective-c
- (BOOL)isEqualToColor:(Color *)color {
    return [self.red isEqualToNumber:color.red] &&
           [self.green isEqualToNumber:color.green] &&
           [self.blue isEqualToNumber:color.blue];
}
```

**重写 isEqualTo:**

```objective-c
- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[Color class]]) {
        return NO;
    }
    return [self isEqualToColor:(Color *)object];
}
```

**重写 hash**

关于自定义哈希实现的一个常见误解来自对结果的肯定:认为哈希值必须是不同的。尽管理想的哈希函数会产生所有不同的值，但这比要求的要困难得多——如果你还记得的话:

- 重写哈希方法，使相同的对象产生相同的哈希值。

 满足此需求的一个简单方法是对确定相等的属性的哈希值进行`XOR(异或)`运算。

```objective-c
- (NSUInteger)hash {
    return [self.red hash] ^ [self.green hash] ^ [self.blue hash];
}
```



