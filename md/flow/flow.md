# 项目核心流程文档

## 0. 一句话总览

ChronoFocus 的主链路是：用户在 iOS App 或 macOS 状态栏 App 操作番茄钟/日程 -> `FocusStore` 保存设置、任务、计划、会话和活跃快照 -> `TimerEngine` 按真实系统时间驱动计时 -> 平台服务负责通知、Live Activity/占位、日历和 Pro -> SwiftUI 渲染。

开发链路是：用户目标 -> 当前会话在 [work.md](../../work.md) 规划 -> 小步实现与自查 -> 按改动选择必要云端验证 -> 自行核对真实结果 -> 交付并清空当前任务记录。默认禁止本机编译和测试；纯文档不触发产品 CI，历史提示词不再是前置条件。

## 1. 当前核心数据流

iOS主题和基础面板位于`AppTheme.swift`，计时上下文与倒计时位于`TimerPresentation.swift`。展示组件只接收Engine/Store派生的值，不拥有计时或持久化状态；TimerView继续发起所有计时动作。Dashboard与Debug编辑保护容器仅接收同一Engine引用发出生命周期命令，不订阅其每秒输出；真正计时页面继续通过环境对象观察Engine。两端面板按系统减少透明度/增强对比度环境渲染，计时数字、Mac小窗和按钮动画尊重减少动态效果。iOS队列标题/分类/时间完整换行，进度和轮次独立显示，Mac详情队列启用已有完整换行行组件。iOS统计大字号改为单列，编辑器仅通过FocusState管理键盘，提交前收起输入焦点，保存保护和草稿保留逻辑不变。

v1.10待办管理：两端View持有TaskListStatus、查询与删除确认瞬态；共享TaskListFilter先按完成状态和可选分类筛选，再用固定POSIX规范化的多个词匹配标题/分类，保留输入身份和顺序，不写Store。iOS先取当前日期范围，Mac待办面板取全部任务；分类计数反映当前状态和任务查询，日历格仍仅按原日期/分类统计。完成/恢复仍调用toggleTaskDone；iOS卡片更多与两端确认最终调用Store删除，确认时复查活动身份，删除实际成功后才取消提醒，不删除FocusSession。

Mac分类筛选网格把长名称限制为两行并尾部截断，完整名称仍由help、辅助功能label和原搜索提供；已有分类表单维持两行并补help。此高度边界只作用于选择控件，任务正文和日历任务仍完整换行，不改变分类身份、计数、筛选或持久化。

iOS日程使用inline导航，任务搜索从待办标题旁展开，分类查询独立按需展开，收起分类查询只清除查询而保留选择。两端删除采用原生alert，提供明确取消与删除动作。原生构建/启动、测试、原始结果收集分别作为10/14/5分钟云端步骤，构建与boot并行，双成功记录UDID，测试复核同一UDID并保留真实状态；独立always收集导出summary/tests/attachments和执行verifier，失败摘要随后生成。短生命周期实际测试先承担冷自动化启动，不重跑失败；总job35分钟及单测限制保持。

TimerEngine自然到点经incrementActiveTaskRound、手动结束经finishActiveTask完成原任务；只有Store成功返回已完成任务时才取消其到期提醒。循环生成后的返回对象按原ID查找，不能用已漂移的数组index。自由专注没有任务ID，不取消其他任务提醒；计时完成通知仍由原cancelNotification处理。

保存成功才清除旧任务查询并显示保存后的状态；iOS同时对齐所选分类和日期，无日期任务回到创建日的日范围，取消不触发此回调。Store拒绝保存时编辑器保持草稿并显示原因，不触发提醒或父级定位。Mac快速新增成功后回到未完成状态，日程任务正文/管理动作分层，标题和分类允许完整换行。循环完成创建下一期后，三个Store完成入口按原ID返回任务，提醒取消和TimerEngine完成处理不会拿到新一期。原生当前每设备10条、40具名场景。Debug根fixture仅在显式测试分支呈现真实编辑器并经Engine使该任务变活动；自动开始时钟本身另由共享core验证。证据同时核对xcresulttool测试树的唯一10测试及逐项Passed/设备/耗时、summary和附件场景；失败也保存逐测试诊断表到独立证据和Actions Summary，不能用诊断代替接受条件。Mac独立17图含完成检索与1100pt双列长文本，生产唯一包与正式五图不变。initial gate失败的fallback包名也包含平台，保留独立失败现场。这些证据仅在执行对应验证时采集，不能代替新提交的必要验证。

