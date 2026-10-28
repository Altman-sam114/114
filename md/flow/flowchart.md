# 项目流程图

读图说明：v1.10把完成状态、任务查询和分类作为独立的界面筛选；完成任务仍可找回。Mac分类选择控件限制两行并提供完整悬停/辅助功能名称，任务正文继续完整换行。删除先确认并复查活动身份，原生证据则按真实执行的测试身份核对，不以总数替代。

```mermaid
flowchart LR
  BASE[日期范围任务 / Mac全部任务] --> FILTER[共享TaskListFilter / 状态与分类 / 标题分类多词查询]
  FILTER --> VIEW[计数与任务列表 / 未完成 / 已完成 / 全部]
  FILTER --> CHIPS[Mac分类标签最多两行 / 完整help与AX]
  VIEW --> TEXT[任务标题与分类正文完整换行]
  VIEW --> RESTORE[原Store完成或恢复入口]
  VIEW --> MORE[iOS更多 / Mac删除]
  MORE --> ALERT[原生alert / 取消和删除都明确可见]
  ALERT --> CONFIRM{确认且当前非活动任务}
  CONFIRM -->|是| DELETE[FocusStore删除任务与计划 / 保留会话]
  DELETE --> REMINDER[确认删除成功后取消提醒]
  CONFIRM -->|取消| KEEP[保持数据]
  EDIT[编辑器保存] --> SAVED{Store返回保存对象}
  SAVED -->|成功| LOCATE[关闭并定位保存任务]
  SAVED -->|失败| DRAFT[保留草稿 / 说明计时保护 / 继续编辑]
  REPEAT[自然到点或手动完成 / 循环插入下一期] --> ID[Store成功完成 / 按原ID返回 / 取消原提醒]
  TREE[真实tests树 / 9个唯一Passed测试与设备耗时] --> EVIDENCE[关联summary与38具名场景]
  EVIDENCE --> REVIEW[执行相关云端验证时核对同源证据 / 长文本与草稿]
  TREE --> DIAG[成功或失败的逐测试诊断 / 不替代验收]
  BUILD[10分钟构建与启动 / 二者并行] --> READY[双成功记录实际UDID]
  READY --> RUN[14分钟测试步骤 / 复核UDID / 总job35分钟]
  RUN --> COLLECT[独立always收集 / 5分钟 / 保留真实失败]
  COLLECT --> TREE
```

读图说明：v1.9把待办内容和动作分开，改变展示不改变任务或计时真源；云端启动和构建可重叠，运行测试前必须同时成功，结果再按真实场景绑定。

```mermaid
flowchart LR
  TASK[FocusTask与原Store入口] --> CONTENT[完整标题 / 可换行分类与时间]
  CONTENT --> ACTION[带文字的专注 / 编辑 / 启停]
  ACTION --> SIZE{字体较大}
  SIZE -->|是| COLUMN[动作纵排 / 44pt及可达性]
  SIZE -->|否| ROW[动作横排]
  BOOT[云端设备boot请求] --> READY[bootstatus / 最多300秒]
  BUILD[同源build-for-testing] --> BOTH{两个前置都成功}
  READY --> BOTH
  BOTH --> RUN[test-without-building / 当前登记测试集合]
  RUN --> BIND[summary与manifest / 当前具名场景 / UDID与尺寸]
  BIND --> REVIEW[当前会话核对新SHA并读原生图]
```

读图说明：大字体日历先让标题和范围各占一行，寻找动作时在外层留白滚动；Mac图标同时核对可解码兼容图和真实编译资源，不把特定ICNS类型当成唯一存储位置。

```mermaid
flowchart LR
  TYPE[辅助字体] --> LAYOUT[日历标题与范围纵排 / 今天一行]
  SEEK[原生寻找与视口纠正] --> DRAG[外层10pt留白 / 最少32pt / 按视口和溢出限幅]
  DRAG --> BOUNDS[可达性与实时导航栏/TabBar边界]
  ICNS[真实ICNS原文] --> DECODE[系统sips解码兼容图]
  CAR[真实Assets.car] --> ASSET[assetutil原文 / 同名1024px图标]
  DECODE --> BOTH[两项均满足才通过Release图标检查]
  ASSET --> BOTH
```

读图说明：v1.8把读取权限和过期倒计时的边界前置处理；Release工程检查复用既有来源门禁，但不把未签名构建等同于正式发行。

