# 测试规范

本文指导 Agent B 和 Agent C 为 ChronoFocus 选择测试层级。每次实现前先读本文件，默认从最小可证明测试开始，并按改动范围扩大。

## 固定前缀 / 环境要求

当前项目是 Xcode SwiftUI 工程，默认机器可能将 `xcode-select` 指向 Command Line Tools。运行 Xcode 构建时优先使用：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Mac 版构建命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

主结构验证命令：

```bash
bash scripts/verify_project.sh
```

文档和补丁格式检查：

```bash
git diff --check
```

## 测试分层

### 1. Probe / Fast

最快发现文档、补丁、核心脚本或局部 Swift 逻辑断点。

触发条件：

- 文档-only 修改。
- 小范围脚本修改。
- 修改共享模型、`FocusStore` 或计划/统计逻辑，需要先跑核心 Swift 脚本。

命令：

```bash
git diff --check
```

共享模型或核心数据逻辑改动时再运行：

```bash
xcrun --sdk macosx swiftc \
  -module-cache-path /tmp/chrono_focus_mac_core_module_cache \
  ChronoFocus/Models/AppModels.swift \
  ChronoFocus/Services/FocusStore.swift \
  Shared/SharedExtensions.swift \
  scripts/test_mac_core.swift \
  -o /tmp/chrono_focus_mac_core_tests
/tmp/chrono_focus_mac_core_tests
```

当前基线：

- `scripts/test_mac_core.swift` 应输出 `Mac core tests passed.`。
- `git diff --check` 不应输出错误。

### 2. Smoke

验证主要集成路径，适合大多数 Swift、脚本和 Mac UI 改动。

触发条件：

- 修改 `ChronoFocus.xcodeproj`、plist、entitlements、assets。
- 修改 `TimerEngine`、`TimerPlatformServices`、通知、StoreKit、EventKit。
- 修改 Mac 小窗、详细窗口、快照安全控件。
- 修改验证脚本或快照脚本。

命令：

```bash
bash scripts/verify_project.sh
```

当前基线：

- 检查项目和 plist 语法。
- 检查必需文件、工程引用、shared schemes。
- 检查 Live Activity、本地通知、Pro、日历同步、自动计划、Mac 状态栏等实现标记。
- 编译并运行 Mac core tests。
- 渲染 Mac 快照到 `/tmp/chronofocus-mac-snapshots/`。
- 最终输出 `Project structure verified.`。

### 3. Stage Regression

覆盖当前阶段核心模块，适合 macOS 目标、跨平台共享逻辑或平台服务改动。

触发条件：

- 修改 `ChronoFocusMac/App/*`、`ChronoFocusMac/Services/*`、`ChronoFocusMac/Views/*`。
- 修改共享模型导致 iOS/macOS 都受影响。
- 修改状态栏、popover、详细窗口、通知、Pro、日历同步。
- Smoke 通过但仍需要确认 target 可构建。

命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

当前基线：

- 目标结果是 `BUILD SUCCEEDED`。
- 当前环境可能出现 CoreSimulator、FSEvents、缓存权限相关警告；只要没有 Swift 编译、链接、签名或脚本错误，且最终 `BUILD SUCCEEDED`，Mac target 视为通过。

### 4. Full

全量验证 iOS 主 App、Live Activity 扩展和 Mac App。

触发条件：

- 修改 iOS App 入口、iOS Views、Live Activity、ActivityKit 数据结构、iOS 通知或权限。
- 修改工程结构、target、scheme、签名、entitlements。
- 发布前、重要里程碑或 Agent C 验收要求。

命令：

```bash
bash scripts/verify_project.sh
```

Mac 构建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

iOS 构建需按当前机器可用模拟器选择目的地。可先查看：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -showdestinations
```

然后使用可用 destination 构建 `ChronoFocus` scheme。若当前环境没有可用模拟器或 Xcode 服务异常，最终回复必须说明未跑 iOS 构建的原因。

当前基线：

- Mac 侧已有明确脚本和构建基线。
- iOS 侧需要根据本机 destination 状态补充稳定命令。

## 静态检查

固定可用：

```bash
git diff --check
```

工程结构和实现标记：

```bash
bash scripts/verify_project.sh
```

plist / JSON / scheme 检查已包含在 `scripts/verify_project.sh` 中：

- `plutil -lint`
- `python3 -m json.tool`
- XML parse 检查 shared schemes。

## 快照测试要求

`scripts/render_mac_snapshots.swift` 当前生成：

- `/tmp/chronofocus-mac-snapshots/mini-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-schedule.png`
- `/tmp/chronofocus-mac-snapshots/detail-analytics.png`
- `/tmp/chronofocus-mac-snapshots/detail-settings.png`

快照测试必须继续覆盖：

- 图片非空。
- 详情页右侧内容区有前景内容。
- 不出现黄色缺失控件占位。

新增 Mac 页面、重要状态或快照安全控件时，必须同步扩展 `scripts/render_mac_snapshots.swift` 和 `scripts/verify_project.sh`。

## 规则

- 每次实现前先读本文件。
- 默认从最小测试开始，根据改动范围扩大测试。
- 不得伪造测试结果，不得把“已验证”当作命令结果。
- 文档-only 修改可只跑 `git diff --check`，但必须说明未跑完整业务测试的原因。
- 修改共享模型、计时状态机、计划生成、统计、通知、Pro 或日历同步时，不得只跑文档检查。
- 测试脚本失败时，先判断是项目问题还是环境问题；Swift 编译、链接、签名、脚本断言失败不得忽略。
