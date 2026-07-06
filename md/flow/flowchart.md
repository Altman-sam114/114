# 项目流程图

本文用 Mermaid 图展示 ChronoFocus 当前真实核心逻辑和后续 Agent 迭代流程。每张图前都有通俗读图说明，方便人工快速复核。

## 核心数据流

读图说明：这张图从“用户或系统输入”开始，看数据如何进入共享状态，再由计时引擎和平台服务输出到 UI、通知、Live Activity、持久化和测试脚本。重点看 `FocusStore` 与 `TimerEngine` 的职责边界；当前任务选择行分类语义、分类筛选反选清除和统计计划回顾分类语义都有独立 `verify_project` marker 和 artifact validator 复判。

```mermaid
flowchart TD
  U["用户操作<br/>iOS 计时/日程/统计/设置<br/>Mac 状态栏/小窗/详细窗口"] --> V["SwiftUI Views<br/>只收集意图和展示状态"]
  SYS["系统输入<br/>App 启动/前后台恢复<br/>日历同步/通知授权"] --> V
  V --> S["FocusStore<br/>任务、设置、会话、计划、活跃快照"]
  V --> CAT["TaskCategoryPreset / TaskCategoryFilterOption<br/>常用分类快选、分类计数、筛选排序、重复点击已选分类退出、分类输入上下文、可访问状态/动作提示、selected trait、Voice Control input labels、iOS/Mac日程日期格状态和语音标签、iOS日程筛选计数、iOS日程toolbar新增入口分类语义、iOS日程任务行分类badge和语音标签、iOS/Mac日程任务操作任务名和分类语义、iOS/Mac计时主控任务名和分类语义、iOS/Mac计划开始任务/时间/轮次语义、iOS/Mac计划项分类badge、iOS/Mac计划面板生成/清空当前轮数语义、Mac快速新增提交分类/轮次语义、Mac小窗快捷面板按钮动作和选中状态语义、Mac计划项可见分类上下文、iOS统计计划回顾分类badge和语音语义、计时页筛选摘要、计时页摘要清除入口、计时页空态清除入口、计时页分类badge可访问标签、当前任务选择selected trait/运行中提示/任务名和分类语音标签、Mac任务行和小窗分类badge语音标签与预设色、新建预填、筛选摘要/快捷新增/清除按钮分类语义、Mac摘要快捷新增和稳定点击区"]
  CAT --> V
  S --> P["UserDefaults JSON<br/>持久化核心数据"]
  V --> E["TimerEngine<br/>唯一计时状态机"]
  S --> E
  E --> S
  E --> N["TimerNotificationServicing<br/>完成通知、任务提醒、声音/音色、振动"]
  E --> L["TimerLiveActivityServicing<br/>iOS Live Activity / Mac 占位服务"]
  S --> C["统计和计划计算<br/>7 日趋势、分类投入、分类列表、工作压力、PomodoroPlanItem"]
  CAL["CalendarSyncService / MacCalendarSyncService<br/>系统日历事件"] --> S
  PRO["PremiumAccessService / MacPremiumAccessService<br/>StoreKit Pro 权益"] --> V
  S --> V
  E --> V
  V --> OUT["屏幕渲染<br/>iOS App / Mac Popover / Mac 详情窗口 / 菜单栏时间"]
  N --> OUT2["系统输出<br/>本地通知、桌面通知、提示音、振动"]
  L --> OUT3["锁屏/通知栏/灵动岛<br/>或 Mac 空实现"]
  S --> T["测试入口<br/>test_mac_core.swift<br/>render_mac_snapshots.swift<br/>快照 manifest<br/>verify_project.sh<br/>分类摘要接线、动作可访问提示、日程日期格状态和语音标签、日程摘要按钮分类语义、Mac摘要按钮点击区、分类输入上下文、预设按钮、点击切换、统计分类投入占比语义、统计计划回顾分类语义、iOS日程toolbar新增入口分类语义、iOS日程任务行分类badge语音标签、iOS/Mac日程任务操作任务名和分类语义、iOS/Mac计时主控任务名和分类语义、iOS/Mac计划开始任务/时间/轮次语义、iOS/Mac计划项分类badge、iOS/Mac计划面板生成/清空当前轮数语义、Mac快速新增提交分类/轮次语义、Mac小窗快捷面板按钮语义、Mac计划项分类上下文、计时页摘要清除入口、计时页空态清除入口、计时页分类badge可访问标签、当前任务选择selected trait/提示/运行中不可切换提示/Voice Control标签、Mac任务行和小窗分类badge语音标签与预设色、selected trait 和 Voice Control 标签检查<br/>validator 复判 manifest元数据/artifactName/overallOutcome/project reports、固定CI process version、JUnit元数据/errors/outcome/failure元素、index精确清单/本地元数据/version/artifactName、额外artifact拒绝、Mac快照generatedAt和byteCount、static-checks、Xcode 版本、分类摘要动作/分类可访问/日程任务操作/计时主控/计划开始/计划分类badge/Mac计划分类/计划面板操作/日程toolbar新增/Mac快速新增/分类输入上下文/Mac小窗快捷面板/统计分类占比/统计计划回顾分类日志 marker<br/>validator 正向/旧process version/摘要marker缺失/任务操作marker缺失/计时主控marker缺失/计划开始marker缺失/计划分类badge marker缺失/Mac计划分类marker缺失/计划面板操作marker缺失/日程toolbar新增marker缺失/Mac快速新增marker缺失/分类输入上下文marker缺失/Mac小窗快捷面板marker缺失/统计分类占比marker缺失/统计计划回顾分类marker缺失/JUnit元数据/JUnit errors/JUnit错包/JUnit failure元素/错包/manifest artifactName/manifest overallOutcome/index artifactName/manifest元数据/index错包/totals错包/index未预期entry/额外artifact/本地篡改/缺失产物/快照manifest generatedAt和byteCount篡改 fixture"]
```