原生寻找和对齐均从外层10pt留白发起限幅垂直拖动，避免嵌套Picker/横向分类条截获手势；每次至少32pt以跨过滚动识别阈值，最大幅度仍按视口和阶段限幅。revealInsideViewport把目标纠正到实时导航栏与TabBar之间，仍检查真实可达性和尺寸。日历标题/范围在辅助字体纵排，今天保持一行，新增原生标题高度和日历场景。独立Release保存真实ICNS并用系统sips解码兼容图，再通过Assets.car的assetutil原文绑定同CFBundleIconName的1024×1024编译图；失败保留诊断，不能以源PNG或构建成功代替资源验证。

v1.9展示与证据：iOS日程待办的标题/分类/时间和动作分层，标题与分类完整换行，三个带文字动作在较大字体下纵排，仍由原闭包调用Store或发出一次性handoff；不增加状态机或持久化。设置按时间、后台提醒、自动化、声音、Pro、隐私排序。原生实心按钮从实际主题填色调用共享对比色算法，分类原始色和已有badge规则保留。

原生云端准备创建指定测试设备并发起boot；测试脚本并行等待有界bootstatus与build-for-testing，两者均成功才test-without-building。当前十个实际测试的tests树、summary与附件manifest按测试身份、40个场景、UDID和完整像素尺寸绑定，不接受只靠总数的证明。完整测试树及构建/启动/测试日志独立保留。生产checkout固定触发github.sha；Release实际读取Mac ICNS与编译图标资源，独立证据结构与来源门禁保持。

v1.8平台边界：两日历服务先拒绝并发同步，再经共享`CalendarReadAccessGate`读取真实授权。fullAccess允许读取，notDetermined/writeOnly请求完整访问后同时核对返回值和刷新状态，denied/restricted/unknown拒绝；异常也刷新平台状态。只有允许后才查询EventKit并通过既有Store导入。Live Activity锁屏/灵动岛共用`ActivityCountdownText`，暂停显示非负快照值，运行中只对未来日期构造`futureCountdownRange`，到点/过期显示00:00而不创建倒置区间。

iOS设置通知卡片把状态说明与授权动作纵排，动作占满卡片内容宽度，避免说明文字挤空按钮；实际授权/系统设置跳转仍委托NotificationService。普通浅色与辅助大字体暗色原生测试覆盖同一入口，保留具名原生附件供实际读图核对。

原生UITest控件寻找按实际frame选择滚动方向，空frame采用有界双向搜索；保存后任务位于当前视口上方也必须重新变为可点击，不能仅以元素存在替代实际可达性。寻找失败保存原生截图供退回定位。

发布证据扩展为同一UI workflow的release矩阵项：验证源身份后checkout当前源SHA，双端Release构建后从真实App/appex核对隐私资源、身份/版本/最低系统/架构和Debug入口缺失，再绑定source/UI两套身份与freshness上传独立包。该工程检查没有签名发行能力，报告保留distributionReady=false；生产结果包与第四模式结构不变。

v1.7展示派生：Mac详情与popover读取同一`store.settings.appThemeMode`；MacTheme按原生appearance提供背景、面板、正文、次要文字、边框和轨道，浅色强调文字单独加深，选中填色保留原分类色和共享对比文字。Mac筛选和快速新增从完整搜索结果再经`CategoryOptionPresentation`派生默认6/4项；非空查询显示全部匹配，当前选择从完整来源查找并在前缀/匹配之外单独保留，匹配计数不使用可见前缀。展开仅为View状态，查询/分类/选项身份变化恢复收起，iOS保留原横向栏。

v1.5展示层：iOS计时依次呈现当前任务、模式/倒计时、主控、任务队列、可折叠提醒、今日统计。辅助大字体使用线性计时摘要，主控文字随开始/暂停/继续和专注/休息改变，仍调用TimerEngine原入口。日程把待办放在计划/同步前。Mac两页使用`MacAdaptiveColumns`按实际内容宽度测量；低于780pt时纵排，计时主区在前、日程待办区在前。布局切换不复制或重建核心状态，真实/快照只在原生控件替身上分支，内容顺序一致。

