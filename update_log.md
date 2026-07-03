# 项目版本更新记录

本文记录 ChronoFocus 的正式版本、重要维护事项、关键决策和遗留问题。它不是流水账；只有影响项目行为、架构、测试、文档体系或后续协作方式的事项才写入。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新产品版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。
- 日期使用本地日期，格式为 `YYYY-MM-DD`。

## 当前状态

- iOS 主 App 已具备番茄钟、日程待办、自动计划、统计分析、Pro 内购、系统日历同步、本地通知、Live Activity、铃声/振动、亮暗主题。
- macOS 版已作为状态栏 App 存在，复用共享模型、`FocusStore` 和 `TimerEngine`，提供菜单栏剩余时间、小窗、详细窗口、Mac 通知、Mac 日历同步、Mac Pro 服务和 Mac 快照测试。
- 当前本地项目专属验证入口是 `bash scripts/verify_project.sh`，会检查项目结构、关键实现标记、分类筛选/预填/排序标记、Mac 核心测试和 Mac UI 快照。
- 当前默认协作体系要求后续按 Agent A/B/C 云端闭环迭代：Agent A 产出版本化实现提示词，Agent B 基于最新 `origin/main` 实现、本地轻量检查、commit 并 push 到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载 artifact 并核对 manifest、日志和产物；失败时退回 Agent B 在 `main` 追加修复 commit。可由 Agent X 围绕人工总目标拆分多轮并调度 A/B/C 闭环。
- 当前云端 CI 结果包覆盖静态检查、项目验证、`ChronoFocusMac` build 和 `ChronoFocus` iOS generic build。

## 关键决策

- Mac 版不重写业务代码，只新增 macOS target、平台服务和 Mac 专用 UI。
- `TimerEngine` 是唯一计时状态机；View 不维护第二套开始/暂停/完成逻辑。
- `FocusStore` 是核心数据仓库；任务、设置、会话、计划和活跃计时快照使用 `UserDefaults` JSON 持久化。
- 平台能力通过协议和服务隔离：iOS 使用本地通知、ActivityKit、StoreKit、EventKit；macOS 使用 AppKit 状态栏、桌面通知、StoreKit、EventKit 和 Live Activity 空实现。
- Mac 快照渲染中，原生 `Picker`、`Toggle`、`Slider`、`DatePicker`、`Stepper` 可能显示黄色缺失占位；快照路径使用 `macSnapshotRendering` 环境值切换快照安全控件。

## 遗留问题

- iOS scheme 已纳入云端 generic build；本机模拟器构建命令和本机 destination 基线仍可继续补强。
- StoreKit 和 EventKit 仍缺少更明确的本地 mock 或配置说明。
- Mac 小窗快捷入口可以继续优化为打开详细窗口并定位到指定 tab。
- iOS 端尚未明确是否需要同步提供 `CompletionSound` 多铃声选择 UI。
- 部分 SwiftUI View 文件较长，后续可在功能稳定后按职责拆分，不应在功能任务中顺手大重构。

## 历史记录

### v0.6 / 优化分类新建预填和筛选排序

日期：2026-07-04

核心变更：

- 新增非持久化 `TaskCategoryFilterOption` 和 `TaskCategoryPreset.prioritizedFilterOptions`，让分类筛选按当前范围内任务数量优先展示有任务分类。
- iOS 日程页选中分类后新增待办会自动预填该分类和匹配预设色；编辑已有待办不受当前筛选影响。
- macOS 日程详情把待办分类筛选状态上提，选中分类时同步快速新增区域的分类和预设色。
- iOS 分类筛选 chip 和常用分类快选按钮提升到 44pt 最小高度。
- `scripts/test_mac_core.swift` 增加空白分类归一、默认分类顺序、预设元数据、筛选排序和 fallback 元数据断言。
- `scripts/verify_project.sh` 增加分类排序 helper、新建预填、44pt 点击高度和 macOS binding/onChange 标记检查。
- `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION` 更新为 v0.6。

