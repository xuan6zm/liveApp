# liveApp
个人搭建的框架，包括使用moya网络请求，snapkit约束，适合项目初期调试

# 2026 Swift6 项目统一编码规范
融合 Google + Airbnb 规范，适配 iOS 音视频/直播商业项目，可直接复制使用

## 前言
### 核心原则（优先级从高到低）
1. **安全优先**：并发线程安全、杜绝内存泄漏、循环引用
2. **清晰可读**：代码自解释，复杂逻辑补充注释
3. **简洁统一**：全项目格式、命名、分层写法保持一致
4. **自动化落地**：配套 `swift-format` + SwiftLint 自动校验格式化
5. **向前兼容**：适配 Swift6 严格并发模式，最低支持 iOS 15+

### 配套工具
- 代码格式化：`swiftlang/swift-format`
- 静态代码检查：`realm/SwiftLint`
- 项目配置文件：`.swiftformat` / `.swiftlint.yml` 统一提交仓库

---

## 一、基础排版格式规范
### 1. 缩进与换行
- 缩进：**4 个空格**，禁止使用 Tab
- 单行最大宽度：120 字符，超出主动换行拆分
- 空行规则
  - 不同逻辑代码块之间空 1 行
  - 类、结构体、Actor、扩展、函数之间空 1 行
  - 文件末尾保留 1 个空行
- 禁止行尾多余空格、连续多行空行

### 2. 大括号统一规则
左大括号 `{` 紧跟代码尾部，不换行；右大括号 `}` 单独一行
```swift
// 正确示例
func loadStream() async throws {
    guard let url = streamUrl else { throw StreamError.emptyUrl }
}

// 错误示例（禁止）
func loadStream() async throws
{
}
```



### 3. 符号空格规范

#### 规范要求

- 逗号 `,` 后必须保留一个空格。
- 二元运算符（如 `+`、`-`、`*`、`/`、`=`、`==`、`>=`、`&&` 等）两侧必须添加空格。
- 泛型声明、类型标识两侧禁止出现多余空格。
- 冒号 `:` 遵循 Swift 官方风格：冒号前无空格，冒号后保留一个空格。

#### ✅ 正确示例

```swift
let list = [1, 2, 3]

let valid = width + height >= 1080

let model: User<SendableModel>

let dictionary: [String: Int] = [:]

let isAvailable = isLogin && hasPermission
```

#### ❌ 错误示例（禁止）

```swift
let list = [1,2,3]

let valid = width+height>=1080

let model: User < SendableModel >

let dictionary : [String : Int] = [:]

let isAvailable = isLogin&&hasPermission
```
### 4. 尾随闭包使用规范

#### 单闭包参数强制使用尾随闭包写法，多闭包参数仅最后一个允许尾随。
```swift
// 正确示例
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0
} completion: { _ in
    self.removeFromSuperview()
}

Task { @Sendable in
    await fetchStreamData()
}

// 错误示例（禁止）
UIView.animate(withDuration: 0.3, animations: {
    self.view.alpha = 0
})
```
## 二、全局统一命名规范

### 1. 大小写对照表

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| Class / Struct / Actor / Enum | PascalCase 大驼峰 | LivePlayerActor、StreamInfo |
| 函数 / 变量 / 属性 / 参数 | camelCase 小驼峰 | streamUrl、startPlay() |
| 静态只读常量 | 小驼峰，不使用全大写 | defaultBufferDuration |
| 枚举 case | 小驼峰 | case streamInterrupt |
| 编译宏标记 | 全大写下划线 | `#if DEBUG` |

### 2. 命名语义约束

禁止无意义简写；布尔变量统一 is/has/can/should 前缀；异步函数动词开头；禁止 Model 冗余后缀。

```swift
// 正确示例
var isPlaying: Bool
func fetchStreamInfo()
struct StreamInfo

// 错误示例（禁止）
var play: Bool
func getInfo()
struct StreamInfoModel
```

### 3. 协议命名规则

能力协议后缀使用 able/ing；业务代理协议统一 Delegate 后缀。

```swift
// 正确示例
protocol Playable {
    func play() async throws
}

protocol StreamPlayDelegate: AnyObject {}

// 错误示例（禁止）
protocol PlayProtocol {}

protocol StreamDelegateInterface {}
```

## 三、类型与访问控制规范

### 1. 类型选择优先级

优先使用 Struct 存储纯数据；UI、工具类统一添加 final；跨线程共享状态必须使用 Actor 隔离；禁止全局可变静态变量。

```swift
// 正确示例
struct StreamInfo: Sendable {}

final class LiveViewModel {}

actor StreamPlayerActor {}

// 错误示例（禁止）
class BaseManager {}

static var globalPlayer: IJKPlayerWrapper!
```