分类筛选先由 `prioritizedFilterOptions` 生成原顺序/计数/颜色，再由 `TaskCategorySearchResult` 按共享 query key 过滤。至少 6 类显示搜索；少于 6 类忽略隐藏 query。匹配数不包含单独的 `pinnedSelection`；未匹配但仍存在的选中分类显示为“当前已选”，选中分类不存在时仍可由“全部”或已有摘要清除。query 仅由各 View 持有，不写 Store、不改变选择/任务/计划。iOS 两个筛选栏共用输入控件，Mac 两页共用自适应网格；快照环境只提供查询初始值，过滤逻辑一致。

```text
用户操作 / 系统日历 / App 恢复
  -> SwiftUI View 或平台入口
  -> FocusStore 读写模型
  -> TaskCategoryPreset / FocusStore 派生分类比较键、代表色与对比文字色
  -> TimerEngine 处理计时状态
  -> TimerNotificationServicing / TimerLiveActivityServicing
  -> UserDefaults JSON 持久化、通知、Live Activity、Mac 状态栏、SwiftUI 渲染
  -> scripts/test_mac_core.swift 和 scripts/render_mac_snapshots.swift 由 GitHub Actions 验证核心逻辑与 UI 快照
  -> GitHub Actions ci-results.yml 上传可追溯结果包，由当前会话读取云端独立 review 的结论
```

核心数据对象：

- `TimerSettings`：专注/休息时长、长休间隔、通知、Live Activity、铃声音量、到点音色、振动、常亮、自动计划、自动流转、主题。
- `FocusTask`：日程任务、分类、截止时间、预计轮次、完成轮次、启用状态、自动开始、开始模式、循环、外部日历 ID。
- `TaskCategoryPreset` / `TaskCategoryFilterOption`：常用分类和筛选项的非持久化元数据，提供标题、代表色、对比文字色、图标、当前计数、筛选排序、再次点击已选分类退出筛选、分类输入上下文、预设按钮和筛选 chip 的可访问状态/动作提示、selected trait 和 Voice Control input labels、iOS/Mac 日程日期格的日期/待办数/已选中/非本月语义和 Voice Control input labels、未筛选全量日期计数与选中分类日期计数的共同上下文、iOS 日程筛选计数、iOS 日程 toolbar 新增入口分类语义、iOS/Mac 日程分类空态新增/清除操作、iOS 待办保存/取消按钮任务/分类/动作语义、iOS 日程任务行分类 badge 和 Voice Control input labels、iOS/Mac 日程任务行操作按钮任务名和分类语义、iOS/Mac 计时主控按钮任务名和分类语义、iOS/Mac 计划项开始按钮任务名/时间段/轮次语义、iOS/Mac 计划项分类 badge、iOS/Mac 计划面板生成/清空操作当前轮数语义、Mac 快速新增任务名称输入框分类上下文、提交按钮分类/轮次语义、Mac 小窗快捷面板按钮动作和选中状态语义、Mac 计划项可见分类上下文、统计页分类投入占比、专注次数、排行位置、排序依据、空态、元信息可读性、占比可读性和分类/时长/占比可访问语义、iOS 统计页计划回顾分类 badge 与任务/分类/开始时间/轮次语义、计时页当前待办筛选摘要、计时页分类摘要清除入口、计时页分类空态清除入口、计时页分类 badge 可访问标签和 Voice Control input labels、iOS/Mac 当前任务选择行的 selected trait、选择/运行中提示和任务名/分类名 Voice Control input labels、Mac 任务行和小窗分类 badge 预设色兜底与 Voice Control input labels、选中分类摘要快捷新增、摘要新增/清除按钮分类语义、摘要动作可访问提示和分类上下文新增提示；代表色由预设优先、首个任务、session-only/fallback 的统一规则派生，选中背景文字按 `contrastTextHex(on:)` 比较实际 `#FFFFFF` / `#111827` 的 sRGB 相对亮度与对比度选择（平局选白，不保证任意背景均达 4.5:1），真实分类仍保存为 `FocusTask.category`。
- `FocusSession`：已记录的专注/休息会话，用于统计和报表；`category` 会在统计最近记录中显示为分类 badge，并进入整行可访问标签与 Voice Control input labels；完成的专注会话也会按分类聚合成分类投入的时长、占比、排序依据、排行位置和专注次数；没有分类统计时，统计页分类投入空态会提示完成带分类的番茄钟。
- `PomodoroPlanItem`：由日程生成的计划项，可直接启动专注。
- `ActiveTimerSnapshot`：正在运行或暂停的计时快照，用于跨前后台和重启恢复。
- `CompletionSound`：到点提示音选择，非默认音色属于 Pro。

