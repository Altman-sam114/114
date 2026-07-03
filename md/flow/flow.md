# 项目核心流程文档

## 0. 一句话总览

ChronoFocus 的主链路是：用户在 iOS App 或 macOS 状态栏 App 操作番茄钟/日程 -> `FocusStore` 保存设置、任务、计划、会话和活跃计时快照 -> `TimerEngine` 按真实系统时间驱动计时状态 -> 平台服务负责通知、Live Activity/占位、日历同步和 Pro 权益 -> SwiftUI 视图渲染当前状态。

协作验证主链路是：Agent A 写版本化提示词 -> Agent B 在最新 `origin/main` 上实现、轻量检查、commit 并 push 到 `origin/main` -> GitHub Actions 运行 `ci-results.yml` -> 上传未加密 CI 结果包 -> Agent C 下载并核对 manifest、日志和产物 -> 失败时退回 Agent B 在 `main` 追加修复 commit。

## 1. 当前核心数据流

```text
用户操作 / 系统日历 / App 恢复
  -> SwiftUI View 或平台入口
  -> FocusStore 读写模型
  -> TimerEngine 处理计时状态
  -> TimerNotificationServicing / TimerLiveActivityServicing
  -> UserDefaults JSON 持久化、通知、Live Activity、Mac 状态栏、SwiftUI 渲染
  -> scripts/test_mac_core.swift 和 scripts/render_mac_snapshots.swift 验证核心逻辑与 UI 快照
  -> GitHub Actions ci-results.yml 上传 Agent C 可复判结果包
```

核心数据对象：

- `TimerSettings`：专注/休息时长、长休间隔、通知、Live Activity、铃声、振动、常亮、自动计划、自动流转、主题。
- `FocusTask`：日程任务、分类、截止时间、预计轮次、完成轮次、启用状态、自动开始、开始模式、循环、外部日历 ID。
- `FocusSession`：已记录的专注/休息会话，用于统计和报表。
- `PomodoroPlanItem`：由日程生成的计划项，可直接启动专注。
- `ActiveTimerSnapshot`：正在运行或暂停的计时快照，用于跨前后台和重启恢复。
- `CompletionSound`：到点提示音选择，非默认音色属于 Pro。

## 2. 当前核心执行流

### 2.1 App 启动

iOS：

- `ChronoFocusApp` 创建 `FocusStore`、`NotificationService`、`LiveActivityService`、`PremiumAccessService`、`CalendarSyncService` 和 `TimerEngine`。
- SwiftUI 根视图通过环境对象使用这些服务。
- `TimerEngine` 初始化时从 `FocusStore.activeTimer` 恢复活跃计时。

macOS：

- `ChronoFocusMacApp` 通过 `MacAppDelegate` 启动。
- App 设置为 accessory，无 Dock 图标。
- 创建 `FocusStore`、`MacNotificationService`、`MacPremiumAccessService`、`MacCalendarSyncService`、`MacLiveActivityService` 和 `TimerEngine`。
- `MacStatusBarController` 创建状态栏项目，菜单栏显示 `engine.formattedRemaining`。
- 左键打开 `MacMiniTimerView` popover，右键显示开始/暂停、打开详情、退出菜单。

### 2.2 开始计时

1. 用户从计时页、小窗或计划项触发开始。
2. `TimerEngine.start()` 或 `TimerEngine.startPlanItem(_:)` 读取当前任务和模式。
3. `TimerEngine` 创建 `ActiveTimerSnapshot`，写入 `FocusStore.activeTimer`。
4. `FocusStore` 自动将快照编码为 JSON 写入 `UserDefaults`。
5. `TimerEngine` 启动 1 秒 ticker，更新 `remainingSeconds` 和 `progress`。
6. 平台通知服务调度完成提醒。
7. iOS Live Activity 启动或更新；macOS 使用 `MacLiveActivityService` 占位实现。
8. SwiftUI 视图和 Mac 状态栏通过 `ObservableObject` 状态刷新。

### 2.3 暂停、恢复、停止

- 暂停：`TimerEngine.pause()` 计算剩余秒数，写入 `remainingWhenPaused`，取消完成通知，更新 Live Activity。
- 恢复：`TimerEngine.resume()` 根据暂停剩余秒数重算 `endAt`，重新调度通知并启动 ticker。
- 停止：`TimerEngine.stop(markIncomplete:)` 取消通知和 Live Activity，必要时记录未完成会话，然后清空 `activeTimer`。

### 2.4 完成与自动流转