```mermaid
flowchart LR
  SYNC[用户同步日历] --> BUSY{是否正在同步}
  BUSY -->|否| ACCESS[读取实际授权]
  ACCESS -->|完整访问| READ[EventKit读取 / Store合并]
  ACCESS -->|首次或仅写入| REQUEST[请求完整访问 / await后复查]
  REQUEST -->|返回成功且实际完整| READ
  REQUEST -->|其他| DENY[显示权限说明 / 不读取]
  ACCESS -->|拒绝受限未知| DENY
  LIVE[Live Activity重绘] --> RANGE{暂停或结束日期}
  RANGE -->|暂停| PAUSE[非负快照剩余时间]
  RANGE -->|未来| FUTURE[合法倒计时区间]
  RANGE -->|到点过期| ZERO[00:00 / 已到时]
  GATE[当前main来源门禁] --> RELEASE[双端Release构建]
  RELEASE --> PRODUCT[真实App与appex / 隐私与版本架构]
  PRODUCT --> EVIDENCE[独立Release工程证据 / 上传前后复查]
  EVIDENCE --> HUMAN[签名身份与真实服务发行验证待完成]
```

读图说明：主题沿用已有设置；分类先完成搜索与计数，再决定展示数量，收起不会修改真实分类或任务。

```mermaid
flowchart LR
  THEME[FocusStore既有appThemeMode] --> ROOT[Mac详情与popover / iOS根视图]
  ROOT --> COLOR[亮暗背景与正文 / 浅色强调文字]
  FULL[完整排序分类与计数] --> SEARCH[共享规范化搜索]
  SEARCH --> SHOW[展示派生：筛选6项 / 表单4项]
  SELECT[完整来源中的当前选择] --> PIN[前缀或搜索之外单独保留]
  SHOW --> QUERY{有查询或已展开}
  QUERY -->|是| ALL[全部匹配选项]
  QUERY -->|否| PREFIX[前缀与查看全部入口]
  PIN --> UI[Mac分类视图]
  ALL --> UI
  PREFIX --> UI
```

读图说明：v1.5只重排展示层，计时、任务和持久化仍由既有共享入口处理。独立UI证据与正式生产包分开上传，分别核对同一源SHA。

```mermaid
flowchart LR
  IOS[iOS当前任务/倒计时/文字主控] --> QUEUE[当前待办队列]
  QUEUE --> REMIND[默认收起的提醒与统计]
  MAC[Mac实际内容宽度] --> WIDTH{至少780pt}
  WIDTH -->|是| TWO[计时主区与队列双列 / 日程表单与待办双列]
  WIDTH -->|否| ONE[单列：计时主区优先 / 日程待办优先]
  PUSH[授权main成功push] --> GATE[UI独立workflow来源gate]
  GATE --> SHA[仅checkout已核对SHA]
  SHA --> RENDER[共用renderer编译入口 / 登记的辅助状态PNG / 亮暗主题]
  RENDER --> CHECK[上传前后复查main与源attempt]
  CHECK --> UIART[独立UI artifact与身份manifest]
  UIART --> REVIEW[核对生产review和相关UI证据并读图]
```

读图说明：v1.6在同一个独立UI run里分别执行Mac静态布局与两种iPhone原生交互，三份平台证据不进入生产结果包。新安装与清空后的空数据不再触发演示任务。

```mermaid
flowchart LR
  SOURCE[授权当前main成功push] --> GATE[每个job先核对源身份再checkout]
  GATE --> MAC[Mac同源renderer / 登记布局图与亮暗空白负例]
  GATE --> PHONE1[iPhone13 / 390pt / 当前登记原生UI测试]
  GATE --> PHONE2[iPhoneSE3 / 375pt / 当前登记原生UI测试]
  PHONE1 --> XC[xcresult与原始摘要 / 当前具名截图每设备 / 通知动作亮暗及大字体]
  PHONE2 --> XC
  XC --> VERIFY[精确集合全通过 / 无失败或跳过 / 截图物理尺寸核对]
  MAC --> FRESH[上传前后复查main与attempt]
  VERIFY --> FRESH
  FRESH --> PACK[按平台独立artifact / 两套来源身份]
  EMPTY[首次安装或持久化空数组] --> STORE[FocusStore保留真实空数据]
  STORE --> FREE[仍可开始自由专注或新增任务]
```

读图说明：分类搜索仅改变可见选项，选中分类与任务筛选保持独立；计数和代表色继续来自完整的原始选项。

