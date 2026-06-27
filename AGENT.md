# ChronoFocus 后续 Codex Agent 系统提示词

你是 ChronoFocus 项目的后续编程 Agent。请把本文当作项目级系统提示词、项目总结和规范化管理文档使用。每次开始工作前先阅读本文件、`README.md`、当前 git 状态和相关代码；每次完成工作后，必须同步更新测试规范和 `README.md` 的完成记录或验证说明。

## 项目目标

ChronoFocus 是一个 SwiftUI 番茄钟 App 原型，包含 iOS 与 macOS 两个版本。

- iOS 版：番茄钟、日程待办、Pro 统计、日历同步、本地通知、Live Activity、铃声/振动、暗色/亮色主题。
- macOS 版：状态栏应用，无 Dock 图标；菜单栏显示剩余时间；左键打开极简番茄钟；三点按钮打开竖向快捷面板；可展开详细窗口，管理计时、日程、统计、设置和 Pro 功能。
- 核心原则：共享业务逻辑，平台层分离。不要为 Mac 版重写一套核心数据或计时逻辑。

## 当前项目状态

最近 git 记录显示：

- `0867b40`：完成 macOS 版基础架构。新增 `ChronoFocusMac` target、状态栏入口、popover 小窗、详细窗口、Mac 通知、Mac 日历同步、Mac Pro 服务、快照测试和 README 说明。
- `94d0e59`：优化 Mac 小窗。三点按钮改为竖向快捷面板；进度条改为连续动态进度条；新增 Pro 铃声选择和 Mac 多音色提示音。

当前关键能力：

- `ChronoFocus`：iOS 主 App。
- `ChronoFocusLiveActivity`：iOS Live Activity 扩展。
- `ChronoFocusMac`：macOS 状态栏 App。
- `Shared`：跨 target 共享类型和扩展。
- `scripts/verify_project.sh`：项目结构、核心测试、Mac 快照渲染的主验证入口。

## 架构规范

### 共享层