## 计时执行流

读图说明：这张图描述一次番茄钟从开始到完成的执行路径。任何新增计时行为都应该落在 `TimerEngine`，不要让 View 自己维护第二套计时规则。

```mermaid
flowchart TD
  A["用户点击开始<br/>或从计划项开始"] --> B["TimerEngine.start / startPlanItem<br/>读取任务、模式、设置"]
  B --> C["创建 ActiveTimerSnapshot<br/>sessionID、taskID、startedAt、endAt、plannedSeconds"]
  C --> D["写入 FocusStore.activeTimer<br/>触发 UserDefaults JSON 保存"]
  D --> E["启动 1 秒 ticker<br/>按真实系统时间计算 remainingSeconds"]
  E --> F["调度平台能力<br/>完成通知、Live Activity 或 Mac 占位"]
  F --> G["SwiftUI 和菜单栏刷新<br/>剩余时间、进度、当前任务"]
  G --> H{"用户操作或时间到"}
  H -->|暂停| I["pause<br/>保存 remainingWhenPaused<br/>取消完成通知"]
  I --> J["resume<br/>重算 endAt 并重新调度"]
  J --> E
  H -->|停止| K["stop<br/>取消通知和 Live Activity<br/>必要时记录未完成会话"]
  H -->|完成| L["completeCurrentSession<br/>记录 FocusSession"]
  L --> M["专注模式更新任务轮次<br/>更新计划项和任务完成状态"]
  M --> N["按 completionSound 播放 App 内提示音/振动<br/>结束 Live Activity<br/>清空 activeTimer"]
  N --> O["计算下一模式<br/>短休/长休/专注"]
  O --> P{"自动流转开启?"}
  P -->|是| B
  P -->|否| Q["回到空闲状态<br/>等待用户下一次操作"]
```

## 日程、计划和统计流

读图说明：这张图展示任务如何变成番茄钟计划，计时完成后又如何反向更新任务和统计。日历同步进来的事件也必须先进入 `FocusStore`，不能绕过核心数据仓库；统计最近记录会继续使用 `FocusSession.category` 显示分类 badge，统计计划回顾会使用 `PomodoroPlanItem.category` 显示分类 badge，并把任务、分类、时间和轮次写入可访问语义。