1. ticker 发现 `remainingSeconds <= 0`，进入 `completeCurrentSession(playSound:)`。
2. 记录 `FocusSession(completed: true)`。
3. 如果完成的是专注轮次，调用 `FocusStore.incrementRound(for:)` 更新任务和计划项。
4. 若任务完成，取消任务到期提醒。
5. 根据 `TimerSettings.completionSound`、音量和振动设置播放提示。
6. 结束 Live Activity，清空 `activeTimer`。
7. 根据 `roundsBeforeLongBreak` 计算下一模式。
8. 若 `autoStartBreaks` 或 `autoStartFocus` 启用，则自动开始下一段。

### 2.5 日程与计划

1. 用户创建、编辑、启用/停用、完成或删除 `FocusTask`。
2. `FocusStore` 保存任务，并在 `autoGeneratePomodoroPlan` 启用时调用 `generatePomodoroPlanFromSchedule()`。
3. 计划按未完成任务、截止时间、剩余轮次和休息规则生成 `PomodoroPlanItem`。
4. 用户可从计划项直接开始专注，`TimerEngine.startPlanItem(_:)` 会标记计划开始并启动计时。
5. 循环任务完成后，`FocusStore.createNextRecurrenceIfNeeded(from:)` 创建下一周期任务。
6. 外部日历同步通过 `upsertExternalTask(...)` 合并到任务列表。

### 2.6 统计与 Pro

- `FocusStore` 从 `sessions` 计算今日专注、7 日趋势、分类投入、最近记录和工作压力。
- Pro 权益由 iOS `PremiumAccessService` 和 macOS `MacPremiumAccessService` 分平台实现，商品 ID 语义保持一致。
- 普通用户可以看到预览态和购买/恢复入口；Pro 用户看到完整报表。

## 3. 核心模块

### 3.1 `AppModels.swift`

职责：定义共享模型、枚举和 Codable 兼容逻辑。

输入：用户设置、任务字段、计时快照、会话记录、日历同步结果。

输出：跨 iOS/macOS target 共享的数据结构。

禁止：新增字段不做向后兼容解码；把平台 API 类型放进共享模型。

### 3.2 `FocusStore.swift`

职责：核心数据仓库、JSON 持久化、任务管理、计划生成、统计计算。

输入：View 操作、计时引擎回写、日历同步结果。

输出：`@Published` 状态、`UserDefaults` JSON、统计数据、计划项。

禁止：绕过 `FocusStore` 在 View 或平台服务中写散落持久化。

### 3.3 `TimerEngine.swift`

职责：唯一计时状态机，控制开始、暂停、恢复、停止、完成、跳过、自动流转、恢复。

输入：用户操作、计划项、设置变化、系统时钟、活跃计时快照。

输出：运行态、剩余时间、进度、会话记录、任务轮次、通知调度、Live Activity 更新。

禁止：在 View 中复制一套计时状态机。

### 3.4 平台服务

职责：接入通知、声音/振动、Live Activity、StoreKit、EventKit。

输入：`TimerEngine` 调用、用户授权、购买/恢复、日历同步请求。

输出：系统通知、提示音、Live Activity、Pro 权益、外部日历任务。

禁止：把 iOS 专属 API 直接放进 macOS target，或把 AppKit 放进 iOS target。

### 3.5 SwiftUI Views

职责：展示和收集用户操作。

输入：环境对象和局部 UI state。

输出：调用 `FocusStore`、`TimerEngine` 和平台服务。

禁止：在 View 中承担核心业务规则或第二套持久化。

## 4. 架构边界

- 共享层只依赖 Foundation、SwiftUI 必需类型和跨平台扩展。
- iOS 平台层可以依赖 UIKit、UserNotifications、ActivityKit、StoreKit、EventKit。
- macOS 平台层可以依赖 AppKit、UserNotifications、StoreKit、EventKit。
- Mac 状态栏逻辑集中在 `MacStatusBarController`。
- Mac 快照测试通过脚本编译 Swift 文件并使用 `ImageRenderer` 渲染，不等同于完整 App 运行。

## 5. 用户入口

iOS：

- 计时页：选择任务、开始/暂停/恢复/跳过、调整铃声/振动/常亮和主题。
- 日程页：日历/待办、任务编辑、计划生成、日历同步。
- 统计页：Pro 预览、购买、报表和分析。
- 设置页：时长、通知、Pro、日历、主题等设置。
- Live Activity：锁屏、通知栏和灵动岛倒计时。

macOS：

- 菜单栏时间胶囊：显示剩余时间。
- 左键 popover：极简计时器、动态进度条、快捷面板。
- 右键菜单：开始/暂停、打开详细界面、退出。
- 详细窗口：计时、日程、统计、设置。

