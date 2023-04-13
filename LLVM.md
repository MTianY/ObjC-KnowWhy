# LLVM

`LLVM` 项目是模块化、可重用的`编译器`以及`工具链`技术的集合.

### 传统的编译器架构

`Source Code (源代码)` -> `Frontend (编译器前段)` -> `Optimizer (优化器)` -> `Backend (编译器后端)` ->  `Machine Code(生成机器码)`

<img src="/Users/Maty/Library/Application Support/typora-user-images/image-20230413155322203.png" alt="image-20230413155322203" style="zoom:50%;" />

### Clang

- LLVM 项目的一个子项目
- 基于 LLVM 架构的 C/C++/Objective-C`编译器前端`

相比 GCC, Clang 具有如下优点:

- 编译速度快.
- 占用内存小.
  - Clang 生成的 AST 所占用的内存是 GCC 的五分之一左右
- 模块化设计
  - Clang 采用基于库的模块化设计, 易于 IDE 集成及其他用途的重用
- 诊断信息可读性强
  - 编译过程中,Clang 创建并保留了大量详细的元数据(metadata), 有利于调试和错误处理

### Clang 与 LLVM

LLVM 架构; 

- 前端 : Clang
  - 词法分析
  - 语法分析
  - 语义分析、生成中间代码
- 后端 : LLVM 后端
  - 优化器:
    - 代码优化
  - 后端:
    - 生成目标程序

### OC 源文件的编译过程

命令查看编译的过程:

```sh
$:clang -ccc-print-phases main.m

输出:
               +- 0: input, "main.m", objective-c							// 找到编译的文件 main.m
            +- 1: preprocessor, {0}, objective-c-cpp-output		// 预处理器
         +- 2: compiler, {1}, ir															// 编译器编译成中间代码
      +- 3: backend, {2}, assembler														// 交给后端生成目标文件
   +- 4: assembler, {3}, object																// 汇编其生成机器码
+- 5: linker, {4}, image																			// 链接
6: bind-arch, "x86_64", {5}, image														// 生成可执行文件
```

#### 查看 preprocessor (预处理) 的结果

```sh
$:clang -E main.m
```

- 预处理阶段, 会处理 `#`开头的代码, 如替换头文件、条件编译等等.

#### 词法分析

词法分析, 生成 Token

```sh
$:clang -fmodules -E -Xclang -dump-tokens main.m

如:
at '@'	 [StartOfLine]	Loc=<./YYRootViewController.h:13:1>
identifier 'end'		Loc=<./YYRootViewController.h:13:2>
at '@'	 [StartOfLine]	Loc=<./YYAppDelegate.h:12:1>
```

### 语法分析

生成语法树 - AST

```sh
$:clang -fmodules -fsyntax-only -Xclang -ast-dump main.m
```

#### LLVM IR

有三种表现形式, 但本质是等价的.

- `text`

  - 便于阅读的文本格式, 类似汇编语言, `扩展名.II`

  ```sh
  生成命令:
  $:clang -S -emit-llvm main.m
  ```

- `memory`

  - 内存格式

- `bitcode`

  - 二进制格式, 扩展名 `.bc`

  ```sh
  生成命令:
  $:clang -c -emit-llvm main.m
  ```

  