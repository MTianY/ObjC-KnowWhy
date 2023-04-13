# iOS 签名机制

## 一. 对称密码

对称密码中, 加密、解密时使用的`同一个密钥`.

常见的对称密码算法有:

- DES (Data Encryption Standard)
- 3DES
- AES

### DES

- DES 是一种将 64bit 明文加密成 64bit 密文的对称密码算法, 密钥长度是 56bit.
- 规格上来说, 密钥长度 64bit, 但每隔 7bit 会设置一个用于错误检查的 bit, 因此密钥长度实际上是 56bit
- 由于 DES 每次只能加密 64bit 的数据, 遇到比较大的数据, 需要对 DES 加密进行迭代(反复加密)
- 目前已经可以在短时间内被破解, 所以不建议使用

加密:

- 密钥 (56bit)

- 明文(64bit) -> DES 加密 -> 密文(64bit)

解密:

- 密钥 (56bit)
- 密文(64bit) -> DES 解密 -> 明文(64bit)

### 3DES

- 将 DES 重复 3 次所得到的一种密码算法, 也叫所 3 重 DES
- 处理速度不高, 安全性逐渐暴露出来

### AES (Advanced Encryption Standard)

- 取代 DES 成为新标准的一种对称密码算法

### 对称密码 - 密钥配送问题

假设 Alice 将`使用对称密码加密过的消息`发给 Bob, 只有将密钥发送给 Bob, Bob 才能完成解密. 在发送密钥中, 可能会被 Eve 窃取密钥,  则 Eve 也能完成解密.

**解决办法**:

- 事先共享密钥
  - 比较麻烦, 不能远程操作
- 密钥分配中心
  - 密钥放到分配中心, Bob 自己去拿
  - 这个要保证分配中心是安全的
- 公用密码
  - 非对称加密, 相对安全

## 二. 非对称加密 - 公钥密码 (Public-key Cryptography)

密钥分为 `加密密钥`,`解密密钥`2 种. 它们不是同一个密钥.

公钥密码也称为`非对称密码`

在公钥密码中:

- 加密密钥, 一般是公开的, 因此该密钥称为公钥 (public key)
- 解密密钥, 消息接收者自己保管, 不能公开, 因此也称为私钥 (private key)
- 公钥和私钥一一对应, 不能单独生成. 一对公钥和密钥统称为密钥对 (key pair)
- 公钥加密的密文, 必须使用与该公钥对应的私钥才能解密.

明文 -> (公钥)加密 -> 密文 -> (私钥)解密 -> 明文

### 解决密钥配送问题

- 消息的接收者, 生成一对公钥、私钥
- 将公钥发给消息的发送者
- 消息的发送者使用公钥加密消息

### RSA

目前使用最广泛的非对称密码

## 三. 混合密码系统

对称密码的缺点:

- 不能很好的解决密钥配送问题

非对称密码缺点:

- 加密解密速度比较慢

混合密码系统, 将对称密码和公钥密码的优势相结合的方法.

- 解决公钥密码速度慢的问题
- 并通过公钥密码解决了对称密码的密钥配送问题

SSL/TLS 都运用了混合密码系统.

### 加密

消息 -> 混合密码系统加密 -> ①用公钥密码加密的会话密钥 /② 用对称密码加密的消息

**混合密码系统加密**做了什么?

- 第一步, 发送方获取接收方的`公钥`.
- 第二步, 发送方随机生成一个会话密钥 (对称加密), 用来 `加密`发送方消息.生成密文.
- 第三步, 发送方用接收方的`公钥`, 加密会话密钥, 生成密文.
- 最后将上面两步生成的加密结果, 一并发给消息接收者.

发送方, 用接收方的`公钥`, 共加密了 2 个(会话密钥及消息). 传给接收方.

### 解密

- 解密会话密钥
  - 接收方用私钥密码解密会话密钥
- 解密消息
  - 用解密出来的会话密钥, 因为是对称加密, 所以用它来解密消息.