优先复用以下核心代码：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Services/FocusStore.swift`
- `ChronoFocus/Services/TimerEngine.swift`
- `ChronoFocus/Services/TimerPlatformServices.swift`
- `Shared/SharedExtensions.swift`
- `Shared/PomodoroActivityAttributes.swift`

不要在 Mac 目标里复制核心模型、统计逻辑、计划生成逻辑或计时状态机。需要新增业务字段时，优先加到共享模型，并验证 iOS 与 macOS 两端兼容。

### 平台层

iOS 专属能力留在 `ChronoFocus/Services` 和 iOS Views：

- `NotificationService`
- `LiveActivityService`
- `CalendarSyncService`
- `PremiumAccessService`

macOS 专属能力留在 `ChronoFocusMac`：

- `ChronoFocusMac/App/ChronoFocusMacApp.swift`
- `ChronoFocusMac/App/MacStatusBarController.swift`
- `ChronoFocusMac/Services/*`
- `ChronoFocusMac/Views/*`

平台 API 必须隔离。不要让 macOS target 直接依赖 UIKit、ActivityKit UI 行为；不要让 iOS target 直接依赖 AppKit。

## UI 设计规范

使用 SwiftUI。不要引入第三方 UI 框架。

- Mac 小窗保持极简、紧凑、状态栏友好。
- 三点快捷面板只放常用操作：模式、常用时长、铃声、试听、日程、统计、设置。更复杂的操作放详细窗口。
- 详细窗口使用左侧导航和右侧功能页面，不要做营销式落地页。
- 控件要稳定、克制、信息密度适合生产力工具。
- 图标优先使用 SF Symbols / SwiftUI `Label`，按钮必须有可访问文本标签。
- 避免大面积单一色调；当前主色以青绿色为核心，但要配合蓝、紫、橙等状态色。
- 不要添加无意义装饰图形、渐变球、过度卡片嵌套。

Mac 快照渲染有特殊限制：原生 `Picker`、`Toggle`、`Slider`、`DatePicker`、`Stepper` 在 `ImageRenderer` 中可能渲染成黄色缺失占位。真实 App 可以继续用原生控件；快照路径使用 `macSnapshotRendering` 环境值切换到自绘静态控件。

## 功能规范

### 计时

`TimerEngine` 是唯一计时状态机。新增开始、暂停、恢复、跳过、自动开始逻辑时，必须修改并验证 `TimerEngine`，不要把计时状态分散到 View。

### 通知与铃声

通知抽象通过 `TimerNotificationServicing`。新增通知相关行为时，必须同时考虑：

- iOS `NotificationService`
- macOS `MacNotificationService`
- `TimerEngine` 调用点
- `scripts/test_mac_core.swift`
- `scripts/verify_project.sh`

Pro 铃声目前通过 `CompletionSound` 存在共享模型中，Mac 端可选择多音色并生成提示音；iOS 端保持兼容默认提示逻辑，除非明确要求扩展 iOS 铃声选择。

### Pro 功能

StoreKit 商品 ID：`com.example.ChronoFocus.pro.analytics`。

Pro 相关功能要有普通用户预览态、购买入口、恢复购买入口，以及已解锁态。Mac 与 iOS 的购买服务可以分平台实现，但商品 ID 和行为语义要一致。

### 日历同步

iOS 使用 iPhone 日历同步语义；macOS 使用 Mac 日历同步语义。同步后应进入 `FocusStore` 的待办系统，参与计划生成、统计和提醒。

## 编码规范

- 使用 SwiftUI，优先遵循现有文件风格。
- 不引入第三方依赖，除非用户明确要求。
- 不做无关重构。
- 不回滚用户或其他 Agent 的改动。
- 手写文件修改使用 `apply_patch`。
- 每个新增功能应有明确验证路径。
- 视图可以先保持现有私有子 View 风格；大规模新增时再拆文件，避免单文件过长失控。
- 新增共享模型字段时，要提供向后兼容的 `decodeIfPresent` 默认值。
- 不要把测试专用逻辑暴露为真实产品行为；测试/快照开关应通过环境值或初始化参数明确隔离。

## 测试规范

每次改动后至少运行：

```bash
bash scripts/verify_project.sh
```

如果涉及 macOS App、Mac UI、状态栏、小窗、详细窗口、通知、StoreKit、EventKit 或共享模型，还要运行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

如果涉及 iOS 主 App 或 Live Activity，还要尽量运行对应 iOS scheme 的 Xcode 构建；若当前环境无法运行模拟器，要在最终回复中明确说明原因。

### 快照测试要求

`scripts/render_mac_snapshots.swift` 当前会生成：

- `/tmp/chronofocus-mac-snapshots/mini-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-schedule.png`
- `/tmp/chronofocus-mac-snapshots/detail-analytics.png`
- `/tmp/chronofocus-mac-snapshots/detail-settings.png`

快照测试必须继续检查：

- 图片非空。
- 详情页右侧内容区有前景内容。
- 不出现黄色缺失控件占位。

新增 Mac 页面或重要状态时，应扩展快照脚本和 `verify_project.sh`，不能只靠人工观察。

## README 与文档更新要求

每次完成开发后必须检查是否需要更新：

- `README.md`：功能清单、打开方式、本地验证、已完成能力。
- `AGENT.md`：如果改变架构、测试命令、重要文件、项目规范或后续工作方式，必须更新本文。
- `scripts/verify_project.sh`：如果新增功能有可静态检查的标记、文件或快照，应加入验证。
- `scripts/test_mac_core.swift`：如果新增共享模型字段、核心计划/统计/持久化逻辑，应加入核心测试。
- `scripts/render_mac_snapshots.swift`：如果新增或明显改变 Mac UI，应覆盖快照。

不要只在最终回复里说“已完成”，而不更新 README 或测试规范。项目文档必须能让下一位 Agent 接上工作。

## 工作流程

1. 读取 `AGENT.md`、`README.md`、`git status --short`、相关 git log。
2. 用 `rg` 查找相关代码，不盲改。
3. 明确影响范围：iOS、macOS、共享模型、脚本、README。
4. 小步修改，优先保持现有架构。
5. 更新测试脚本或快照脚本。
6. 运行验证命令。
7. 检查关键快照或构建产物。
8. 更新 README 和 `AGENT.md` 中需要变更的部分。
9. 最终回复只汇报关键改动、验证结果和未完成风险。

## 常见验证噪声

当前环境运行 `xcodebuild` 时可能出现 CoreSimulator、FSEvents、缓存目录权限相关警告。这些通常是桌面沙盒或模拟器服务噪声。只要最终出现 `BUILD SUCCEEDED`，macOS target 构建可视为通过。若出现 Swift 编译错误、链接错误、签名错误或脚本失败，不得忽略。

## 后续优先级建议

1. 完善 Mac 小窗快捷面板的真实交互细节，例如快捷入口跳到详细窗口指定 tab。
2. 为 iOS 端同步支持 `CompletionSound` 的可选 UI，前提是用户明确需要。
3. 增强 iOS scheme 构建验证，避免只验证 Mac。
4. 为 StoreKit 和 EventKit 增加更明确的本地 mock 或配置说明。
5. 梳理长文件，把过长 Mac View 拆成更小的文件，但不要在功能开发中顺手大重构。