## 2. 当前核心执行流

### 2.1 App 启动

FocusStore启动只加载已有JSON或模型默认值；没有任务时保持空列表，不再因tasks/sessions为空写入演示任务。已保存的旧任务不迁移、不删除；解码失败回退为空展示，原始任务JSON不在加载阶段被覆盖。空列表仍可从TimerEngine开始自由专注。iOS Debug显式UI测试flag才切入隔离suite并种确定性fixture；正常/Release使用.standard。

iOS：

- `ChronoFocusApp` 创建 `FocusStore`、`NotificationService`、`LiveActivityService`、`PremiumAccessService`、`CalendarSyncService` 和 `TimerEngine`。
- SwiftUI 根视图通过环境对象使用这些服务。
- `TimerEngine` 初始化时从 `FocusStore.activeTimer` 恢复活跃计时。
- `DashboardView` 启动和回到前台时刷新 Pro 权益，非 Pro 状态会把持久化的 Pro 音色回退为 `.chime`。

macOS：

- `ChronoFocusMacApp` 通过 `MacAppDelegate` 启动。
- App 设置为 accessory，无 Dock 图标。
- 创建 `FocusStore`、`MacNotificationService`、`MacPremiumAccessService`、`MacCalendarSyncService`、`MacLiveActivityService` 和 `TimerEngine`。
- `MacStatusBarController` 创建状态栏项目，菜单栏显示 `engine.formattedRemaining`。
- 左键打开 `MacMiniTimerView` popover，快捷面板可直接进入日程、统计或设置详情；右键显示开始/暂停、打开计时详情、退出菜单。

### 2.2 开始计时

1. 用户从计时页、小窗或计划项触发开始。
2. `TimerEngine.start()`、`TimerEngine.startPlanItem(_:)` 和 `TimerEngine.selectTask(_:)` 通过 `FocusStore.startableTask(for:)` 复核当前可启动任务；失效的计划项不启动，空闲失效选择回到自由专注。
3. `TimerEngine` 创建 `ActiveTimerSnapshot`，写入 `FocusStore.activeTimer`；运行中 iOS/macOS UI 读取快照 `tintHex`，不因任务编辑而改变当前会话颜色。
4. `FocusStore` 自动将快照编码为 JSON 写入 `UserDefaults`。
5. `TimerEngine` 启动 1 秒 ticker，更新 `remainingSeconds` 和 `progress`。
6. 平台通知服务调度完成提醒。
7. iOS Live Activity 启动或更新；macOS 使用 `MacLiveActivityService` 占位实现。
8. SwiftUI 视图和 Mac 状态栏通过 `ObservableObject` 状态刷新。

### 2.3 暂停、恢复、停止

- 暂停：`TimerEngine.pause()` 计算剩余秒数，写入 `remainingWhenPaused`，取消完成通知，更新 Live Activity。
- 恢复：`TimerEngine.resume()` 根据暂停剩余秒数重算 `endAt`，重新调度通知并启动 ticker。
- 停止：`TimerEngine.stop(markIncomplete:)` 取消通知和 Live Activity，必要时记录未完成会话，然后清空 `activeTimer`。
- 活动任务保护按 `activeTimer.taskID` 判定，运行和暂停期间的编辑、停用/完成切换及删除请求被 Store 拒绝或过滤；视图继续读取快照身份、标题、分类和颜色。停止后恢复正常修改入口；停用/删除经既有异步观察进入 `reconcileIdleSelectedTask()`，失效选择回到自由专注，仍可启动的合法编辑保留选择并刷新上下文。
- `deleteTasks(ids:)` 先过滤活动 taskID，再核对是否实际命中可删任务或非活动计划项的 taskID；都未命中则在任何数组写回/persist/regen 前返回。纯活动/空/unknown 请求无副作用，不重生自动计划；mixed batch 与仅命中非活动计划项的合法删除仍沿用计划重生成，ids 不代表计划项自身 UUID。guard 与 autoGenerate=true 完整数组回归已落盘，尚未云端验证。