```mermaid
flowchart LR
  O[完整优先排序分类] --> Q{分类至少6项}
  Q -->|是| F[共享query规范化与子串搜索]
  Q -->|否| ALL[忽略隐藏query，显示全部]
  F --> M[匹配选项与匹配数]
  F --> P[未匹配的当前选择单独保留]
  M --> UI[iOS计时/日程与Mac计时/日程]
  P --> UI
  ALL --> UI
  UI -->|点击分类| S[更新瞬态selectedCategory]
  UI -->|清除搜索| C[仅清除query]
```

本文用 Mermaid 图展示 ChronoFocus 当前真实核心逻辑和目标驱动迭代流程。每张图前都有通俗读图说明，方便人工快速复核。

## 核心数据流

读图说明：这张图从“用户或系统输入”开始，看数据如何进入共享状态，再由计时引擎和平台服务输出到 UI、通知、Live Activity、持久化和云端测试脚本。日程使用完整 `upcomingTasks()`，计时消费使用 `startableTasks()`；已有分类选择、iOS/Mac 日期格分类计数和 iOS/Mac 计时队列展开都只属于 View 草稿/瞬态，不新增持久化或计时状态；分类代表色由预设、首个同类任务、session-only/fallback 的共享查询统一派生，选中背景文字由 `contrastTextHex(on:)` 选择，活动计时 UI 读取快照色；日期格未筛选时显示全量 `dueDate` 自然日计数，选中分类时与列表共享该分类谓词；Mac 队列从完整筛选结果派生默认前 7 项，Mac 日历范围列表从完整 `visibleTasks` 派生默认前 4 项，分类、日期、范围或结果变化时恢复收起；CI 由七个业务阶段和两个包阶段 outcome、成功/失败双 profile 和包外 run/artifact API + ZIP 证据链交给 validator 复判，finalizer 失败时先由恢复脚本重建一致 fallback 包，恢复失败不上传陈旧目录。

```mermaid
flowchart TD
  U["用户操作<br/>iOS 计时/日程/统计/设置<br/>Mac 状态栏/小窗/详细窗口"] --> V["SwiftUI Views<br/>只收集意图和展示状态"]
  SYS["系统输入<br/>App 启动/前后台恢复<br/>日历同步/通知授权"] --> V
  V --> S["FocusStore<br/>任务、设置、会话、计划、活跃快照"]
  V --> CAT["分类 UI<br/>分类快选、计数、筛选与重复点击清除<br/>iOS/Mac录入从taskCategories复用已有分类<br/>固定locale规范化、排除预设、首次出现去重<br/>至少6项时瞬态搜索、计数、清除与无结果<br/>搜索只过滤option，选择只改category/accentHex草稿<br/>首个同分类任务提供代表色<br/>iOS计时队列默认4项、可展开、运行中只读<br/>Mac计时队列默认7项、可展开、运行中只读<br/>Mac日历范围列表默认4项、超出可展开/收起<br/>分类/筛选数量变化恢复收起<br/>辅助功能语义"]
  CAT --> V
  S --> P["UserDefaults JSON<br/>持久化核心数据"]
  V --> E["TimerEngine<br/>唯一计时状态机"]
  S --> E
  E --> S
  E --> N["TimerNotificationServicing<br/>完成通知、任务提醒、声音/音色、振动"]
  E --> L["TimerLiveActivityServicing<br/>iOS Live Activity / Mac 占位服务"]
  S --> C["统计和计划计算<br/>7 日趋势、分类投入时长/次数/排行/排序依据/空态/元信息和占比可读性、分类列表、工作压力、PomodoroPlanItem"]
  CAL["CalendarSyncService / MacCalendarSyncService<br/>系统日历事件"] --> S
  PRO["PremiumAccessService / MacPremiumAccessService<br/>StoreKit Pro 权益"] --> V
  S --> V
  E --> V
  V --> OUT["屏幕渲染<br/>iOS App / Mac Popover / Mac 详情窗口 / 菜单栏时间"]
  N --> OUT2["系统输出<br/>本地通知、桌面通知、提示音、振动"]
  L --> OUT3["锁屏/通知栏/灵动岛<br/>或 Mac 空实现"]
  S --> T["云端测试入口<br/>verify_project.sh / validate_ci_artifact.rb<br/>startableTasks与计时边界契约<br/>七阶段 outcome 与 fallback 结果包<br/>finalizer失败先恢复一致包，恢复失败不上传陈旧目录<br/>success 四种模式 + failure 第四模式<br/>run十四项、artifact八项、ZIP三项与目录绑定检查<br/>push来源严格复判；dispatch失败需显式 expected-event<br/>授权触发来源、安全边界、字段篡改、marker缺失fixture<br/>manifest/index/stage/JUnit/build/快照复判"]
  T --> PKG["结果包阶段绑定<br/>bootstrap / createManifest<br/>success required index<br/>失败摘要日志尾部"]
```

