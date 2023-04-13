# iOS 代码混淆

## 基本概念

### 加固

为了增加应用的安全性, 防止应用被破解、盗版、二次打包、注入、反编译等.

### 常见加固方式有

- 数据加密 
- 应用加壳
- 代码混淆 (类名、方法名、代码逻辑等)

### 代码混淆

iOS 可以通过`class-dump`、`Hopper`、`IDA`等获取`类名`、`方法名`、以及分析程序的执行逻辑.

- 拿到可执行文件
  - `-H` 获取头文件
  - `-o`后面跟上文件夹路径

```shell
$:class-dump -H -o headers 可执行文件
```

进行混淆, 加大别人分析难度.

#### iOS 的代码混淆方案

- 源码的混淆
  - 类名
  - 方法名
  - 协议名
  - ...
- LLVM 中间代码 IR 的混淆(容易产生 BUG)

#### 源码混淆 - 通过宏定义混淆方法名、类名

- 注意不能混淆系统方法
- 不要混淆`init`开头的方法
  - 因为对`self`的赋值操作, 必须在`init`开头的方法中, 如`self = [super init]`
- 属性主要 set 方法
- xib如果用到混淆内容, 手动修改
- 可以把混响的符号加上前缀
- 混淆过多可能会被上架拒绝

```objc
#define TYPerson xaxxa
#define run adav
...
```

第三方工具: `ios-class-guard`. [https://github.com/Polidea/ios-class-guard](https://github.com/Polidea/ios-class-guard)

- 基于 `class-dump`的扩展
- 用`class-dump`扫描出可执行文件中的类名、方法名、属性名等并做替换, 会更新`xib`和`storyboard`的名字等等.

#### 字符串加密

- 对字符串每个字符进行异或

```objc
// 比如字符串 @"fd45"
// 对每个字符异或后, 'f','d','4','5' 得到 97, 99, 51, 50.
char str[] = {97, 99, 51, 50, 0};
用的时候再从 str[] 中取出每个字符, 再次和 7 异或, 即可得到 @"fd45"
```