### 2.4 完成与自动流转

1. ticker 发现 `remainingSeconds <= 0`，进入 `completeCurrentSession(playSound:)`。
2. 记录 `FocusSession(completed: true)`。
3. 如果完成的是专注轮次，调用 `FocusStore.incrementRound(for:)` 更新任务和计划项。
4. 若任务完成，取消任务到期提醒。
5. 根据 `TimerSettings.completionSound`、音量和振动设置播放 App 内提示；iOS 和 macOS 都由平台通知服务生成对应音色。后台系统本地通知仍使用系统默认通知声。
6. 结束 Live Activity，清空 `activeTimer`。
7. 根据 `roundsBeforeLongBreak` 计算下一模式。
8. 若 `autoStartBreaks` 或 `autoStartFocus` 启用，则自动开始下一段。

### 2.5 日程与计划

1. 用户创建、编辑、启用/停用、完成或删除 `FocusTask`。
2. 新增/编辑 UI 可用 `TaskCategoryPreset` 快速填入分类和代表色，也可继续手写分类。iOS `TaskEditorView` 与 macOS 快速新增顺序遍历 `FocusStore.taskCategories`，用固定 POSIX locale 对清理后的名称执行大小写、变音符号和宽度不敏感比较，排除预设并按首次出现去重，形成“已有分类”；达到 6 项时以独立瞬态查询做同规则名称子串过滤，显示结果数/总数、清除和无结果状态。搜索只改变可见 option，不修改 `category` / `accentHex`。点击已有分类只更新这两个 View 草稿；共享代表色遵循预设优先、首个同类任务可用颜色、session-only/fallback 的顺序，不调用保存入口、不新增持久化。当前项以 checkmark、轮廓和 selected trait 表达，再次点击不清空；自由文本、5 个预设和保存/取消语义保持不变。
3. 选中分类筛选后 toolbar 新增入口会读出当前分类并支持按分类 Voice Control 新增，新增待办会预填该分类；再次点击已选分类、点击“全部”或摘要清除会退出筛选；分类 chip 的可访问标签会读出数量、已选中状态和点击后的筛选/清除动作；iOS 待办标题显示筛选数/总数，日程任务行以带分类名 Voice Control input labels 的分类 badge 保留分类上下文，完成/启用/编辑操作会读出任务名；iOS 当前范围没有该分类待办时，分类空态会直接提供新增此分类和清除筛选操作；macOS 完成/启用/删除操作也读出任务名，避免长列表中误操作；列表摘要可直接新增此分类待办或清除筛选，摘要和按钮可访问标签也会说明新增/清除动作及分类名；macOS 计时队列选中分类且结果非空时显示常驻分类上下文条、筛选数/总数和新增/清除动作，窄宽时动作纵排；筛选态任务行隐藏重复视觉 badge，但整行继续读出任务名、分类名、选中/运行状态与操作提示，未筛选态和其他页面仍显示 badge。macOS 计时队列以完整分类筛选结果计算计数、上下文和空态，默认展示前 7 项，超过 7 项时可展开全部或收起；分类切换、完整筛选结果数量变化、筛选清除和 handoff 都恢复收起，运行中仍可展开浏览但任务行不可切换，toggle 保持 44pt 并提供两态 VoiceOver/Voice Control 语义。macOS 选中分类且无未完成待办时，空态本身也可新增此分类或清除筛选；macOS 选中分类摘要可把左侧快速新增表单切回当前分类并聚焦任务名称，任务名称输入框会读出当前将新增到的分类并支持按分类 Voice Control 输入，摘要新增/清除按钮也暴露分类名 Voice Control input labels，快速新增面板显示当前分类，筛选预填时保留“已预填”语义，提交按钮会读出当前分类和预计轮次，连续新增时保留刚创建任务的分类；编辑已有待办仍保留原任务分类。
4. macOS 日历面板当前范围没有待办时，空态可把当前选中日期传回父视图；父视图保留快速新增截止时间的时分，只替换年月日并聚焦任务名称，任务仍通过现有 `addTask()` 写入 `FocusStore`。
- iOS `ScheduleView.taskCount(on:)` 和 macOS `MacCalendarPanelView.taskCount(on:)` 都先按 `dueDate` 与日期格匹配自然日，再应用可选 `selectedCategory` 谓词；周条、月格、日历范围列表和日期格 label 因此共享同一筛选上下文。macOS 日历面板通过父级 binding 接收分类，视觉计数与 accessibility label 共用同一派生计数，清除筛选即恢复全量计数；范围列表仍用完整 `visibleTasks` 计算总数、日期格和空态，只从中派生默认前 4 项，超过 4 项可展开/收起，分类、日期、范围或结果变化恢复收起，不新增持久化或计时状态。
5. `FocusStore` 清洗空白分类、合并常用分类和已有分类为 `taskCategories`，供 iOS/macOS 筛选 UI 使用。
6. `TaskCategoryPreset.prioritizedFilterOptions` 按当前范围内任务数量把有任务的分类排在空分类前面。
7. `FocusStore` 保存任务，并在 `autoGeneratePomodoroPlan` 启用时调用 `generatePomodoroPlanFromSchedule()`。
8. `upcomingTasks()` 保留未完成停用任务供日程管理；`startableTasks()` 在其排序结果上排除停用任务，供计时队列、计划启动和日程接力共享。
9. 计划按未完成任务、截止时间、剩余轮次和休息规则生成 `PomodoroPlanItem`。
10. 用户可从计划面板按日程生成或清空计划，操作语义会读出当前未完成轮数；用户也可从计划项直接开始专注，计划项会以分类 badge 显示分类上下文，计划开始按钮会读出任务名、时间段、轮次和分类，`TimerEngine.startPlanItem(_:)` 会在最终复核通过后标记计划开始并启动计时。
11. 循环任务完成后，`FocusStore.createNextRecurrenceIfNeeded(from:)` 创建下一周期任务。
12. 外部日历同步通过 `upsertExternalTask(...)` 合并到任务列表。