```mermaid
flowchart TD
  A["用户新增/编辑任务<br/>或系统日历同步事件"] --> P0["分类 UI<br/>iOS/Mac日程日期格读出日期、待办数、选中和非本月状态<br/>iOS日程筛选/总数计数<br/>iOS日程toolbar新增入口读出当前分类<br/>iOS日程任务行分类badge语音标签<br/>iOS/Mac日程任务操作读出任务名和分类<br/>iOS/Mac计时主控读出任务名和分类<br/>iOS/Mac计划开始读出任务/时间/轮次<br/>iOS/Mac计划项分类badge可见<br/>iOS/Mac计划面板生成/清空读出当前未完成轮数<br/>Mac快速新增提交读出分类和预计轮次<br/>Mac小窗快捷面板读出按钮动作和选中状态<br/>Mac计划项直接显示分类<br/>计时页当前待办筛选摘要<br/>计时页摘要清除入口<br/>计时页空态清除入口<br/>计时页任务行分类badge可访问<br/>当前任务选择读出已选中状态、运行中提示和任务/分类语音标签<br/>Mac任务行和小窗分类badge可说分类名<br/>常用分类快选、手写分类和输入上下文<br/>重复点击已选分类退出<br/>VoiceOver读出已选状态和点击动作<br/>辅助技术识别 selected trait<br/>Voice Control 可说日期、任务和分类名<br/>筛选摘要新增/清除按钮读出分类名<br/>筛选联动新建预填<br/>Mac 摘要快捷新增并聚焦任务名<br/>Mac 快速新增当前分类/已预填提示<br/>Mac 摘要按钮稳定点击区<br/>Mac 连续新增保留分类"]
  P0 --> B["FocusStore.addTask / updateTask / upsertExternalTask"]
  B --> C["FocusTask<br/>标题、分类、截止时间、轮次、循环、外部日历 ID"]
  C --> C2["FocusStore.taskCategories + TaskCategoryFilterOption<br/>合并预设/已有分类<br/>有任务分类优先显示"]
  C2 --> C3["选中分类摘要/预填提示<br/>iOS/Mac 筛选/总数计数<br/>iOS/Mac 新增此分类、一键清除按钮分类语义<br/>Mac 摘要按钮稳定点击区<br/>Mac 已预填提示、空态提示"]
  C3 --> D{"autoGeneratePomodoroPlan 开启?"}
  D -->|是| E["generatePomodoroPlanFromSchedule<br/>按未完成任务和截止时间生成计划"]
  D -->|否| F["仅保存任务<br/>等待用户手动生成或开始"]
  E --> G["PomodoroPlanItem 列表<br/>计划开始/结束、轮次、颜色"]
  G --> H["用户从计划项开始专注"]
  H --> I["TimerEngine.startPlanItem<br/>标记计划项开始并启动计时"]
  I --> J["完成专注"]
  J --> K["FocusStore.incrementRound<br/>完成轮次、计划项、循环任务"]
  J --> L["FocusStore.recordSession<br/>写入 FocusSession"]
  L --> M["统计分析<br/>今日、7 日、分类、报表、工作压力"]
  K --> M
  M --> N["AnalyticsView / MacAnalyticsDetailView<br/>普通预览或 Pro 完整报表<br/>iOS计划回顾分类badge和语音语义"]
```

## 平台边界图

读图说明：这张图说明哪些代码可以共享，哪些只能在 iOS 或 macOS target 中使用。后续改平台能力时，先看这张图避免污染 target。

```mermaid
flowchart LR
  SH["共享层<br/>AppModels<br/>FocusStore<br/>TimerEngine<br/>TimerPlatformServices<br/>Shared"] --> IOS["iOS 平台层<br/>ChronoFocusApp<br/>iOS Views<br/>NotificationService<br/>LiveActivityService<br/>CalendarSyncService<br/>PremiumAccessService"]
  SH --> MAC["macOS 平台层<br/>ChronoFocusMacApp<br/>MacStatusBarController<br/>Mac Views<br/>MacNotificationService<br/>MacCalendarSyncService<br/>MacPremiumAccessService"]
  IOS --> IOUT["iOS 输出<br/>本地通知<br/>Live Activity<br/>StoreKit<br/>EventKit<br/>UIKit 常亮控制"]
  MAC --> MOUT["macOS 输出<br/>状态栏<br/>Popover<br/>桌面通知<br/>StoreKit<br/>EventKit<br/>AppKit"]
  IOS -.禁止直接依赖.-> MAC
  MAC -.禁止直接依赖.-> IOS
```

## Agent 迭代与云端验收流程

读图说明：这张图描述当前默认协作方式。人工提出目标后，Agent A 写提示词；Agent B 必须基于最新 `origin/main` 实现、轻量检查、提交并直推 `main`；GitHub Actions 生成未加密 CI 结果包；Agent C 下载并核对最新 run。失败时不回滚，退回 Agent B 在 `main` 追加修复 commit 后重新触发云端验证。

