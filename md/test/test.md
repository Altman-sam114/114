# 测试规范

本文指导 Agent B 和 Agent C 为 ChronoFocus 选择测试层级。每次实现前先读本文件，默认从本地轻量检查开始，并通过 `origin/main` 上的 GitHub Actions 做重验证。

## 默认验证策略

- 默认路径：本地轻量检查 -> commit 到 `main` -> `git push origin main` -> GitHub Actions 上传未加密 CI 结果包 -> Agent C 下载并复判。
- 只有人工明确要求“本机测试”“本地 build”“本地 xcodebuild”“本地跑探针”等，才把完整本机 Xcode build 作为默认路径。
- 文档-only 修改可本地跑 `git diff --check` 和必要的 YAML/plist 解析；业务代码、工程文件、脚本或平台能力改动完成后，默认依赖云端重验证给出最终结论。
- 云端失败时，Agent B 根据结果包里的 failure summary、JUnit、日志和 manifest 修复，并在 `main` 上追加修复 commit 后重新 push。
- 云端环境缺依赖时，最终回复必须说明没跑哪个测试、缺什么依赖、是否影响验收、需要人工提供什么。

## Agent X 循环验证规则

Agent X 只负责主控调度，不改变每轮验证责任。每一个由 Agent X 拆出的轮次仍按 Agent A -> Agent B -> Agent C 闭环执行：

- Agent A 提示词必须写清本轮本地验证、GitHub Actions、artifact 和 Agent C 复判要求。
- Agent B 必须按本文件选择本地轻量检查；实现轮次默认至少有本地轻量检查结果、commit 和 `origin/main` push。
- GitHub Actions 必须为最新 `origin/main` commit 生成未加密 artifact。
- Agent C 必须下载并核对最新 run 对应 artifact，检查 manifest、JUnit 或测试摘要、failure summary、主日志、`.xcresult` 和项目专属产物。
- Agent X 不得跳过 Agent C artifact 验收，不得用本地输出、旧 run 或旧 artifact 代替最新云端结论。
- 如果 Agent C 验收失败，Agent X 只能选择退回 Agent B 修复、暂停等待人工确认或停止；不得继续下一轮并伪装成功。
- Agent X 宣布总目标完成前，最后一轮必须已有 Agent C 对最新 `origin/main` artifact 的通过结论。

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

云端 iOS generic 构建命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$RUNNER_TEMP/ChronoFocusIOSDerivedData" \
  -resultBundlePath "$PWD/ci-results/ChronoFocus-iOS.xcresult" \
  CODE_SIGNING_ALLOWED=NO build
```

主结构验证命令：

```bash
bash scripts/verify_project.sh
```

文档和补丁格式检查：

```bash
git diff --check
```

GitHub Actions workflow 语法轻量检查：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

Agent C 下载结果包前必须完成 GitHub CLI 登录：

```bash
gh auth login
```

Agent C 结果包缓存默认目录：

```bash
/private/tmp/chronofocus-c-review-<run_id>/
```

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、artifact index、JUnit 或测试摘要、关键日志、失败摘要、必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/chronofocus-c-review-<run_id>/`。
- 下载后应检查目录大小：

```bash
du -sh /private/tmp/chronofocus-c-review-<run_id>/
```

- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。
- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。

## 测试分层

### 1. Probe / Fast

最快发现文档、补丁、workflow、核心脚本或局部 Swift 逻辑断点。

触发条件：

- 文档-only 修改。
- GitHub Actions workflow 修改。
- 小范围脚本修改。
- 修改共享模型、`FocusStore` 或计划/统计逻辑，需要先跑核心 Swift 脚本。

命令：

```bash
git diff --check
```

修改 `.github/workflows/ci-results.yml` 时再运行：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

共享模型或核心数据逻辑改动时再运行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
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

- `scripts/test_mac_core.swift` 应输出 `Mac core tests passed.`，并覆盖分类清洗、默认分类顺序、筛选排序和 fallback 元数据。
- `git diff --check` 不应输出错误。
- workflow YAML 解析应输出 `yaml ok`。

### 2. Smoke

验证主要集成路径，适合大多数 Swift、脚本和 Mac UI 改动。默认由云端 `ci-results.yml` 执行；本机只在人工要求或定位问题时运行。

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
- 检查必需文件、工程引用、三个 shared schemes 语法。
- 检查 Live Activity、本地通知、Pro、日历同步、自动计划、Mac 状态栏等实现标记。
- 检查分类预设、日程页和计时页分类筛选、新建预填、筛选摘要、筛选优先级、44pt iOS 分类点击区域、Mac 小窗直达详情入口、Mac 各详情页快照安全静态控件和 CI iOS/错误摘录/artifact index 结果包实现标记。
- 编译并运行 Mac core tests。
- 渲染 Mac 快照到 `/tmp/chronofocus-mac-snapshots/`，并生成 `manifest.json` 记录 5 张快照的文件名、尺寸和字节数。
- 最终输出 `Project structure verified.`。