### 2.6 统计与 Pro

- `FocusStore` 从 `sessions` 计算今日专注、7 日趋势、分类投入时长/占比/排序依据/排行位置/专注次数、最近记录和工作压力。
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

职责：接入通知、声音/音色/振动、Live Activity、StoreKit、EventKit。

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
- Mac 快照测试通过脚本编译 Swift 文件并使用 `ImageRenderer` 渲染，不等同于完整 App 运行；快照路径用 `macSnapshotRendering` 替换原生 `Picker`、`Toggle`、`Slider`、`DatePicker`、`Stepper` 和部分 bordered/prominent `Button`，日程摘要静态动作按钮保持与真实按钮一致的稳定宽高，避免黄色缺失控件占位和按钮尺寸回退。

## 5. 用户入口

iOS：

- 计时页：按分类筛选当前待办、再次点击已选分类退出筛选；非空筛选摘要显示分类名、筛选数/总数和新增/清除双操作，无结果时只显示原有双操作空态。新增动作复用现有 `TaskEditorView(initialCategory:)`，保存后筛选保持并由 `FocusStore` 派生数据刷新计数。筛选态隐藏任务行重复视觉 badge，但任务名、分类、selected trait、选择/运行中提示和 Voice Control input labels 独立保留；计时主控继续读出当前任务名和分类，支持选择任务、开始/暂停/恢复/跳过及调整铃声/振动/常亮和主题。
- 日程页：日历/待办、日期格语义、分类筛选/摘要/空态、任务操作、计划和日历同步；新增/编辑保留自由文本与 5 个预设，并从 `store.taskCategories` 显示稳定去重的非预设“已有分类”。至少 6 项时提供瞬态名称搜索、结果计数、清除和无结果状态；搜索只过滤 option，选择时只修改草稿并复用首个同分类任务代表色。已有分类项提供非颜色选中状态、至少 44pt 点击高度、VoiceOver 和 Voice Control，保存仍统一进入 `FocusStore.addTask/updateTask`。
- 统计页：Pro 预览、购买、报表和分析；最近记录显示分类 badge，整行读出任务、分类、模式、开始时间、时长和完成状态，并支持任务名/分类名 Voice Control 输入标签；日程计划回顾计划项显示分类 badge，整行读出任务、分类、计划开始时间和轮次，并支持任务名/分类名 Voice Control 输入标签。
- 设置页：时长、通知、Pro、App 内到点音色选择/试听、日历、主题等设置；非 Pro 不能持久保留 Pro 音色。
- Live Activity：锁屏、通知栏和灵动岛倒计时。