```mermaid
flowchart TD
  H["人工提出目标<br/>功能、算法、禁止项、验收、性能、UI、测试"] --> A["Agent A<br/>阅读入口文档和源码<br/>分析目标并设计实现方案"]
  A --> P["md/prompt/版本目录<br/>写给 Agent B 的详细实现提示词<br/>包含 main push、CI、artifact 要求"]
  P --> B0["Agent B<br/>git fetch origin<br/>git switch main<br/>git pull --ff-only origin main"]
  B0 --> B1["Agent B 实现<br/>按现有架构小步修改<br/>同步必要文档"]
  B1 --> L["本地轻量检查<br/>git diff --check<br/>YAML/plist/脚本语法检查"]
  L --> G["main commit<br/>vX.Y: 简要说明本轮做了什么"]
  G --> PUSH["git push origin main<br/>触发 GitHub Actions"]
  PUSH --> CI["GitHub Actions<br/>ci-results.yml<br/>静态检查、verify_project、Mac build、iOS build"]
  CI --> ART["未加密 CI 结果包<br/>manifest元数据/artifactName/overallOutcome/project reports、固定CI process version、artifact index artifactName/version、精确清单和本地元数据复算、额外artifact拒绝、run context精确键集、failure summary 身份/总结果/outcome/错误摘录、JUnit 元数据/errors/outcome/failure元素、static-checks marker、Xcode 版本、verify_project 分类摘要动作/分类可访问/日程任务操作/计时主控/计划开始/计划分类badge/Mac计划分类/计划面板操作/日程toolbar新增/Mac快速新增/分类输入上下文/Mac小窗快捷面板/统计分类占比/统计计划回顾分类 marker、Mac/iOS 日志、Mac/iOS xcresult、快照、快照 manifest"]
  ART --> C["Agent C<br/>gh auth login<br/>下载 artifact 到 /private/tmp/chronofocus-c-review-run_id<br/>核对 manifest artifactName、overallOutcome、index artifactName、artifact index、index totals、run context精确键集、artifact 名称、计时主控/计划分类badge/计划面板操作/日程toolbar新增/Mac快速新增/分类输入上下文/Mac小窗快捷面板/统计分类占比/统计计划回顾分类 marker 和快照 manifest"]
  C --> V["核对最新 origin/main<br/>commitSha、run id、run attempt、branch=main<br/>run context无重复/无额外字段<br/>artifact 名称、日志和项目专属产物"]
  V --> PASS{"验收通过?"}
  PASS -->|不通过| BACK["退回 Agent B<br/>问题、证据、修复路径"]
  BACK --> FIX["main 追加修复 commit<br/>不回滚旧提交"]
  FIX --> PUSH
  PASS -->|通过| DOC{"核心文档已同步?"}
  DOC -->|否| D["补齐 md/flow、md/test、update_log<br/>作为 main 追加文档 commit"]
  D --> PUSH
  DOC -->|是| J["人工复核<br/>进入下一轮"]
  J -->|继续下一轮| H
  J -->|发现新目标| A
```

## Agent X 主控循环

读图说明：这张图描述人工用 `agentx:` 给出总目标后，Agent X 如何拆分轮次并调度 Agent A、Agent B、GitHub Actions 和 Agent C。Agent X 只做主控判断，不能跳过 Agent C 对最新 artifact 的验收；失败或阻塞时必须退回、暂停或停止，不能伪装成功继续下一轮。

```mermaid
flowchart TD
  H["人工输入 agentx 总目标 X<br/>范围、约束、验收标准"] --> X0["Agent X<br/>理解总目标和当前状态"]
  X0 --> X1["拆分本轮小目标<br/>版本、边界、非目标、风险"]
  X1 --> A["Agent A<br/>写 md/prompt 版本化提示词<br/>包含验证、CI、artifact、Agent C 要求"]
  A --> B["Agent B<br/>按提示词实现<br/>本地轻量检查、commit、push origin/main"]
  B --> CI["GitHub Actions<br/>ci-results.yml<br/>运行静态检查、verify_project、Mac/iOS build"]
  CI --> ART["最新未加密 artifact<br/>manifest、artifact index、run context、JUnit、failure summary/错误摘录、日志、xcresult、快照 manifest、项目产物"]
  ART --> C["Agent C<br/>下载最新 run artifact<br/>核对 branch、commitSha、run id、run attempt、run context精确键集、artifact 名称、manifest artifactName、overallOutcome、index artifactName、manifest元数据和project reports"]
  C --> X2["Agent X 读取 Agent C 结论<br/>只基于最新 origin/main artifact 判断"]
  X2 --> D{"下一步判断"}
  D -->|通过且总目标未完成| X1
  D -->|不通过但可修复| B
  D -->|需要人工决策<br/>权限/密钥/方向/冲突| P["暂停等待人工确认"]
  D -->|达到停止条件| S["停止循环<br/>说明阻塞、证据和建议"]
  D -->|总目标完成| DONE["宣布完成<br/>最后一轮 Agent C 已确认云端通过"]
```