## 6. 前端 / 数据层 / 模型层 / 测试层关系

- SwiftUI Views 只发起用户意图。
- `TimerEngine` 把计时意图转成状态变化和平台服务调用。
- `FocusStore` 管理数据读写、统计和计划。
- `AppModels.swift` 定义跨端模型契约。
- 平台服务负责系统能力，不持有核心业务规则。
- `scripts/test_mac_core.swift` 锁定共享模型、Store、计划、统计等核心逻辑。
- `scripts/render_mac_snapshots.swift` 锁定 Mac 关键页面渲染。
- `scripts/verify_project.sh` 是结构、标记、核心测试和快照的本地/云端项目专属验证入口。
- `.github/workflows/ci-results.yml` 是默认云端重验证入口，负责在 `main` push 和手动触发时生成未加密 CI 结果包。

## 7. 协作与云端验证流

### 7.1 角色入口

- `agenta`、`a:` 或 `A:` 召唤 Agent A，负责目标分析和写 `md/prompt/` 版本化提示词。
- `agentb`、`b:` 或 `B:` 召唤 Agent B，负责在 `main` 上实现、轻量检查、提交并 push。
- `agentc`、`c:` 或 `C:` 召唤 Agent C，负责下载云端结果包并验收最新 `origin/main`。
- 没有角色前缀时，按普通 Codex 任务处理；若任务天然需要 A/B/C 边界，需要先说明本轮采用的身份。

### 7.2 main 直推闭环

1. Agent B 每轮开始前同步 `origin/main`，确认当前分支是 `main`，并检查没有无关 diff。
2. Agent B 小步实现并运行 `md/test/test.md` 要求的本地轻量检查。
3. Agent B 只提交本轮相关文件，提交信息使用 `vX.Y: 简要说明本版本做了什么`。
4. Agent B `git push origin main` 触发 GitHub Actions。
5. `.github/workflows/ci-results.yml` 在云端运行静态检查、`scripts/verify_project.sh` 和 `ChronoFocusMac` Xcode build。
6. workflow 上传未加密结果包，包含 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、`xcodebuild.log`、`verify_project.log`、`.xcresult` 和 Mac 快照。
7. Agent C 用 `gh auth login` 后下载 artifact 到 `/private/tmp/chronofocus-c-review-<run_id>/`。
8. Agent C 只验收 manifest 中 `branch=main` 且 `commitSha`、run id、run attempt 与 `origin/main` 最新状态一致的结果包。
9. 如果云端失败或结果包不一致，Agent C 不回滚；退回 Agent B 在 `main` 上追加修复 commit 后重新 push。
10. 如果 Agent C 需要补齐核心文档，也必须用 `main` 追加 commit/push，并验收新的最新 run。

本轮不把现存 `smalldata_test` 分支、PR 合并流、AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png` 等项目特例写入 ChronoFocus 默认流程。

## 8. 已确认的铁律

- Mac 版复用现有核心逻辑，不重写业务层。
- `TimerEngine` 是唯一计时状态机。
- `FocusStore` 是唯一核心数据仓库。
- 新共享字段必须向后兼容。
- Pro 商品 ID 语义在 iOS/macOS 保持一致。
- Mac 快照不能出现黄色缺失控件占位。
- README、测试规范、核心流程和更新日志必须随重要变更同步。
- 默认验证以 `main` push 后的云端结果包为 Agent C 复判依据；本地完整 Xcode build 只在人工明确要求或定位问题时默认执行。

## 9. 未来扩展点

- 为 iOS 增加与 Mac 一致的多铃声选择 UI。
- 为 StoreKit/EventKit 增加更明确的本地 mock 和验证说明。
- 增强 iOS scheme 的稳定构建命令和基线。
- Mac 快捷面板入口支持打开详细窗口指定 tab。
- 在功能稳定后拆分过长 SwiftUI View 文件。

## 10. 不允许破坏的行为

- 活跃计时必须能通过 `ActiveTimerSnapshot` 跨重启/前后台恢复。
- 完成专注必须记录会话、更新任务轮次、更新计划项。
- 自动计划必须基于未完成且启用的任务生成。
- 日历同步任务必须进入 `FocusStore`，参与计划和统计。
- 通知、声音、振动必须受 `TimerSettings` 控制。
- Mac App 必须保持状态栏应用形态，不显示 Dock 图标。
- `scripts/verify_project.sh` 必须持续作为可靠 Smoke 验证入口。