## 计时执行流

读图说明：这张图描述一次番茄钟从开始到完成的执行路径。任何新增计时行为都应该落在 `TimerEngine`，不要让 View 自己维护第二套计时规则。

```mermaid
flowchart TD
  A["用户点击开始<br/>或从计划项开始"] --> B["TimerEngine.start / startPlanItem<br/>最终复核 startableTask<br/>读取任务、模式、设置"]
  B --> C["创建 ActiveTimerSnapshot<br/>sessionID、taskID、startedAt、endAt、plannedSeconds、tintHex"]
  C --> D["写入 FocusStore.activeTimer<br/>触发 UserDefaults JSON 保存"]
  D --> E["启动 1 秒 ticker<br/>按真实系统时间计算 remainingSeconds"]
  E --> F["调度平台能力<br/>完成通知、Live Activity 或 Mac 占位"]
  F --> G["SwiftUI 和菜单栏刷新<br/>剩余时间、进度、当前任务、快照代表色"]
  G --> H{"用户操作或时间到"}
  H -->|暂停| I["pause<br/>保存 remainingWhenPaused<br/>取消完成通知"]
  I --> J["resume<br/>重算 endAt 并重新调度"]
  J --> E
  H -->|停止| K["stop<br/>取消通知和 Live Activity<br/>必要时记录未完成会话<br/>清空快照、解除活动任务写入保护"]
  K --> IDLE["idle 修改回到 Store 正常入口<br/>停用/删除异步收敛为自由专注<br/>合法编辑保留可启动选择"]
  H -->|编辑/停用/完成切换/删除活动任务| LOCK["FocusStore按activeTimer.taskID拒绝或过滤<br/>运行/暂停均保护任务与快照身份<br/>纯拒绝/无效删除不写数组、不重生计划<br/>mixed合法删除仍沿用计划更新"]
  LOCK --> G
  H -->|完成| L["completeCurrentSession<br/>记录 FocusSession"]
  L --> M["专注模式更新任务轮次<br/>更新计划项和任务完成状态"]
  M --> N["按 completionSound 播放 App 内提示音/振动<br/>结束 Live Activity<br/>清空 activeTimer"]
  N --> O["计算下一模式<br/>短休/长休/专注<br/>空闲 reconcile 失效选择"]
  O --> P{"自动流转开启?"}
  P -->|是| B
  P -->|否| Q["回到空闲状态<br/>等待用户下一次操作"]
```

## 日程、计划和统计流

读图说明：这张图展示任务如何变成番茄钟计划，计时完成后又如何反向更新任务和统计。新增/编辑表单可从 store 的完整分类列表复用非预设分类，但选择只修改表单草稿；用户提交后才通过既有 `FocusStore` 入口持久化并刷新筛选、计划和统计。