macOS：

- 菜单栏时间胶囊：显示剩余时间。
- 左键 popover：极简计时器、动态进度条、带分类名可访问标签、Voice Control input labels、已选中状态、选择提示、运行中不可切换提示和任务名/分类名语音标签的当前待办分类 badge/时间上下文、可读出按钮动作和当前选中状态的快捷面板，并可直接打开日程、统计或设置详情页。
- 右键菜单：开始/暂停、打开详细界面、退出。
- 详细窗口：计时、日程、计划、统计和设置；快速新增保留自由文本、5 个预设和分类预填，并从 `store.taskCategories` 显示与 iOS 相同算法的“已有分类”。长列表搜索与 snapshot rendering 共享过滤 option，外部分类预填先清除旧查询；选择已有分类只更新快速新增草稿并复用首个同分类任务代表色。提交仍走现有 `addTask()`，连续新增、筛选摘要、任务操作和计时语义保持不变。
- 日历范围列表：完整当前分类结果继续用于范围计数、日期格和空态，默认显示前 4 项；超过 4 项时提供带剩余数量的展开/收起按钮，分类、日期、日/周/月范围或结果变化会恢复收起，按钮和快照静态路径保持至少 44pt 及辅助功能语义。

## 6. 前端、业务、模型与验证的关系

- SwiftUI View 只收集意图、展示 Store/Engine 投影，持有分类、查询、展开和编辑草稿等瞬态；不绕过 Store 写持久化，不制造第二套计时状态。
- `FocusStore` 负责模型清洗、任务/计划/会话和活跃快照保存，并为日期格、任务列表、计时队列和统计提供一致的派生数据。
- `TimerEngine` 消费可启动任务，维护恢复、暂停、完成和自动流转，调用平台协议并把结果写回 Store。
- 共享模型和辅助策略不依赖 AppKit/UIKit/EventKit 平台类型；平台服务只实现对应能力。
- `scripts/test_mac_core.swift` 验证共享行为，`scripts/render_mac_snapshots.swift` 生成 Mac 渲染证据，原生 UITests 负责真实交互；源码 marker 只作为结构合同，不代替行为或视觉结论。
- `scripts/verify_project.sh` 是包含 core、渲染和结果包合同的组合入口，不是每轮必跑的轻检查。测试范围按 [测试规范](../test/test.md) 选择。
- 当前生产 workflow 是固定完整链，包含七个业务阶段和包阶段；manifest/index/stage/JUnit/outcome/required 产物互相绑定。finalizer 失败由恢复脚本重建一致 fallback 包，恢复失败不上传陈旧目录。
- 完整包由独立 Actions 执行 validator 第四模式，使用包外原始 run/artifact API、ZIP 与目录绑定；validator 不联网且不在本机运行。安全合同统一在测试规范维护，避免入口重复堆叠逐版 PASS 清单。

## 7. 目标驱动迭代与云端验证

### 7.1 开始与接续

1. 读取 `AGENTS.md`、`work.md`、Git 状态和最近提交，按任务读取源码、flow/test 及相关 workflow；不通读整个历史 prompt 栈。
2. 保留已有改动，安全同步 `origin/main`；在 `work.md` 写目标、非目标、验收、分步计划、本轮文件范围和验证选择。
3. 当前会话自行规划、实现和复查，不设置角色召唤、阶段交接或强制版本提示词，默认不启动子智能体。
4. 完成步骤、调整方案、发现失败或准备压缩上下文时更新工作台；恢复后核对源码、Git 和云端状态，不只依赖勾选项。

### 7.2 按范围验证和修复