### 2. 访问控制层级

权限优先级：private > fileprivate > internal > public > open；UI 相关类强制 @MainActor，对外接口仅使用 public，禁用 open。

```swift
// 正确示例
@MainActor
final class LiveViewController {
    private var streamUrl: String?
    fileprivate func reloadUI() {}
    public func startPlay() async {}
}

// 错误示例（禁止）
open class LiveViewController {
    var streamUrl: String?
    internal func reloadUI() {}
}
```

### 3. 数据模型强制规范（音视频项目专用）

所有网络、流数据模型必须遵循 Sendable，所有存储属性统一使用 let 常量。

```swift
// 正确示例
struct StreamInfo: Sendable {
    let streamId: String
    let url: String
    let bufferTime: Double
}

// 错误示例（禁止）
struct StreamInfo {
    var streamId: String
    var url: String
}
```
## 四、Swift6 并发强制规范（2026 核心规则）

### 1. @MainActor 主线程隔离

所有 UI、ViewController、ViewModel 必须标记 `@MainActor`，禁止后台 Task 直接操作 UI 状态。

```swift
// 正确示例
@MainActor
final class LiveViewModel {
    var isPlaying: Bool = false

    func play() async {
        await playerActor.start()
        isPlaying = true
    }
}

// 错误示例（禁止）
final class LiveViewModel {
    var isPlaying: Bool = false

    func play() async {
        Task {
            isPlaying = true
        }
    }
}
```
### 2. Sendable 线程安全约束

跨线程传递模型必须实现 Sendable；Class 默认不满足 Sendable，优先替换 Struct；谨慎使用 `@unchecked Sendable` 并添加注释说明安全逻辑。

### 3. Actor 状态隔离（播放器强制要求）

多路播放器、全局缓存、会话状态全部封装 Actor 串行隔离，淘汰 GCD 信号量做状态同步。

```swift
// 正确示例
actor StreamPlayerActor {
    private var players: [String: IJKPlayerWrapper] = [:]

    func getPlayer(id: String) -> IJKPlayerWrapper? {
        players[id]
    }
}

// 错误示例（禁止）
class PlayerManager {
    static var shared = PlayerManager()

    var players: [String: IJKPlayerWrapper] = [:]
}
```

### 4. async/await 统一异步写法

新项目完全废弃 completion 回调，统一使用 `async throws`；页面生命周期 Task 必须持有并在 `deinit` 取消。

```swift
// 正确示例
@MainActor
final class LiveView {
    private var loadTask: Task<Void, Never>?

    func loadStream() {
        loadTask = Task { @Sendable [weak self] in
            guard let self else { return }

            let info = try await self.streamActor.fetchInfo()
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// 错误示例（禁止）
func loadStream(completion: @escaping (StreamInfo?, Error?) -> Void) {}
```

### 5. 禁止危险并发写法

- 禁止全局可变静态变量
- 禁止非隔离 Class 跨线程传递
- 禁止 `@Sendable` 闭包捕获可变局部变量
- 同一业务逻辑禁止混用 GCD 回调与 `async/await`

## 五、函数、条件、可选值规范

### 1. if / guard 选择规则

优先使用 guard 提前返回，减少多层 if 嵌套。

```swift
// 推荐写法
func play() throws {
    guard let url = stream.url else { throw StreamError.invalidUrl }
    guard !isPlaying else { return }
}

// 不推荐写法（禁止）
func play() throws {
    if let url = stream.url {
        if !isPlaying {
            // 深层嵌套逻辑
        }
    }
}
```

### 2. 可选值处理

优先 guard let / if let 安全解包；禁止无注释强制解包 `!`；UI 组件避免隐式解包 `UIView!`。

```swift
// 正确示例
guard let url = streamUrl else { return }

lazy var playerView: PlayerView

// 错误示例（禁止）
let url = streamUrl!

var playerView: PlayerView!
```

### 3. 函数定义规范

返回 `Void` 省略 `-> Void`；异步函数必须显式标记 `async throws`；参数过多使用显式参数标签。

```swift
// 正确示例
func loadStream(url: String, bufferDuration: Double) async throws -> StreamInfo {}

// 错误示例（禁止）
func loadStream(url: String) -> Void {}

func loadStream(url: String) throws {}
```

### 4. 闭包防循环引用（强制）

所有 Task、闭包捕获 `self` 必须添加 `[weak self]`，内部第一行判空 `self`。

```swift
// 正确示例
Task { @Sendable [weak self] in
    guard let self else { return }

    await self.player.play()
}

// 错误示例（禁止）
Task {
    await self.player.play()
}
```

## 六、UIKit / MVVM 分层业务规范

### 1. 分层职责严格划分