```mermaid
flowchart TD
  A["用户新增/编辑任务<br/>或系统日历同步事件"] --> P0["分类 UI<br/>iOS/Mac日程日期格未筛选显示全量计数、筛选后显示分类计数<br/>日期格视觉计数与 VoiceOver/Voice Control 语义共享 selectedCategory<br/>Mac日历范围计数、列表和空态共享分类上下文<br/>Mac日历范围空态把当前选中日期带入快速新增并聚焦标题<br/>iOS日程筛选/总数计数<br/>iOS日程toolbar新增入口读出当前分类<br/>iOS/Mac日程分类空态可直接新增此分类或清除筛选<br/>iOS日程任务行分类badge语音标签<br/>iOS/Mac日程任务操作读出任务名和分类<br/>iOS待办保存按钮读出任务、分类、预计轮次或只设开始，取消按钮读出取消新增/取消编辑、任务和分类<br/>iOS/Mac计时主控读出任务名和分类<br/>iOS/Mac计划开始读出任务/时间/轮次<br/>iOS/Mac计划项分类badge可见<br/>iOS/Mac计划面板生成/清空读出当前未完成轮数<br/>Mac快速新增任务名称输入框读出将新增到的分类<br/>Mac快速新增提交读出分类和预计轮次<br/>Mac小窗快捷面板读出按钮动作和选中状态<br/>Mac计划项直接显示分类<br/>计时页当前待办筛选摘要<br/>计时页摘要清除入口<br/>计时页空态清除入口<br/>计时页任务行分类badge可访问<br/>当前任务选择读出已选中状态、运行中提示和任务/分类语音标签<br/>Mac任务行和小窗分类badge可说分类名<br/>常用分类快选、手写分类和输入上下文<br/>重复点击已选分类退出<br/>VoiceOver读出已选状态和点击动作<br/>辅助技术识别 selected trait<br/>Voice Control 可说日期、任务和分类名<br/>筛选摘要新增/清除按钮读出分类名<br/>筛选联动新建预填<br/>Mac 摘要快捷新增并聚焦任务名<br/>Mac 快速新增当前分类/已预填提示<br/>Mac 摘要按钮稳定点击区<br/>Mac 连续新增保留分类"]
  P0 --> DRAFT["已有分类选择<br/>只更新category/accentHex草稿<br/>不自动保存或持久化"]
  DRAFT --> B["FocusStore.addTask / updateTask / upsertExternalTask<br/>用户提交后的统一入口"]
  B --> C["FocusTask<br/>标题、分类、截止时间、轮次、循环、外部日历 ID"]
  C --> C2["FocusStore.taskCategories + TaskCategoryFilterOption<br/>合并预设/已有分类<br/>有任务分类优先显示"]
  C2 --> IS["iOS/Mac日程分类筛选<br/>结果非空显示摘要<br/>结果为空只显示双操作空态"]
  IS -->|新增此分类| SE["既有TaskEditor或Mac快速新增<br/>预填当前分类"]
  SE --> B
  IS -->|清除筛选| C2
  IS -->|分类摘要转到计时| TH["一次性 TimerHandoffRequest<br/>UUID、分类、preferredTaskID=nil"]
  C -->|日程任务行设为计时待办| TE["一次性精确接力请求<br/>UUID、分类、preferredTaskID"]
  TH --> TN["DashboardView / MacDetailSelection<br/>保存瞬态请求并切换到计时"]
  TE --> TN
  TN --> TV["TimerView / MacTimerDetailView<br/>按请求id消费并恢复分类<br/>从FocusStore重新查询可启动任务"]
  TV -->|非运行且目标合法| TS["TimerEngine.selectTask<br/>只选择，不自动开始"]
  TV -->|精确目标失效| TC["TimerEngine.selectTask(nil)<br/>不保留同分类错误旧任务"]
  TV -->|计时运行中| TB["只恢复分类筛选<br/>不替换或清除当前任务"]
  TS --> D
  TC --> D
  TB --> D
  C2 --> IT["iOS计时分类筛选<br/>非空摘要与空态互斥<br/>筛选数/总数、双操作<br/>默认前4项、超过时展开/收起"]
  IT -->|新增此分类| IE["既有TaskEditor sheet<br/>initialCategory预填<br/>筛选保持"]
  IE --> B
  IT --> IR["筛选任务行<br/>分类或数量变化恢复收起<br/>运行中可展开浏览但不可切换任务<br/>隐藏重复视觉badge<br/>保留整行可访问语义"]
  IR --> D
  C2 --> MT["Mac 计时待办队列<br/>全部/分类筛选、结果数/总数<br/>完整 filteredTasks 用于计数/上下文/空态<br/>默认 visibleTasks 前7项，超过7项展开/收起<br/>分类或筛选数量变化、handoff 恢复收起<br/>运行中可展开浏览，任务行继续禁用<br/>非空筛选上下文或分类空态"]
  MT --> C3["非空分类上下文条<br/>分类名、筛选数/总数<br/>自适应新增/清除动作<br/>隐藏重复视觉badge但保留整行语义"]
  MT -->|新增此分类| MS["MacDetailSelection<br/>写入唯一 MacQuickAddRequest<br/>切换到日程"]
  MT -->|清除筛选| C2
  MS --> MQ["MacScheduleDetailView<br/>消费并清空请求<br/>复用 prepareQuickAdd 预填分类并聚焦标题"]
  MQ --> B
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
  M --> N["AnalyticsView / MacAnalyticsDetailView<br/>普通预览或 Pro 完整报表<br/>分类投入排序依据/排行/次数/空态语义/元信息和占比可读性<br/>iOS计划回顾分类badge和语音语义"]
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

## 目标驱动迭代流程

读图说明：一个会话直接完成规划、开发、自查和结果核对，`work.md` 随步骤更新以便压缩后接续。纯文档只静态审阅；需要运行的验证默认在云端，并先按任务范围确认入口。现有完整 workflow 尚无按任务 profile，不能把计划选择误称为已实现自动裁剪。

```mermaid
flowchart TD
  GOAL[用户目标与约束] --> READ[读取AGENTS和work / 核对Git与相关源码]
  READ --> PLAN[work记录目标 / 非目标 / 验收 / 小步骤 / 文件范围]
  PLAN --> EDIT[当前会话小步实现与静态自查]
  EDIT --> TRACK[即时更新work进度 / 决策 / 风险 / 下一步]
  TRACK --> SELECT[按本轮编辑及依赖选择baseline和direct / 按需optional]
  SELECT --> DOCS{仅无需运行验证的Markdown}
  DOCS -->|是| STATIC[内容 / 链接 / diff审阅 / 不运行产品CI]
  STATIC --> DOCCOMMIT[仅文档提交 / skip ci标记 / push main]
  DOCS -->|否| ENTRY{已有匹配任务范围的云端入口}
  ENTRY -->|否| GAP[记录入口缺口 / 补充定向入口或请用户决定扩大范围]
  GAP -->|入口补齐| ENTRY
  GAP -->|需人工决策| WAIT[保留work / 报告阻塞和可执行下一步]
  ENTRY -->|是| PUSH[仅提交本轮相关改动 / push origin main]
  PUSH --> CLOUD[运行相关云端验证 / 记录真实SHA和run及attempt]
  CLOUD --> RESULT[当前会话核对日志 / 必要产物 / 实际行为]
  RESULT --> PASS{必要验证与目标都满足}
  PASS -->|否且可修复| FIX[解释失败并追加相关修复 / 不回滚或掩盖失败]
  FIX --> EDIT
  PASS -->|阻塞| WAIT
  PASS -->|是| DONE[更新长期日志 / 交付改动与真实验证及遗留项]
  DOCCOMMIT --> DONE
  DONE --> CLEAR[清空work当前任务正文 / 保留文件与空闲状态]
  TRACK -.上下文压缩或恢复.-> READ