1. 本机只静态阅读、diff/路径核对及 Git/gh 操作；编译、测试、配置解析和 validator 默认仅云端执行。用户明确授权本机时，iOS 仅使用现有 `FAC4325D` 前缀的唯一模拟器，云端不受此限制。
2. 按本轮实际编辑与依赖选择 `baseline + direct + optional`，解释每项关联，不因历史清单或其他会话改动扩大测试。
3. 纯 Markdown 且不影响可执行配置/fixture 时，不触发产品构建、UI、Release 或 validator；仅此类推送使用 `[skip ci]`。必要代码验证不能借此跳过。
4. 当前 `ci-results.yml` 仍是固定完整产品链，成功 push 还自动触发独立 review 和四项 UI/Release 矩阵；没有已实现的按任务 profile。入口过宽时先记录缺口并补充相关定向入口或取得扩大范围的明确决定，不默认运行无关 CI。
5. 需要云端验证时，仅提交本轮相关改动并 push `origin/main`，跟进相关源 run、独立 review 和必要专属证据，核对最新 SHA/run/attempt 与实际执行结果。
6. 失败先读日志和证据，区分代码、合同或环境原因，保持失败结论，在 `main` 追加相关修复；不回滚、不自动重跑掩盖失败、不降级 profile 冒充成功。

### 7.3 完整包的独立 review

完整生产结果包的安全链保持现有接线，不再依赖额外人工角色：

- `ci-artifact-review.yml` 只响应生产 completed 事件，checkout 前核对源 workflow/run/event、授权账号与仓库、当前 main 和 profile，再 checkout 已核对的 SHA；仅 `contents: read`、`actions: read`，不持久化凭证或执行解包代码。
- `scripts/review_ci_artifact.py` 在全新目录保存原始 API 与 ZIP，以 `.part` 无覆盖下载、size/digest/安全结构校验和原子晋升建立包外证据，`extracted/` 与原文隔离。
- 仅在 Actions 传完整 archive、artifact metadata、run metadata 和目录执行正式第四模式，下载前和结论前再核对 main/源 attempt，漂移即 stale。
- 产品成功与显式受控失败证据链通过分开，失败 push 不降级；受控注入只用于该安全链的相关任务，不是每轮前置条件。
- 独立 review evidence 绑定 source/review 两套身份，上传失败或缺证据不能通过。当前会话通过 gh 读取结论并核对实际实现、必要截图和日志，本机不复跑 validator。

完整参数、安全约束和系统服务边界见 [测试规范](../test/test.md)，不在此复制逐版历史结果。

### 7.4 收口与停止

- 目标及必要验证都满足才交付完成；长期结论写 `update_log.md`，最终回复说明提交、真实验证、未执行项和风险，然后清空 `work.md` 的任务正文并保留文件。
- 只改受影响的稳定文档，不为了写入自身 SHA/run 制造文档提交和完整 CI 的递归循环；文档不把旧结果当新结果。
- 未完成、CI 待结束或用户暂时中断时保留工作台；权限、密钥、付费选择、归属不明冲突或同一阻塞连续三次无新进展时停止重复尝试并报告下一步。

## 8. 稳定约束

- Mac 复用共享业务，`TimerEngine` 是唯一计时状态机，`FocusStore` 是唯一核心仓库，新字段向后兼容。
- iOS/macOS 的 Pro 商品 ID 语义一致，系统能力通过平台服务边界实现。
- Mac 快照无黄色缺失控件或内容区域空白；截图数量、非空或构建成功不能替代实际视觉审阅。
- 本轮未跑的真实服务、真机和发行验证如实说明，不把 `distributionReady=false` 写成正式发布通过。
- 当前代码与配置决定实际行为，历史 prompt 和单次验证记录不覆盖当前规则；文档只在对应职责变化时更新。

## 9. 未来扩展点

- 在平台服务边界补充真实系统服务失败路径的测试替身，不伪造购买或授权结果。
- 根据真实任务增加必要的定向云端验证入口，避免完整链成为所有小改动的默认测试。
- 功能稳定且任务确有需要时，再按职责拆分过长 SwiftUI View；不顺手大重构。

## 10. 不允许破坏的行为

- 活跃计时通过 `ActiveTimerSnapshot` 跨重启与前后台恢复。
- 完成专注记录会话、更新任务轮次和计划项，并只取消对应原任务提醒。
- 自动计划基于未完成且启用的任务，日历导入仍通过 Store 参与计划和统计。
- 通知、声音、振动受 `TimerSettings` 控制。
- Mac 保持状态栏应用形态，不显示 Dock 图标。
- 现有组合验证和结果包安全合同继续有效，但是否执行及执行范围由本轮改动和必要依赖决定。