## 四. 单向散列函数 (One-way hash function)

### 特点:

- 单向散列函数, 可以根据消息内容计算出散列值.
- 计算速度快, 呢个快速计算出散列值
- 消息不同, 散列值也不同.
- 具备单向性. (无法根据散列值去推算之前是什么消息)

#### 单向散列函数

又称消息摘要函数, 哈希函数.

常见的几种单向散列函数

- MD4, MD5
  - 产生`128bit`的散列值, 目前已经不安全
- SHA-1
  - `160bit`, 目前不安全
- SHA-2
  - SHA-256 `(256bit)`, SHA-384`(384bit)`,SHA-512`(512bit)`, 安全
- SHA-3
  - 全新标准

应用场景:

- 防止数据被篡改

## 五. 数字签名

#### 生成签名

- 消息`发送者`用自己的`私钥`生成签名

#### 验证签名

- 消息`接收者`完成, 通过`公钥`验证签名

### 数字签名的过程

发送者 Alice, 接收者 Bob.

- 发送者 Alice 用自己的`私钥`加密消息. 生成签名.
- 发送者 Alice 将自己的`明文消息`和`生成的签名`都发送给`接收者 Bob`.
- 接收方Bob 收到签名后,用`公钥`解密.
- 然后将解密后的明文与上面接收到的明文对比, 如果一致,则`签名验证成功`.

**存在的问题:**

- 发送的数据有点大

**改进**

- 发送方 Alice 生成公钥和私钥, 将`公钥`发送给接收方 Bob.
- 发送方 Alice, 用单向散列函数计算`消息`的散列值.
- 发送方 Alice 再用自己的`私钥`加密散列值. 生成签名
- 发送 Alice 将`明文消息`和`生成的签名`都发送给`接收者 Bob`.
- 接收方 Bob 收到后, 将`明文消息`用单向散列计算, 得到散列值
- 接收方 Bob 将`签名`用`公钥`解密, 得到散列值.
- 对比散列值, 一致则说明签名验证成功.

### 数字签名作用

- 确认消息的完整性
- 识别消息是否被篡改
- 防止消息发送人否认

### 数字签名无法解决的问题

要正确使用签名 , 前提是

- 用于验证签名的`公钥`必须属于真正的发送者.

如果遭遇中间人攻击, 那么

- 公钥将是伪造的
- 数字签名将失效

所以在验证签名之前, 首先得先验证公钥的合法性.

## 六. 证书 (Certificate)

密码学中叫**公钥证书 (Public-key Certificate, PKC)**.

- 里面有姓名、邮箱等个人信息, 以及此人的公钥
- 由认证机构(Certificate Authority, CA) 施加数字签名.

### 证书的注册和下载

- 用户 Bob (**公钥注册者**) 向认证机构`注册`公钥.
- 认证机构公钥注册成功后, 将会生成一个`证书`
  - 包含 Bob 的公钥
  - 数字签名等
- 用户 Alice(**公钥使用者**) 向认证机构`下载`证书.

## 七. iOS 签名机制

作用:

- 保证安装到用户手机上的 App 都是经过 Apple 官方允许的.

不管真机调试, 还是发布 App. 开发者都要经过一系列复杂的步骤:

- 生成 `CertificateSigningRequest.certSigningRequest` 文件
- 获得`ios_development.cer\ios_distribution.cer`证书文件
- 注册`device`, 添加`App ID`.
- 获得`*.mobileprovision` 文件.

目前真机调试, Xcode 已经自动做了上面的操作.

### iOS 签名机制 - 流程

前提条件:

- **Mac 设备**. 包含`Mac 公钥`、`Mac 私钥`.
- **Apple 后台**. 包含`Apple 私钥`
- **iOS 设备**. 包含`Apple 公钥`

iOS App 生成的 `ipa` 包中内容:

- 第一步签名(对应编译代码时), 对 App 的代码和资源等做签名操作. (签名只能用私钥做, 即 `Mac 私钥`). 放到`ipa`中
- 第二步签名,(对应证书助理请求证书 )用 `Mac 公钥`生成`证书`的操作.
  - 通过`Apple 私钥`, 将`Mac 公钥` 签名生成`证书`. (对应网站上传 Cer 证书的操作)
- 第三步将第二步生成的`证书`和`devices`、`app id`、`entitlements`等混合一起后, 通过`Apple 私钥`进行签名. 最终生产 `mobileprovision` 文件.放到`ipa`中.

手机安装 ipa 安装包, 验证签名合法操作:

- 用 `Apple 公钥` 验证`mobileprovision`文件中的`签名`(即上面第三步的签名)
- 用`Apple 公钥`验证`mobileprovision 文件`中的`证书`中的`签名`(即上面第二步的签名)
- 用`Mac 公钥` 验证`App 代码文件等`中的签名(即上面第一步的签名)

### 重签名

下载一个 App 的 ipa 包之后, 如果改变其包内的代码的话, 那么就会破坏其签名信息. 正常是不能再次安装这个包了.

签名信息如果破坏了, 可以**重签名**从而进行安装.

命令行命令: **codesign**.

```shell
$:codesign

输出:
Usage: codesign -s identity [-fv*] [-o flags] [-r reqs] [-i ident] path ... # sign
       codesign -v [-v*] [-R=<req string>|-R <req file path>] path|[+]pid ... # verify
       codesign -d [options] path ... # display contents
       codesign -h pid ... # display hosting paths
```

对`.app`包进行签名命令:

```shell
$:codesign -f -s 证书ID --entitlements entitlement.plist xxx.app
```

查看可用的证书命令:

```shell
$:security find-identity -v -p codesigning

输出:
1) 76ABD4DCBCF3B2345E86C688EA3F42D5DB312221 "Apple Development: mtystar@qq.com (3BL2P62LQE)"
     1 valid identities found
```

对`.app`内部的动态库、AppExtension 等进行签名命令:

```shell
$:codesign -f -s 证书ID xxx.dylib
```

从`embedded.mobileprovision`文件中提取出`entitlements.plist`权限文件命令:

```shell
// 将 provision 文件生成 plist 文件
$:security cms -D -i embedded.mobileprovision > temp.plist

// 将 temp.plist 文件生成 entitlements.plist 文件(用来重签名用的文件)
$:/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' temp.plist > entitlements.plist
```

修改原`ipa`包内容, 重签步骤总结:

- 获取`embedded.mobileprovision`文件.将该文件放到`ipa`包改的`.app`文件中
- 用上面的命令, 从`embedded.mobileprovision`文件中取出`entitlements.plist`权限文件.
- 查看证书 ID , 用上面的命令查看
- 重签, 最终命令如下:

```shell
$:codesign -f -s 证书ID --entitlements entitlements.plist xxx.app

重签成功会输出如下信息:
xxx.app: replacing existing signature
```

重签名工具: `iOS App Signer`[https://github.com/DanTheMan827/ios-app-signer](https://github.com/DanTheMan827/ios-app-signer), 可以对`.app`重签名打包成`.ipa`. 需要在`.app`包中提供对应的`embedded.mobileprovision`文件.

#### 动态库注入

可以使用 `insert_dylib` 库将动态库注入到`Mach-O`文件中. 工具下载地址: [https://github.com/Tyilo/insert_dylib](https://github.com/Tyilo/insert_dylib)

用法:

- insert_dylib 动态库加载路径 Mach-O 文件.
- 有 2 个常用的参数选项
  - `--weak`, 即使动态库找不到也不会报错
  - `--all-yes`, 后面所有的选择都为`yes`
- `insert_dylib`本质是往`Mach-O`文件的`Load Commands` 中添加了一个 `LC_LOAD_DYLIB` 或 `LC_LOAD_WEAK_DYLIB`
- 可以通过`otool`查看`Mach-O`的动态库依赖信息
  - `otool -L Mach-O文件`