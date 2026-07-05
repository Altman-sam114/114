# ChronoFocus

一个 SwiftUI 番茄钟 App 原型，包含 iOS 和 macOS 两个版本。iOS 版提供可自定义轮次时间、日历式日程记录、Pro 统计分析、自动番茄钟计划、后台本地通知、可调/可选铃声与振动和 Live Activity 通知栏显示；macOS 版是状态栏应用，点击菜单栏时间胶囊可打开极简番茄钟，也可展开详细窗口管理日程、统计、设置和高级功能。

## 功能

- 自定义专注、短休、长休时间和长休间隔。
- 创建日程任务，绑定番茄钟轮次并自动累计进度，可为截止时间调度本地提醒。
- 计时主界面可调铃声音量，音量为 0 时静音；设置页可选择 App 内到点音色并试听，后台系统通知继续使用系统默认提示声；可开启到点振动；可选择运行时屏幕是否常亮。
- 支持暗色/亮色两套 UI，可在计时页右上角快速切换。
- 自动化默认开启，专注、短休、长休会按设置连续流转。
- 日程页改为日历/待办样式，可按日、周、月和分类查看；待办可启用/停用、循环、到时间自动开启番茄钟。
- 新增/编辑待办时可一键选择常用分类；分类预设按钮会读出已选中状态并支持分类名 Voice Control 指令；选中分类筛选后新增待办会自动沿用该分类，分类会同步用于计划、统计和筛选。
- 分类筛选会优先展示当前范围内有待办的分类，选中分类后待办标题显示筛选数/总数；再次点击已选分类、点击“全部”或从筛选摘要清除都能退出筛选，VoiceOver 会读出已选状态和点击后的筛选/清除动作，分类 chip 也会暴露 selected trait，并提供分类名 Voice Control 指令标签；筛选摘要会读出可新增或清除动作，摘要也可直接新增此分类待办，减少在空分类间来回查找。
- 计时页的当前日程也可按分类筛选，选中分类后显示当前筛选摘要、可启动待办数和清除入口，任务行会显示分类 badge，方便从待办直接进入专注。
- 待办支持“按轮次”和“只设开始”两种模式；只设开始的任务由用户手动完成，实际用时会计入统计。
- 根据日程任务按截止时间自动生成可执行的番茄钟计划，可从计划项直接开始专注。
- 统计页作为 Pro 内购功能：普通用户可体验今日概览和 Pro 预览，Pro 用户解锁近 7 日、分类投入、最近记录、工作压力、任务安排分析，以及日/周/月工作复盘报表。
- Pro 可同步 iPhone 日历，Siri 语音创建的系统日程可在同步后自动转为 ChronoFocus 待办。
- 使用 StoreKit 2 购买/恢复 Pro 权益，内购商品 ID 为 `com.example.ChronoFocus.pro.analytics`。
- 使用本地通知在番茄钟结束和日程到期时提醒，并按设置播放系统铃声。
- 使用 ActivityKit Live Activity 在锁屏、通知栏和灵动岛显示后台倒计时。
- macOS 版提供状态栏剩余时间、弹出式极简计时器、带分类和时间上下文的当前待办、可直达日程/统计/设置的快捷面板、详细功能窗口、任务行常驻分类 badge、分类筛选快速新增预填提示、筛选摘要快捷新增和筛选/总数计数、桌面通知、触觉反馈、Pro 统计和 Mac 日历同步。
- 通知权限未授权时可在 App 内请求；用户拒绝后会引导到系统设置。
- 所有核心数据使用 `UserDefaults` JSON 持久化，重启后可恢复。

## 后台机制

iOS 不允许普通计时器 App 长时间常驻后台执行。ChronoFocus 使用可恢复的结束时间、系统本地通知和 Live Activity 实现后台体验：开始专注后保存结束时间，切到后台时由系统通知负责到点提醒和铃声，锁屏/通知栏由 Live Activity 展示倒计时，回到 App 后按真实系统时间恢复状态。

## 打开方式

使用 Xcode 打开 `ChronoFocus.xcodeproj`，选择 `ChronoFocus` scheme 后运行到 iOS 17+ 模拟器或真机。Live Activity 需要支持 ActivityKit 的设备和系统设置。

选择 `ChronoFocusMac` scheme 可运行 macOS 状态栏版本。启动后 App 不显示 Dock 图标，会在 Mac 屏幕顶部菜单栏显示一个剩余时间胶囊；左键打开小番茄钟，右键打开菜单，可从小窗快捷面板直接进入日程、统计或设置详情。

当前机器默认 `xcode-select` 指向 Command Line Tools；可用 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 临时指定 Xcode 运行构建。

## StoreKit 与日历同步本地配置

Pro 权益使用 StoreKit 2，iOS 和 macOS 共用商品 ID `com.example.ChronoFocus.pro.analytics`。本地调试购买/恢复时，需要在 Xcode scheme 绑定包含同名商品的 StoreKit 配置，或使用 App Store Connect sandbox 中已配置的同名商品；否则 Pro 面板会显示“未找到 Pro 商品”或“暂时无法载入 Pro 商品”。

不要通过直接改 `UserDefaults`、`FocusStore` 或新增调试开关伪造 Pro 权益。真实入口是 `PremiumAccessService` / `MacPremiumAccessService` 的商品加载、购买、恢复和 entitlement 刷新；Mac 快照里用于避免联网加载的初始化参数只服务快照渲染，不代表真实权益路径。