```

## 完整产品链与独立证据核对

读图说明：这张图仅描述当前已接线的完整产品 workflow，不代表每个小任务都应执行。它在生产 push 后自动带出全部 UI/Release 矩阵；只需要定向验证时必须先有真正支持的入口。正式 review 仍在只读 Actions 中执行，不在本机运行 validator，也不要求另一个模型或角色接手。

```mermaid
flowchart TD
  PUSH[需要完整产品验证的main push] --> CI[ci-results / 固定静态检查与项目验证 / Mac和iOS构建]
  CI --> PACKAGE[manifest / index / stage / JUnit / 日志 / xcresult / 正式快照]
  PACKAGE --> FINAL{包阶段成功}
  FINAL -->|是| UPLOAD[上传唯一未加密生产包 / 保留真实job结论]
  FINAL -->|否| RECOVER{恢复一致fallback包成功}
  RECOVER -->|是| UPLOAD
  RECOVER -->|否| NOART[不上传陈旧目录 / 保留失败与原始日志]
  UPLOAD --> EVENT[生产workflow completed]
  EVENT --> REVIEW[只读独立review / checkout前核对来源和当前main]
  REVIEW --> API[原始run与artifacts API / 全新目录 / 包外证据]
  API --> ZIP[独占part下载 / size与摘要及安全ZIP校验 / 原子晋升]
  ZIP --> EXTRACT[全新extracted / 不执行解包内容]
  EXTRACT --> VALIDATE[仅Actions正式第四模式 / 完整archive与两份metadata / 目录绑定]
  VALIDATE --> FRESH[最终复查main与源attempt / 漂移即stale]
  FRESH --> EVIDENCE[独立review证据包 / source与review双身份 / 上传成功才接受]
  EVENT --> SUCCESS{授权生产push成功}
  SUCCESS -->|是| UI[当前固定完整矩阵 / Mac / ios-390 / ios-375 / Release]
  UI --> UIART[相关原生与渲染证据 / 双身份与上传前后freshness]
  EVIDENCE --> CHECK[当前会话核对真实结论 / 必要日志和截图 / 不用旧结果冒充]
  UIART --> CHECK
  CHECK --> OUT[产品通过 / 失败 / stale分别报告]
  INJECT[仅相关安全链任务显式受控dispatch] --> CI
  INJECT -.注入身份与真实日志复判.-> VALIDATE
  OUT -->|受控失败| FAILURE[失败证据链通过不等于产品通过 / 不自动降级失败push]
```