### 3. Stage Regression

覆盖当前阶段核心模块，适合 macOS 目标、跨平台共享逻辑或平台服务改动。默认由云端 `ci-results.yml` 执行 Mac build 并上传 `.xcresult`；本机只在人工要求或定位问题时运行。

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

## 云端重验证

默认 workflow：

```bash
.github/workflows/ci-results.yml
```

触发条件：

- push 到 `main`。
- 手动 `workflow_dispatch`。

云端固定执行：

- `git diff --check` 对当前提交 diff 做空白检查。
- `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`。
- `bash scripts/verify_project.sh`，生成 Mac core tests 与 Mac UI snapshots。
- `xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug -destination 'generic/platform=macOS' ... build`，生成 `xcodebuild.log` 和 `.xcresult`。
- `xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug -destination 'generic/platform=iOS' ... build`，生成 `ios-xcodebuild.log` 和 `ChronoFocus-iOS.xcresult`。

结果包最低内容：

- `ci-artifact-manifest.json`：记录版本、branch、commitSha、run id、run attempt、workflow、Mac/iOS scheme、Mac/iOS destination、日志路径、结果路径、artifact index 路径和各阶段 outcome。
- `ci-artifact-index.json`：记录关键 artifact 文件/目录是否存在、类型、文件字节数、目录递归字节数和文件数量。
- `ci-failure-summary.md`：记录通过/失败摘要和日志入口；存在失败阶段时追加有限 `Failure Excerpts` 错误摘录。
- `junit.xml`：Agent C 可读的阶段摘要。
- `xcodebuild.log`：Mac build 主日志。
- `ios-xcodebuild.log`：iOS `ChronoFocus` scheme generic build 主日志。
- `verify_project.log`：项目专属验证日志。
- `ChronoFocusMac.xcresult`：Mac build 原生结果包。
- `ChronoFocus-iOS.xcresult`：iOS build 原生结果包。
- `project-reports/mac-snapshots/`：Mac 快照脚本产物副本。
- `project-reports/mac-snapshots/manifest.json`：Mac 快照清单，记录 5 张快照的文件名、像素尺寸、字节数和生成时间。

Agent C 验收时必须核对：

- artifact 来自 `origin/main` 最新 commit。
- manifest 中 `branch` 为 `main`。
- manifest 中 `commitSha` 与 `origin/main` 最新 SHA 完全一致。
- manifest 中 `runId` 和 `runAttempt` 与下载的 GitHub Actions run 一致。
- `staticChecksOutcome`、`projectVerificationOutcome`、`buildOutcome`、`macBuildOutcome`、`iosBuildOutcome` 均为 `success`。
- artifact index、failure summary、JUnit、主日志和项目专属产物存在且不是旧 checkout 里的遗留文件。
- `ci-artifact-index.json` 必须覆盖 manifest、summary、JUnit、主日志、Mac/iOS `.xcresult`、Mac 快照目录、快照 manifest 和 5 张快照；required 条目必须存在，文件字节数或目录递归字节数必须为正。
- `junit.xml` 必须包含 `staticChecks`、`projectVerification`、`macBuild`、`iosBuild` 四个 testcase。
- `ci-failure-summary.md` 和 GitHub Step Summary 必须列出 iOS build 状态、`ios-xcodebuild.log` 和 `ChronoFocus-iOS.xcresult`；若任一阶段失败，必须包含 `Failure Excerpts` 并按阶段摘录关键错误行。
- Mac 快照 manifest 必须包含 `mini-timer.png`、`detail-timer.png`、`detail-schedule.png`、`detail-analytics.png`、`detail-settings.png` 五个条目，且每项 `width`、`height`、`byteCount` 均大于 0。
- workflow 的 Final CI status 必须把 iOS build outcome 纳入失败判定。

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
- 云端固定使用 `generic/platform=iOS` 构建 `ChronoFocus` scheme，并上传 `ios-xcodebuild.log` 与 `ChronoFocus-iOS.xcresult`。
- 本机 iOS 构建仍可根据当前机器 destination 状态选择可用模拟器；若当前环境没有可用模拟器或 Xcode 服务异常，最终回复必须说明未跑 iOS 构建的原因。

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
- 默认从最小本地轻量检查开始，根据改动范围交给云端重验证扩大覆盖。
- 不得伪造测试结果，不得把“已验证”当作命令结果。
- 文档-only 修改可只跑 `git diff --check`，但必须说明未跑完整业务测试的原因。
- 修改共享模型、计时状态机、计划生成、统计、通知、Pro 或日历同步时，不得只跑文档检查。
- 测试脚本失败时，先判断是项目问题还是环境问题；Swift 编译、链接、签名、脚本断言失败不得忽略。
- 不得把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