- **View（UIView / ViewController）**：仅布局、渲染、转发点击，无业务逻辑。
- **ViewModel（@MainActor）**：管理 UI 状态、数据转换、调用底层 Actor 服务。
- **Actor / Manager**：播放器、网络、缓存、全局状态隔离层。
- **Model（Struct Sendable）**：纯数据结构体，无任何业务方法。
- **Network / Service**：异步网络请求，返回 Sendable 数据模型。

### 2. ViewController 约束

VC 禁止直接持有播放器实例，统一交由 PlayerActor 管理；页面销毁主动取消 Task、释放播放器资源。

### 3. Combine 数据流规范

数据流统一写在 ViewModel 内部；订阅统一存入 `private var cancellables = Set<AnyCancellable>()`，`deinit` 自动销毁。

```swift
// 正确示例
@MainActor
final class LiveViewModel {
    private var cancellables = Set<AnyCancellable>()

    func bindStream() {
        streamActor.$status
            .sink { [weak self] status in
                guard let self else { return }

                self.updateUI(status)
            }
            .store(in: &cancellables)
    }
}
```
## 七、注释规范

### 1. 注释分层规则

对外暴露 `public` 函数使用文档注释 `///`；复杂并发、播放器底层逻辑添加单行注释；废弃代码直接删除，禁止大段注释留存；使用 `// MARK: -` 分组名拆分代码块。

```swift
/// 加载直播流
/// - Parameter url: 直播流地址
/// - Throws: 流地址为空、缓冲异常错误
func loadStream(url: String) async throws {}

// MARK: - Player Control

// MARK: - Async Stream Logic
```

## 八、常量、资源与宏规范

### 1. 常量管理规则

颜色、尺寸、播放默认参数统一放入 `AppConstant.swift`，使用 `struct` 静态 `let` 管理；禁止业务代码散落硬编码字符串、地址；图片资源使用枚举封装。

```swift
// 正确示例
struct AppConstant {
    static let defaultBufferTime: Double = 2.0
}

// 错误示例（禁止）
let buffer = 2.0

player.load(url: "rtmp://xxx.com/live")
```

### 2. 调试宏规范

调试代码全部包裹 `#if DEBUG`，生产环境自动移除。

```swift
#if DEBUG
print("播放日志：\(streamUrl)")
#endif
```

## 九、音视频项目专属内存 & 性能规范

### 1. 播放器资源释放规范

播放器实例使用完毕必须执行 `shutdown`、置空，防止黑屏与内存泄漏；Actor 内部限制多路播放最大并发数量。

```swift
// 正确示例
func destroyPlayer() async {
    await playerActor.shutdownAll()
    self.player = nil
}

// 错误示例（禁止）
func destroyPlayer() {
    self.player = nil
}
```

### 2. 主线程限制规范

解码、文件读写、大数据遍历禁止在主线程执行；循环解码逻辑内判断 `Task.isCancelled` 及时释放资源。

## 十、文件与目录结构规范

### 1. 文件拆分规则

一个文件仅存放一个顶级类型；扩展单独拆分文件 `LiveViewModel+Player.swift`。

### 2. 播放器模块标准目录

```text
MediaPlayer
├── Actor       // 播放器隔离Actor
├── Model       // Sendable数据模型
├── Wrapper     // OC播放器桥接封装层
├── View        // 播放器UI视图
└── Constant    // 播放默认参数常量
```

### 3. 单元测试规范

测试文件与业务文件一一对应：`XXXTests.swift`

## 十一、SwiftLint 强制校验规则

代码提交必须通过以下规则校验，违规禁止合并分支。

- `force_unwrapping`：禁止 `!` 强制解包
- `trailing_whitespace`：禁止行尾空格
- `vertical_whitespace`：禁止多余空行
- `weak_delegate`：Delegate 必须 `weak` 修饰
- `async_without_await`：`async` 函数内部必须使用 `await`
- `unchecked_sendable`：限制滥用 `@unchecked Sendable`
- `global_variables`：禁止全局可变 `var`

## 十二、落地提交流程

- 提交代码前执行 `swift format` 自动格式化全部代码。
- 本地运行 SwiftLint，修复所有 Error / Warning。
- CI 流水线自动执行格式 + 规范校验，校验不通过禁止合并。
- 新项目严格遵守本规范；老项目增量改造，所有新增代码必须符合标准。

## 使用说明

1. 复制全部内容，保存为项目根目录 `SWIFT_CODE_STYLE_GUIDE.md`。
2. 配套 `.swiftformat` / `.swiftlint.yml` 配置文件同步提交仓库。
3. 团队开发前必读，以此文档为项目唯一编码标准。
4. 随 Swift 官方大版本迭代更新并发、宏、语法相关规则。