关键文件：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/test_mac_core.swift`
- `scripts/verify_project.sh`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.6（分类新建预填与筛选优先级）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 首次运行 `bash scripts/verify_project.sh` 发现新增 grep 标记在 `set -u` 下误展开 `$selectedCategory`，已改为单引号字面量。
- 修复后重新运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照。
- 已查看 `/tmp/chronofocus-mac-snapshots/detail-schedule.png`，分类快选和快速新增区域显示正常，未见黄色缺失控件占位。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.6 通过后继续寻找下一轮 UI 和 CI 优化点。

### v0.5 / 启动 Agent X 循环并修复 iOS 分类构建

日期：2026-07-04

核心变更：

- 新增 Agent X 召唤、职责、循环判断和停止条件。
- 将现有 Agent A/B/C 云端验证流程扩展为可被 Agent X 多轮调度。
- 新增 v0.5 Agent A 提示词，明确当前总目标、v0.4 云端失败修复和下一轮 UI/CI 优化边界。
- 修复 iOS `ScheduleView.taskCount(in:)` 分类计数分支缺少 `return` 导致的云端 `ChronoFocus` generic build 失败。
- 更新 flow、flowchart、test、prompt README 和 README 中的协作说明。

关键文件：

- `AGENTS.md`
- `ChronoFocus/Views/ScheduleView.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（持续优化）/v0.5（AgentX循环与iOS构建修复）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- v0.4 首个云端 run 的 iOS build 已确认失败，本轮修复后必须重新 push 并由 Agent C 核对最新 artifact。
- 总目标仍未完成；v0.5 通过后继续拆下一轮 UI 分类体验和 CI 覆盖优化。

### v0.4 / 分类与 CI 首轮优化

日期：2026-07-03

核心变更：

- 新增非持久化 `TaskCategoryPreset` 常用分类预设，继续复用 `FocusTask.category`，不改变 Codable 持久化字段。
- `FocusStore` 新增 `taskCategories` 分类列表，并统一清洗空白分类为 `未分类`。
- iOS 日程页新增分类筛选栏和新增/编辑待办常用分类快选，保留手写分类。
- macOS 日程详情新增快速分类选择和未完成待办分类筛选，并保持 Mac 快照安全控件路径。
- `.github/workflows/ci-results.yml` 升级为 v0.4，新增 `ChronoFocus` iOS generic build，上传 `ios-xcodebuild.log` 和 `ChronoFocus-iOS.xcresult`，并把 iOS build outcome 纳入 manifest、JUnit、failure summary 和最终 CI 状态。
- `scripts/verify_project.sh` 补充 Mac scheme 语法解析、分类功能标记和 CI iOS 结果包标记检查。

关键文件：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Services/FocusStore.swift`
- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `.github/workflows/ci-results.yml`
- `scripts/test_mac_core.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.4（分类与CI首轮优化）.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 首次未指定 `DEVELOPER_DIR` 的 Mac core 编译命中了本机 Command Line Tools Swift/SDK 不匹配；按项目规范改用 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 后，Mac core 编译通过。
- 已运行 `/tmp/chrono_focus_mac_core_tests`，输出 `Mac core tests passed.`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照。

遗留事项：

- 新增 iOS generic build 的真实稳定性需要 `origin/main` GitHub Actions run 和 Agent C artifact 核对确认。
- 本机 iOS 模拟器构建 destination 基线仍可后续补强。

### v0.3 / 升级 main 直推云端验证流程

日期：2026-07-03

核心变更：

- 将协作制度从“本地验证 + Agent C 本地提交”升级为“Agent B main 直推 + GitHub Actions 云端重验证 + Agent C 下载未加密结果包验收”。
- 明确 `agenta` / `a:`、`agentb` / `b:`、`agentc` / `c:` 角色召唤和最终回复身份标识。
- 明确 `main` 是唯一默认上传、提交、推送和云端验证分支；现存 `smalldata_test` 只记录为历史现状，不纳入默认流程。
- 新增 `.github/workflows/ci-results.yml`，在 `main` push 和手动触发时运行静态检查、`scripts/verify_project.sh` 和 `ChronoFocusMac` build，并上传 Agent C 可下载的未加密结果包。
- 移除 AppIcon PNG 的 ignore 规则，并纳入 `AppIcon-1024.png`，保证云端 checkout 满足 `scripts/verify_project.sh` 的视觉资源检查。
- 更新测试规范、核心流程、流程图、prompt 目录说明和 README，写清本地轻量检查、云端结果包、`gh auth login`、下载缓存和失败后追加修复 commit 规则。

关键文件：

- `AGENTS.md`
- `README.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `.github/workflows/ci-results.yml`
- `.gitignore`
- `ChronoFocus/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`

验证结果：

- 本轮为协作流程和 CI 改造，不改变 Swift 业务逻辑、UI、模型或持久化语义。
- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`。
- 云端重验证由 `main` push 触发 `.github/workflows/ci-results.yml` 后，以 Agent C 下载的结果包为准。