日历同步使用 EventKit。iOS 读取 iPhone 日历，macOS 读取 Mac 日历；日程 UI 的同步入口受 Pro 权益保护，`CalendarSyncService` / `MacCalendarSyncService` 只负责权限请求和导入。首次授权在 iOS 17 / macOS 14+ 请求完整日历访问；当前实现也接受系统已有的 `writeOnly` / `authorized` 状态。同步时导入从今天零点起 45 天范围内的非全天事件，分类来自系统日历标题，事件开始时间作为待办时间，导入后仍通过 `FocusStore.upsertExternalTask(...)` 参与计划、筛选和统计。

手工验证时，先用 StoreKit 配置或 sandbox 账号解锁 Pro，再在系统日历中创建一个从今天零点起 45 天范围内的非全天事件，回到日程页执行日历同步，确认待办列表出现同标题任务、分类为来源日历名称，并且重新同步不会重复创建同一外部事件。拒绝日历权限或移除商品配置时，应看到对应状态文案，而不是崩溃或静默失败。

## 本地验证

当前工作区已通过静态结构验证：

```bash
bash scripts/verify_project.sh
```

可单独构建 Mac 版：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

需要本机定位 iOS 模拟器构建问题时，可先解析当前机器可用 destination：

```bash
ruby scripts/resolve_ios_simulator_destination.rb
```

也可直接打印本机 iOS simulator build 命令：

```bash
ruby scripts/resolve_ios_simulator_destination.rb --print-build-command
```

该脚本会在 `DEVELOPER_DIR` 未设置且本机存在 `/Applications/Xcode.app/Contents/Developer` 时自动使用完整 Xcode，避免 `xcode-select` 指向 Command Line Tools 时找不到 `simctl`；如果你已设置 `DEVELOPER_DIR`，打印的 build 命令会沿用该路径。

验证内容包括工程文件和 plist 语法、Swift 文件 target 引用、iOS Live Activity 配置、本地通知/铃声/音色/振动、Pro 内购、EventKit 日历同步、统计分析报表、分类筛选、分类 chip 点击切换、分类预设按钮可访问语义、可访问提示、selected trait 和 Voice Control input labels、筛选摘要动作提示和分类快捷新增、iOS 日程筛选计数、计时页分类筛选摘要、Mac 任务行分类 badge、分类摘要插入点和动作接线检查、Mac 待办筛选计数、Mac 分类摘要快捷新增、自动番茄钟计划、日历式日程核心实现标记、macOS 状态栏应用配置、Mac 小窗快捷入口、Mac 分类预填提示、Mac 日历权限说明、CI validator 正向、artifactName mismatch 负向、artifact index 身份错包负向、artifact index totals 篡改负向、本地缺失产物负向 fixture、static-checks 日志 marker 和分类可访问 contract 日志复判、Mac 快照 manifest，以及 AppIcon PNG 资源存在性。App 图标可通过 `python3 scripts/generate_app_icon.py` 重新生成。

项目包含共享的 `ChronoFocus`、`ChronoFocusLiveActivity` 和 `ChronoFocusMac` schemes，换机器打开 Xcode 后不依赖用户私有 scheme。

## 协作与云端验证

项目默认使用 `main` 作为唯一提交、推送和云端验证分支。Agent B 完成本地轻量检查后提交并 `git push origin main`，GitHub Actions 会运行 `.github/workflows/ci-results.yml`，上传未加密 CI 结果包；Agent C 使用 `gh auth login` 后下载 artifact，核对 manifest、artifact index、run context、artifact 名称、JUnit、failure summary 错误摘录、日志、分类可访问 contract marker、Mac/iOS `.xcresult`、Mac 快照和各阶段 outcome，再确认最新 `origin/main` 是否通过。

下载 artifact 后可用脚本做结构化复判：

```bash
ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-<run_id> \
  --commit <origin-main-sha> \
  --run-id <run_id> \
  --attempt <run_attempt>
```

该脚本会核对 manifest 的分支/提交/run/attempt/关键路径、`ci-run-context.txt` 的身份字段和 artifact 名称、artifact index 的身份字段、必需路径、本地文件/目录非空状态和 totals/entries 一致性、JUnit 四个阶段 testcase、failure summary 的身份字段、阶段 outcome 和日志入口、static-checks 日志 marker、Xcode 版本日志、分类可访问 contract marker、Mac/iOS build 成功标记和 Mac 快照 manifest；`verify_project.sh` 还用错误 artifact 名称、错误 artifact index 身份、错误 artifact index totals 和本地缺失产物负向 fixture 确认 validator 不会放行错包或残缺下载。

可用 `agentx:`、`x:` 或 `X:` 启动主控循环。Agent X 接收总目标并拆分多轮 A/B/C 迭代；它不直接替代 Agent A 的提示词、Agent B 的实现 push，也不替代 Agent C 对最新云端 artifact 的验收。

本轮流程不使用 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并流；现存非 main 分支只作为历史现状保留。

## Agent 规范

后续 Codex/Agent 继续开发前必须先阅读 `AGENTS.md`。项目已建立长期迭代文档体系：

- `AGENTS.md`：入口记忆、基本规则、架构边界、Agent A/B/C/X 工作流。
- `update_log.md`：版本更新记录、历史决策、完成事项、遗留问题。
- `md/prompt/`：Agent A 每轮写给 Agent B 的版本化实现提示词。
- `md/test/test.md`：测试分层、触发条件、命令、当前基线。
- `md/flow/flow.md`：当前真实核心逻辑、数据流、执行流、架构边界。
- `md/flow/flowchart.md`：核心逻辑和 Agent 迭代流程的 Mermaid 图。

每次完成开发后必须同步检查并更新 README、测试规范、核心流程文档和更新记录。默认由 `main` push 触发云端重验证；Agent C 验收不通过时退回 Agent B 在 `main` 追加修复 commit，不得把旧结果包或文字汇报冒充验收结论。