遗留事项：

- iOS scheme 的完整云端构建仍未作为默认 CI 阶段启用；当前云端重验证先覆盖现有稳定的 Mac project verification、Mac core tests、Mac UI snapshots 和 `ChronoFocusMac` build。

### v0.1 / 建立 Agent 协作和项目记忆体系

日期：2026-06-28

核心变更：

- 将 `AGENT.md` 改为项目入口记忆、架构边界和 Agent A/B/C 工作流文档。
- 新增 `update_log.md`、`md/prompt/README.md`、`md/test/test.md`、`md/flow/flow.md`、`md/flow/flowchart.md`。
- 明确后续每轮开发必须同步维护测试规范、核心流程文档和版本记录。

关键文件：

- `AGENT.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `README.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`。
- 文档-only 任务未单独运行完整 Xcode App 构建。

遗留事项：

- 下一轮正式功能开发应由 Agent A 先在 `md/prompt/` 下创建版本化实现提示词。

### v0.2 / 调整 Agent C 验收提交流程

日期：2026-06-29

核心变更：

- 明确 Agent C 验收不通过时退回 Agent B，并给出问题、证据和修复方向。
- 明确 Agent C 验收最终通过后必须按本轮版本号自动创建 git commit。
- 规定提交信息格式为 `vX.Y: 简要说明本版本做了什么`，最终汇报包含 commit hash、版本号、提交说明、核心改动和测试结果。
- 将当前入口文件引用统一为 `AGENTS.md`。

关键文件：

- `AGENTS.md`
- `README.md`
- `update_log.md`
- `md/prompt/README.md`
- `md/flow/flowchart.md`

验证结果：

- 已运行 `git diff --check`，通过。

遗留事项：

- 本轮为工作流文档更新，未改变 Swift 代码和业务逻辑。

### v0.0 / Agent 入口规范初版

日期：2026-06-27

核心变更：

- 新增初版 `AGENT.md`，记录 iOS/macOS 架构、编码规范、测试门禁、快照要求，以及后续开发后更新 README 和测试脚本的要求。
- 在 `README.md` 中新增 Agent 规范入口。

关键文件：

- `AGENT.md`
- `README.md`

验证结果：

- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`。

遗留事项：

- 初版 `AGENT.md` 内容偏项目规则和历史总结，尚未拆分成完整 Agent A/B/C 协作体系。

### v0.0 / Mac 小窗、进度条和 Pro 铃声优化

日期：2026-06-26

核心变更：

- Mac 小窗三点按钮改为竖向快捷面板。
- 快捷面板包含模式切换、常用专注时长、铃声选择与试听、日程/统计/设置入口。
- 时间下方进度条改为连续动态进度条。
- 新增 Pro 铃声选择，Mac 端支持多种提示音。

关键文件：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `ChronoFocusMac/Views/MacLinearProgressView.swift`
- `ChronoFocusMac/Services/MacNotificationService.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/verify_project.sh`

验证结果：

- 以当轮最终记录为准：项目结构验证通过。

遗留事项：

- 快捷入口后续可继续优化为打开详细窗口并定位到指定页面。

### v0.0 / macOS 状态栏版本基础完成

日期：2026-06-25

核心变更：

- 新增 `ChronoFocusMac` target 和共享 scheme。
- 新增状态栏 App：无 Dock 图标，菜单栏显示剩余时间。
- 左键打开极简番茄钟 popover，右键打开菜单。
- 新增详细窗口，包含计时、日程、统计、设置页面。
- 复用 `FocusStore`、`TimerEngine`、模型、统计和计划生成核心代码。
- 新增 Mac 通知、Mac 日历同步、Mac Pro 服务和 Mac Live Activity 占位服务。
- 新增 Mac 快照测试，覆盖小窗和四个详情页。

关键文件：

- `ChronoFocusMac/App/ChronoFocusMacApp.swift`
- `ChronoFocusMac/App/MacStatusBarController.swift`
- `ChronoFocusMac/Services/*`
- `ChronoFocusMac/Views/*`
- `ChronoFocus.xcodeproj/project.pbxproj`
- `scripts/render_mac_snapshots.swift`
- `scripts/test_mac_core.swift`
- `scripts/verify_project.sh`
- `README.md`

验证结果：

- 已运行 `bash scripts/verify_project.sh`。
- 已运行 Mac 构建命令并出现 `BUILD SUCCEEDED`：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

遗留事项：

- iOS 和 Mac 的完整回归验证仍可继续补强。
