# 项目版本更新记录

本文记录 ChronoFocus 的正式版本、重要维护事项、关键决策和遗留问题。它不是流水账；只有影响项目行为、架构、测试、文档体系或后续协作方式的事项才写入。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新产品版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。
- 日期使用本地日期，格式为 `YYYY-MM-DD`。

## 当前状态

- iOS 主 App 已具备番茄钟、日程待办、自动计划、统计分析、Pro 内购、系统日历同步、本地通知、Live Activity、铃声/音色/振动、亮暗主题。
- macOS 版已作为状态栏 App 存在，复用共享模型、`FocusStore` 和 `TimerEngine`，提供菜单栏剩余时间、小窗、详细窗口、Mac 通知、Mac 日历同步、Mac Pro 服务和 Mac 快照测试。
- 当前本地项目专属验证入口是 `bash scripts/verify_project.sh`，会检查项目结构、关键实现标记、计时页/日程页分类筛选摘要/预填/排序/快捷新增标记、iOS/Mac 日程日期格可访问语义、iOS/Mac 日程摘要按钮分类语义、Mac 日程摘要按钮点击区、计时页分类摘要清除入口、计时页分类空态清除入口、计时页分类 badge 可访问标签、iOS/Mac 当前任务选择 selected trait、提示、运行中不可切换提示与 Voice Control 输入标签、iOS/Mac 计时主控按钮任务名和分类语义、统计分类投入占比/次数/排行/排序依据/空态语义/元信息和占比可读性、统计最近记录分类上下文、统计计划回顾分类语义、iOS 待办新增/编辑保存/取消按钮分类语义、分类 chip 点击切换、分类输入上下文、分类预设按钮可访问语义、可访问提示、selected trait 和 Voice Control input labels、摘要动作可访问提示、iOS 日程筛选计数、iOS 日程 toolbar 新增入口分类语义、iOS/Mac 日程分类空态操作、iOS 日程任务行分类 badge 与 Voice Control 输入标签、iOS/Mac 日程任务行操作按钮任务名和分类语义、iOS/Mac 计划项开始按钮任务名/时间段/轮次语义、iOS/Mac 计划项分类 badge、iOS/Mac 计划面板生成/清空操作当前轮数语义、Mac 快速新增任务名称输入框分类上下文、提交按钮分类/轮次语义、Mac 小窗快捷面板按钮语义、Mac 计划项分类上下文、分类摘要插入点和动作接线、Mac 待办筛选计数、Mac 任务行和小窗分类 badge 预设色兜底与 Voice Control 输入标签、Mac 分类摘要快捷新增、Mac 连续快速新增保留分类、Mac 分类预填提示、iOS 设置页音色选择、Mac 小窗分类上下文、CI 结果包校验脚本与小型成功、manifest artifactName/overallOutcome 复判、index artifactName 复判、旧 process version 负向、run context 额外字段负向、分类摘要 marker 缺失负向、日程任务操作 marker 缺失负向、计时主控 marker 缺失负向、计划开始 marker 缺失负向、计划分类 badge marker 缺失负向、Mac 计划分类 marker 缺失负向、计划面板操作 marker 缺失负向、日程 toolbar 新增 marker 缺失负向、iOS/Mac 日程分类空态操作 marker 缺失负向、Mac 快速新增 marker 缺失负向、Mac 快速新增标题分类上下文 marker 缺失负向、分类输入上下文 marker 缺失负向、待办保存分类 marker 缺失负向、待办取消分类 marker 缺失负向、Mac 小窗快捷面板 marker 缺失负向、统计分类占比 marker 缺失负向、统计分类投入次数 marker 缺失负向、统计分类投入排行 marker 缺失负向、统计分类投入排序依据 marker 缺失负向、统计分类投入空态 marker 缺失负向、统计分类投入元信息可读性 marker 缺失负向、统计分类投入占比可读性 marker 缺失负向、统计最近记录分类 marker 缺失负向、统计计划回顾分类 marker 缺失负向、JUnit 元数据负向、JUnit errors 负向、JUnit outcome 负向、JUnit failure/error 元素负向、artifactName mismatch 负向、manifest artifactName/overallOutcome 负向、index artifactName 负向、manifest 元数据负向、artifact index 身份错包负向、artifact index totals 篡改负向、artifact index 未预期 entry 负向、额外 artifact 文件负向、本地文件大小篡改负向、本地缺失产物负向 fixture、快照 manifest generatedAt 无效负向 fixture、快照 manifest 大小篡改负向 fixture、run context 精确键集复判、固定 CI process version、分类摘要动作/分类可访问/日程任务操作/计时主控/计划开始/计划分类 badge/Mac 计划分类/计划面板操作/日程 toolbar 新增/iOS 和 Mac 日程分类空态操作/Mac 快速新增和标题分类上下文/分类输入上下文/待办保存分类/待办取消分类/Mac 小窗快捷面板/统计分类占比/统计分类投入次数/统计分类投入排行/统计分类投入排序依据/统计分类投入空态/统计分类投入元信息可读性/统计分类投入占比可读性/统计最近记录分类/统计计划回顾分类 contract 日志复判、Mac 核心测试、Mac UI 快照和快照 manifest generatedAt/byteCount 复判。
- v0.79 起，当前任务选择行分类语义新增独立云端结果包复判：`Current task selection accessibility contracts verified.` 与 `PASS verify_project current task selection accessibility contracts`。
- v0.80 起，分类筛选 chip 再次点击已选分类清除筛选新增独立云端结果包复判：`Category filter toggle contracts verified.` 与 `PASS verify_project category filter toggle contracts`。
- v0.81 起，iOS 统计页日程计划回顾分类语义新增独立云端结果包复判：`Analytics plan review category accessibility contracts verified.` 与 `PASS verify_project analytics plan review category accessibility contracts`。
- v0.82 起，iOS 待办新增/编辑保存按钮分类语义新增独立云端结果包复判：`Task editor save category accessibility contracts verified.` 与 `PASS verify_project task editor save category accessibility contracts`。
- v0.83 起，iOS 待办新增/编辑取消按钮分类语义新增独立云端结果包复判：`Task editor cancel category accessibility contracts verified.` 与 `PASS verify_project task editor cancel category accessibility contracts`。
- v0.84 起，iOS/macOS 统计页分类投入专注次数上下文新增独立云端结果包复判：`Analytics category share session count contracts verified.` 与 `PASS verify_project analytics category share session count contracts`。
- v0.85 起，iOS/macOS 统计页分类投入排行位置语义新增独立云端结果包复判：`Analytics category share ranking contracts verified.` 与 `PASS verify_project analytics category share ranking contracts`。
- v0.86 起，iOS/macOS 统计页分类投入排序依据语义新增独立云端结果包复判：`Analytics category share sort context contracts verified.` 与 `PASS verify_project analytics category share sort context contracts`。
- v0.87 起，iOS/macOS 统计页分类投入空态语义新增独立云端结果包复判：`Analytics category share empty state contracts verified.` 与 `PASS verify_project analytics category share empty state contracts`。
- v0.88 起，iOS/macOS 统计页分类投入元信息可读性新增独立云端结果包复判：`Analytics category share metadata readability contracts verified.` 与 `PASS verify_project analytics category share metadata readability contracts`。
- v0.89 起，iOS/macOS 统计页分类投入占比可读性新增独立云端结果包复判：`Analytics category share percent readability contracts verified.` 与 `PASS verify_project analytics category share percent readability contracts`。
- v0.90 起，macOS 日程快速新增任务名称输入框分类上下文新增独立云端结果包复判：`Mac quick add title field category context contracts verified.` 与 `PASS verify_project mac quick add title field category context contracts`。
- v0.91 起，iOS 日程分类筛选无结果空态操作新增独立云端结果包复判：`Schedule category empty state action contracts verified.` 与 `PASS verify_project schedule category empty state action contracts`。
- v0.92 起，macOS 日程分类筛选无结果空态操作新增独立云端结果包复判：`Mac schedule category empty state action contracts verified.` 与 `PASS verify_project mac schedule category empty state action contracts`。
- v0.93 起，macOS 日历范围空态按当前选中日期准备快速新增、保留时分并聚焦标题新增独立云端结果包复判：`Mac calendar range empty state quick add contracts verified.` 与 `PASS verify_project mac calendar range empty state quick add contracts`。
- v0.94 起，iOS 计时页分类筛选无可启动待办时新增/清除操作新增独立云端结果包复判：`Timer category empty state action contracts verified.` 与 `PASS verify_project timer category empty state action contracts`。
- v0.95 起，macOS 计时待办队列分类筛选/计数/空态跨页新增与声明边界韧性新增独立云端结果包复判：`Mac timer category queue contracts verified.`、`Declaration boundary resilience contracts verified.` 及两个对应 PASS。
- v0.96 已增加 macOS 计时非空分类筛选上下文条、视觉 badge/可访问语义分离、正常和 220pt 云端快照覆盖，并将 CI Action 升级到 `actions/checkout@v5`、`actions/upload-artifact@v6`；最新 `origin/main` 云端 run、artifact、validator 与完整日志已验收通过。
- v0.97 已对齐 iOS 计时非空分类筛选摘要与空态互斥、双操作和视觉 badge/可访问语义分离；artifact validator 已支持可选 archive 三参数全有全无、size/SHA-256/ZIP 三项复判和目录-only 兼容，相关 marker/PASS、部分参数及四类负向 fixture 已接线，最新 `origin/main` 云端 run、原始 ZIP、validator 与完整日志已验收通过。
- v0.98 已实现 iOS/macOS 日程分类非空摘要与分类空态互斥，并让 `Final CI status` 通过 `tee` 将既有 failure summary 同时输出到步骤 stdout 与 Step Summary；新增独立 marker/PASS、`cat` 回退 fixture 和 marker 缺失 fixture。实现 commit `9f26f865ab84c7874763bb3eef59a6a5c513a7c4` 的 GitHub Actions run `30189412591`（attempt `1`）及 Agent C 原始 artifact 复判已通过，validator 为 `99 PASS / 0 FAIL`。
- v0.99 已实现 iOS 计时队列默认 4 项、展开/收起、分类与数量变化重置及运行中只读浏览边界；artifact validator 已增加原始 API JSON 的参数安全、结构化唯一 artifact 复判、八项 metadata PASS、UI/API marker 和含独立零计数在内的负向 fixture。修复 commit `c65693fe49e0c6ade7ff9751c5dda00103a9c37b` 的 run `30191096124` 与原始 artifact 已由 Agent C 复判通过，validator 为 `109 PASS / 0 FAIL`。
- v1.0 已让 iOS 待办新增/编辑与 macOS 快速新增接入非预设“已有分类”复用，分类只更新 View 草稿并按任务首次出现复用代表色，不新增持久化；artifact validator 已增加 `--run-metadata` 第四模式和十项 workflow run API 独立复判。实现 commit `7ccf408b82ce2ead457e5bce679f5cee1ac9ae33` 的 run `30192906663` 与原始 artifact 已由 Agent C 复判通过，validator 为 `121 PASS / 0 FAIL`。
- v1.1 已让 iOS/macOS 已有分类按规范化 key 显示当前任务数量，session-only 分类显示“历史”；新增独立云端 marker/PASS 和负向 fixture，不新增持久化。修复 commit `46546e703668025a43ed467cafc46571916ad7eb` 的 run `30193805133` 与原始 artifact 已由 Agent C 复判为 `122 PASS / 0 FAIL`。
- v1.2 已闭环：iOS/macOS 已有分类达到 6 项时提供规范化即时搜索、结果计数、清除和无结果反馈；Run API 完整模式增加 push/actor/triggering actor/head repository 四项授权来源复判。最终证据 commit、run、artifact 和 Agent C 结论见下方 v1.2 历史记录。
- 当前默认协作体系要求后续按 Agent A/B/C 云端闭环迭代：Agent A 产出版本化实现提示词，Agent B 只做静态审阅后基于最新 `origin/main` 实现、commit 并 push 到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载 artifact 并核对 manifest、run context、artifact 名称、日志和产物；失败时退回 Agent B 在 `main` 追加修复 commit。可由 Agent X 围绕人工总目标拆分多轮并调度 A/B/C 闭环。本轮禁止本地项目测试、validator、Xcode、`xcodebuild`、`simctl` 和 Simulator。
- 当前云端 CI 结果包覆盖静态检查、项目验证、`ChronoFocusMac` build、`ChronoFocus` iOS generic build、manifest artifactName、manifest overallOutcome、manifest short SHA、固定 CI process version、workflow/project/scheme/destination 元数据、project reports、artifact index artifactName、artifact index version/createdAt、entry 精确清单、本地元数据复算、index totals 一致性、额外 artifact 文件拒绝、run context 精确键集、JUnit suite/classname 元数据、errors 计数、outcome 和 failure/error 元素拒绝、failure summary 身份/总结果/outcome、static-checks 日志 marker、Xcode 版本日志、分类摘要动作 contract marker、分类可访问 contract marker、日程任务操作 contract marker、计时主控 contract marker、计划开始 contract marker、计划分类 badge contract marker、Mac 计划分类上下文 contract marker、计划面板操作 contract marker、日程 toolbar 新增 contract marker、日程分类空态操作 contract marker、Mac 日程分类空态操作 contract marker、Mac 快速新增和标题分类上下文 contract marker、分类输入上下文 contract marker、待办保存分类 contract marker、待办取消分类 contract marker、Mac 小窗快捷面板 contract marker、统计分类占比 contract marker、统计分类投入次数 contract marker、统计分类投入排行 contract marker、统计分类投入排序依据 contract marker、统计分类投入空态 contract marker、统计分类投入元信息可读性 contract marker、统计分类投入占比可读性 contract marker、统计最近记录分类 contract marker、统计计划回顾分类 contract marker、Mac 快照 manifest generatedAt/byteCount 复判和失败阶段关键错误摘录。
- v0.93 的当前云端覆盖还包括 `Mac calendar range empty state quick add contracts verified.` marker、`PASS verify_project mac calendar range empty state quick add contracts` 复判和 `negative_mac_calendar_range_empty_state_marker_fixture` 拒绝路径。

## 关键决策

- Mac 版不重写业务代码，只新增 macOS target、平台服务和 Mac 专用 UI。
- `TimerEngine` 是唯一计时状态机；View 不维护第二套开始/暂停/完成逻辑。
- `FocusStore` 是核心数据仓库；任务、设置、会话、计划和活跃计时快照使用 `UserDefaults` JSON 持久化。
- 平台能力通过协议和服务隔离：iOS 使用本地通知、ActivityKit、StoreKit、EventKit；macOS 使用 AppKit 状态栏、桌面通知、StoreKit、EventKit 和 Live Activity 空实现。
- Mac 快照渲染中，原生 `Picker`、`Toggle`、`Slider`、`DatePicker`、`Stepper` 和部分 bordered/prominent `Button` 可能显示黄色缺失占位；快照路径使用 `macSnapshotRendering` 环境值切换快照安全控件。

## 遗留问题

- StoreKit 和 EventKit 已有本地配置和人工验证说明；自动化 mock 尚未实现，后续如需覆盖真实系统服务失败路径可在平台服务边界补测试替身。
- 部分 SwiftUI View 文件较长，后续可在功能稳定后按职责拆分，不应在功能任务中顺手大重构。

## 历史记录

### v1.3 / 日程分类接力到计时

日期：2026-07-28

核心变更：

- iOS/macOS 日程分类摘要可通过带 UUID 的瞬态请求切到计时、恢复分类并选择首个当前可启动任务；任务行可携带 preferred task id 精确接力。
- 计时端消费时重新查询 `FocusStore.startableTasks()`；精确目标已完成、停用或删除时清除旧选择，运行中只恢复分类筛选。所有选择统一进入 `TimerEngine.selectTask(_:)`，不会自动开始或持久化请求。
- 分类摘要采用自适应布局，任务行和摘要接力入口补齐分类/任务上下文、运行中提示、VoiceOver 与 Voice Control 标签。
- Mac 快照覆盖日程接力入口与计时分类/selected 终态；云端验证新增 `Schedule to timer handoff contracts verified.`、对应 validator PASS 和 marker 缺失负向 fixture，预期基线为 `129 PASS / 0 FAIL`。

关键文件：

- `ChronoFocus/Views/DashboardView.swift`
- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacDetailView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `md/prompt/v1（持续优化）/v1.3（日程分类接力到计时）.md`

验证结果：

- 未运行任何本地项目测试、项目验证脚本、Xcode、`xcodebuild`、`simctl` 或 Simulator。主线程误执行过两次不读取项目文件的空操作 `git diff --check --no-index /dev/null /dev/null`；两次命令均未检查工作区、结果不作为验收证据，但仍属于违反人工禁令的操作，后续不得重复。
- 实现 commit `5feff79c42af8409eded81648a72b33029f1a6d5` 的 run `30322093934`（attempt `1`）、job `90159903882` 中静态检查、macOS/iOS build、manifest/summary 和 artifact 上传成功；project verification 因旧分类摘要清除按钮 contract 依赖 `body` 与 helper 的历史源码顺序而失败，最终结论为 failure。
- Agent C 在全新目录 `/private/tmp/chronofocus-c-review-30322093934-3391f385-a378-48f2-9f01-a06d441db3d0/` 原子落盘并核对 artifact `chronofocus-ci-v0.10-main-5feff79-run30322093934-attempt1`（id `8674404479`，size `93150`，digest `sha256:a32e9175d980ce3177df31fdb1a8d57c0c3395bb558ea2676767597cbbb643a2`，`expired=false`）；failure summary 与 JUnit 均只指向 `projectVerification`，修复后须追加 commit 重跑。
- 首次修复 commit `ab1974f943dfc6869c9a44849b2f9552585310e6` 的 run `30322395891`（attempt `1`）、job `90160800368` 已输出 `Schedule to timer handoff contracts verified.`，两端 build 和结果包上传成功；随后另一条旧 contract 因 `MacTaskListPanelView` 调用已封装到 `taskListPanel` helper、仍以旧调用位置到 `.onChange` 为切片而失败。
- Agent C 在全新目录 `/private/tmp/chronofocus-c-review-30322395891-186a98e0-026c-4515-8e75-0b4be83aba5f/` 核对 artifact `chronofocus-ci-v0.10-main-ab1974f-run30322395891-attempt1`（id `8674495274`，size `93522`，digest `sha256:1f787f3fac1e14f42dd6c63ef57c6160ebbe9e7e72cafb332b2d05bb38fe2d58`，`expired=false`）；failure summary 仍只指向 `projectVerification`，现改为直接验证 helper 内的 callback 接线。
- 第二次修复 commit `a5d5a85ac7095fe5718f45ba3c310c7252acb56d` 的 run `30322671653`（attempt `1`）、job `90161605749` 全步骤成功。Agent C 在 `/private/tmp/chronofocus-c-review-30322671653-ee8dcfd5-fe47-4ba7-8498-dca9bc14f086/` 原子落盘并复判 artifact `chronofocus-ci-v0.10-main-a5d5a85-run30322671653-attempt1`（id `8674620314`，size `14323974`，digest `sha256:58caa79f3d136235ddce0b6fba7201b5ed2ce3b0712d59a36b351ea4d052f1d3`，`expired=false`）为 `129 PASS / 0 FAIL`；JUnit 为 `4 tests / 0 failures / 0 errors`，annotations 为 `0`，Mac/iOS build 均成功。
- `detail-schedule.png` 清晰显示“产品”分类摘要的“转到计时”入口，`detail-timer.png` 显示“产品”筛选、`1/3` 计数和 selected 目标任务；两张快照均无重叠、空白占位或截断。独立 Agent C 判定实现验收通过。

- 最终证据 commit `2477407c21faf2e131e456fd19113344465b64d9` 的 GitHub Actions run `30323180673`（attempt `1`）成功；Agent C 在全新目录复判 artifact `8674780603`，validator 为 `129 PASS / 0 FAIL`，JUnit 为 `4 tests / 0 failures / 0 errors`，annotations 为 `0`，v1.3 正式闭环。

遗留事项：

- 静态快照只能证明入口和消费终态布局，真实点击、Tab/SplitView 重建与交互时序仍需源码 contract、双平台云端构建和 Agent C artifact 共同验收。

### v1.4.2 / Mac core CI 编译接线

日期：2026-08-09

核心变更：

- 云端 run `31295311282`（attempt `1`、`main`、`push`、head `b9d857e725a76ed15b6f83c3f5dc89920f3cf7bf`）的 `Project verification` 因 Mac core `swiftc` 源列表遗漏共享计时依赖而失败；精确错误为 `scripts/test_mac_core.swift:178:22: error: cannot find 'TimerEngine' in scope`，失败摘要同时指出命令在 `verify_project.sh` 第 5161 行退出。
- 仅在 `scripts/verify_project.sh` 的 Mac core 编译列表中、`FocusStore.swift` 后加入 `TimerEngine.swift` 和 `TimerPlatformServices.swift`，与已有 Mac snapshot 编译顺序一致；不修改 Swift、UI、测试断言、validator 或 workflow 行为。

关键文件：

- `scripts/verify_project.sh`
- `md/test/test.md`
- `md/prompt/v1（持续优化）/v1.4.2（Mac core CI 编译接线）.md`

验证结果：

- 按当前硬性约束未运行任何本地测试、`verify_project.sh`、validator、Swift 编译器、Xcode、`xcodebuild`、`simctl` 或 Simulator；仅完成静态审阅，最终只接受推送到 `origin/main` 后的 GitHub Actions 和 Agent C 原始 artifact 复判。
- run `31295311282` 的 Static checks、Mac build、iOS build 和结果包上传成功，`Project verification` 与最终 CI 状态失败；该 run 仅作为本轮失败背景，不能作为通过证据。

遗留事项：

- 本轮提交并 push 后，必须等待新 commit 对应的 GitHub Actions 完成，并由 Agent C 使用 `gh` 核对最新 run、artifact、日志和结果包；在最新云端验收通过前不得宣称 v1.4.2 完成。

### v1.4.1 / CI fixture archive binding 稳定性

日期：2026-08-09

核心变更：

- 将 `scripts/verify_project.sh` 的 artifact index 复算改为 fixed-point：重新计算所有 required entry，包含自引用 `ci-artifact-index.json` 的实际 byteCount，直到写入内容稳定后才生成 archive。
- 正向 run-metadata fixture 从最终 baseline 复制出独立冻结目录，再由同一目录生成 ZIP、size/digest 和 artifact metadata；validator 的目录、archive、metadata 参数不再依赖会被重赋值的共享变量。
- archive-backed 的 existing category reuse/usage/search、schedule-to-timer handoff、CI workflow run API metadata/provenance 负向 fixture 各自重新生成匹配 archive 和 metadata，并保留只允许目标 contract FAIL 的断言；不改 Swift、validator 安全检查或 artifact 结构。

关键文件：

- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`（只读，未修改）
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v1（持续优化）/v1.4.1（CI fixture archive binding稳定性）.md`

验证结果：

- 按当前硬性约束未运行任何本地测试、`verify_project.sh`、validator、Xcode、`xcodebuild`、`simctl` 或 Simulator；仅完成静态源码审阅，等待推送后的 GitHub Actions。
- 本轮基于 `origin/main` 提交 `5067079755039c12423c96870c24c560918d8ad2` 的云端 run `31294009115`；失败 artifact 为 `chronofocus-ci-v0.10-main-5067079-run31294009115-attempt1`（id `9032353778`，digest `sha256:4e479b44699ae9ca0bf429bf0d5f89ba60684aa51d5c775ba50871ad211c0a24`，`expired=false`），不能作为通过证据。
- 云端失败首要证据是 run-metadata 正向 fixture 的 archive binding 与 index required local metadata 连带失败；本轮修复完成后仍需由最新 `origin/main` run 证明 `131 PASS / 0 FAIL`。
- 修复提交 `b9d857e725a76ed15b6f83c3f5dc89920f3cf7bf` 已推送到 `origin/main`，触发云端 run `31295311282`；状态检查时 `Project verification` 和 macOS build 已通过，iOS generic build 仍在运行，未将该 run 宣称为最终通过。

遗留事项：

- 本轮修复尚未完成云端验证；提交并 push 后，Agent C 必须使用最新 run 的原始 run API、artifacts API、ZIP 和完整第四模式复判，未通过时继续在 `main` 追加最小修复。

### v1.4 / 可启动待办一致性与 Archive 目录绑定

日期：2026-08-09

核心变更：

- 保留 `FocusStore.upcomingTasks()` 的未完成排序和停用任务展示语义，新增 `startableTasks()` / `startableTask(for:)` 作为计时队列、计划启动和日程接力的统一可启动查询。
- `TimerEngine.selectTask(_:)`、`startPlanItem(_:)` 和 `start()` 重新从 store 复核任务；空闲任务变化、停止和完成后集中 reconcile 失效选择，运行中/暂停中不清除 `ActiveTimerSnapshot`。
- iOS/macOS 计时队列和 handoff 使用 startable 查询；CI validator 完整 archive 模式在自建临时目录安全解包原始 ZIP，逐路径比较类型、大小和 SHA-256，并拒绝 traversal、重复路径、前缀冲突、symlink 与特殊文件。

关键文件：

- `ChronoFocus/Services/FocusStore.swift`
- `ChronoFocus/Services/TimerEngine.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/test_mac_core.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `md/prompt/v1（持续优化）/v1.4（可启动待办一致性与Archive目录绑定）.md`

验证结果：

- 按当前硬性约束未运行任何本地测试、项目验证脚本、validator、Xcode、`xcodebuild`、`simctl` 或 Simulator；等待本轮 `origin/main` GitHub Actions 和 Agent C 最新 artifact 第四模式复判。
- 目标新增 `Startable task consistency contracts verified.` 与 `PASS artifact archive extracted directory binding`，完整第四模式预期为 `131 PASS / 0 FAIL`。
- 首次实现 commit `3779f26ebc4c0cae2983b7269508e020840a5ce3` 的 run `31291481389`（attempt `1`）中，Mac/iOS build、artifact upload 和 core 项目阶段通过，但静态检查发现 v1.4 提示词 EOF 多余空行，项目验证发现 iOS handoff contract 未接受直接 `startableTask(for: preferredTaskID)` 查询；`Final CI status` 因两阶段失败而失败。artifact `9031543584`（size `93583`，digest `sha256:67a997e59ac0767ba406530b5bdfeb758ce47ab589e4005036902656b2c854fd`）及原始证据保留，不能作为 v1.4 通过结论。

遗留事项：

- 第二次修复 commit `d070cdaa2311f633116351c0db1f28e73dc6ce18` 的 run `31291716728`（attempt `1`）静态检查和 Mac/iOS build 成功，但 `verify_project.sh` 在 CI 结果包 fixture 阶段静默退出，artifact index 缺少快照目录及五张 PNG。为保留失败语义并让下一次云端失败精确报告 Bash 行号和命令，追加 `ERR` 诊断 trap；artifact `9031627225`（size `93271`，digest `sha256:e9552ff8753bde27fee66b42c559f58838a0006baf7af4c7dae53361e9291d91`）及原始证据保留，不能作为 v1.4 通过结论。
- `ERR` 诊断在后续云端复核前静态定位到模拟器 resolver 的 `--print-build-command` fixture：旧 grep 对 Shellwords 转义的等号/空格反斜杠层数过严，`set -o pipefail` 因此提前退出；已改为读取完整命令并用固定字符串核对 xcodebuild、工程名和目标 UDID。
- 2026-08-09：为 archive 正向 fixture 增加云端失败明细输出；当 `validate_ci_artifact.rb` 失败时保留逐项 `PASS/FAIL` 结果，便于下一次 GitHub Actions 精确定位，不改变成功路径或本地测试策略。
- 2026-08-09：云端 run `31292833139` 的唯一失败为 macOS Ruby 缺少 `Zlib::Inflate#unused`；archive binding 改用 `total_in` 与 central directory 压缩字节数核对，保留 trailing-data 检查，等待新的 `main` run。
- 2026-08-09：云端 run `31292991751` 在负向 duplicate ZIP fixture 生成处被 macOS Python 3.14 的重复条目 warning 打断，构建与主 validator 路径未失败；fixture 仅抑制该已知 warning，并在 archive 负向断言失败时输出完整 validator 结果，等待新的 `main` run。
- 已追加修复：移除 v1.4 提示词 EOF 空行、让 iOS handoff 静态 contract 接受直接 startable lookup，并增加 CI fixture 失败行号诊断；等待新的 `origin/main` run、快照和 archive 目录绑定结果。

- 2026-08-09：云端 run 31293195672 已消除 duplicate warning，但正向 metadata/run metadata 断言仍无明细退出；增加正向 validator 命令失败输出和缺失 marker 诊断，等待新的 main run。
- 2026-08-09：云端 run 31293435259 的 run metadata 正向验证报告 archive 与当前 verify_project.log 不一致，并连带 index metadata/既有分类 marker 失败；增加两次 validator 之间的 fixture 摘要诊断，等待新的 main run。
- 2026-08-09：云端 fixture 摘要确认两次验证之间目录未变；run metadata 阶段改为从当前 fixture重新生成并重新绑定 archive、size/digest 与 artifact metadata，避免跨阶段复用 archive 证据。

### v1.2 / 已有分类搜索与 Run 来源复判

日期：2026-07-26

核心变更：

- iOS 待办新增/编辑和 macOS 快速新增在至少 6 个非预设已有分类时提供瞬态名称搜索、结果数/总数、清除和无结果反馈。
- 搜索使用独立空查询语义和现有 POSIX folding 做子串匹配，只过滤稳定 option，不修改分类/颜色草稿或任何持久化数据；Mac 外部预填会清除旧查询。
- validator Run API 完整模式新增 `event`、`actor.login`、`triggering_actor.login` 和 `head_repository.full_name` 四项严格来源复判，既有三种较弱模式保持兼容。
- 云端验证新增 `Existing category search contracts verified.`、`CI workflow run provenance contracts verified.`、两个 validator PASS、逐字段来源负例与 marker 缺失 fixtures。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `md/prompt/v1（持续优化）/v1.2（已有分类搜索与Run来源复判）.md`

验证结果：

- 按人工硬性约束，未运行任何本地测试、检查、验证脚本、`git diff --check`、Xcode、`xcodebuild`、`simctl` 或 Simulator。
- 实现 commit `2f6b1c03434007e307351a638b164e5b391c8c9a` 的 run `30194825035`（attempt `1`）全步骤成功；Agent C 在 `/private/tmp/chronofocus-c-review-30194825035-tCYBX9/` 复判 artifact `chronofocus-ci-v0.10-main-2f6b1c0-run30194825035-attempt1`（id `8629803475`，size `14399461`，digest `sha256:478d8082768f93f1ad7c3f7aa3bc07ec1de964568cf88372412d7c50758c2e02`，`expired=false`）为 `128 PASS / 0 FAIL`。但云端 `detail-schedule.png` 中搜索框与 `1/6` 计数正常，筛选出的“产品”chip 未渲染，Agent C 视觉验收不通过；Agent B 已把静态结果容器改为直接 HStack，必须重新 push 和验收。
- 返修 commit `0802d252056e99c704db8fe4bdaf8d26bb39a846` 的 run `30195201551`（attempt `1`）、job `89775366110` 全步骤成功。Agent C 在 `/private/tmp/chronofocus-c-review-30195201551-x2lTMH/` 复判 artifact `chronofocus-ci-v0.10-main-0802d25-run30195201551-attempt1`（id `8629896081`，size `14377527`，digest `sha256:78644d90e385b81c6c84017a059a4bc48bbebffe0967d63f14e04e7f2fdd8382`，`expired=false`）为 `128 PASS / 0 FAIL`，annotations 为 `0`，JUnit 为 `0 failures / 0 errors`，Mac/iOS build 均成功。
- 新 `detail-schedule.png` 已清晰显示搜索词“产品”、`1/6` 计数和“产品”结果 chip，无重叠、空白占位或截断；其余四张快照抽查无关联回归，v1.2 实现验收通过。
- 最终证据 commit `001875c842a2a2368346c043af59498c75a68788` 的 run `30195874234`（attempt `1`）、job `89777204906` 全步骤成功；Agent C 在命名与原子落盘规则合规的 `/private/tmp/chronofocus-c-review-30195874234-z335ik/` 复判 artifact `chronofocus-ci-v0.10-main-001875c-run30195874234-attempt1`（id `8630116575`，size `14377358`，digest `sha256:1ac0c627198c6d64cb77911a767c487a61d6c0604a383a6220f189e6aad4f007`，`expired=false`）为 `128 PASS / 0 FAIL`，annotations 为 `0`，v1.2 正式闭环。

遗留事项：

- 静态快照不能覆盖真实键盘输入、滚动和点击交互；本轮严格只采用 GitHub Actions 和下载的云端证据验收。

### v1.1 / 已有分类使用量上下文

日期：2026-07-26

核心变更：

- iOS 待办新增/编辑和 macOS 快速新增的已有分类 option 增加非持久化 `taskCount`，按 v1.0 的 POSIX folding key 聚合全部当前任务。
- 有任务显示数量，零任务的 session-only 分类显示“历史”；保持首次出现顺序、代表色、草稿更新、selected、VoiceOver/Voice Control 和 iOS 44pt 边界。
- 云端验证新增 `Existing category usage context contracts verified.`、validator PASS 与 marker 缺失负向 fixture，Mac 实际/静态渲染共享同一 option。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `md/prompt/v1（持续优化）/v1.1（已有分类使用量上下文）.md`

验证结果：

- 主线程未运行任何本地测试、检查、验证脚本、`git diff --check`、Xcode、`xcodebuild`、`simctl` 或 Simulator；CI 子 Agent 误运行过一次 `git diff --check`，该流程违规已记录，其输出不得作为验收证据。未运行项目验证脚本、Xcode 构建或模拟器。
- 当前 v1.1 实现与最终证据提交均已通过最新 GitHub Actions run 和 Agent C 复判。
- 首次实现 commit `0666b4efae1822e978adf21f08df145e43a99aa8` 的 run `30193636728`（attempt `1`）中静态检查、Mac/iOS build 和结果包上传成功，但 project verification 报 `iOS existing category VoiceOver label missing`，最终结论为 failure。原因是 v1.0 旧契约要求分类名后立即拼 selected 后缀，未容纳 v1.1 在中间插入任务数/“历史”；失败 artifact `8629415589` 已保留，Agent B 追加兼容修复后必须重新云端验收。
- 修复 commit `46546e703668025a43ed467cafc46571916ad7eb` 的 run `30193805133`（attempt `1`）成功，job `89771631745` 全步骤通过。Agent C 在 `/private/tmp/chronofocus-c-review-30193805133-S3r0x6/` 复判 artifact `chronofocus-ci-v0.10-main-46546e7-run30193805133-attempt1`（id `8629486888`，size `14392783`，digest `sha256:9f6dab2a41f7de05200309ca024d6c48215aa00d77955d55e2d3b7bb52bcc1f3`，`expired=false`）为 `122 PASS / 0 FAIL`；三项 archive、八项 artifact metadata、十项 run metadata、新 usage marker、manifest overall、Mac/iOS build 均 PASS，annotations 为 0。完整日志只有两条已知 AppIntents metadata 跳过警告。
- 最终证据 commit `db27324eb1a3ddf1fcf7672fdd66c1a326194946` 的 run `30194008859`（attempt `1`）成功，job `89772172289` 全步骤通过。Agent C 在 `/private/tmp/chronofocus-c-review-30194008859-EbwWeP/` 复判 artifact `chronofocus-ci-v0.10-main-db27324-run30194008859-attempt1`（id `8629538360`，size `14392402`，digest `sha256:0b40f8edb49e7aff56761b1fef21d79449098af3666211df661b79311f18a16a`，`expired=false`）为 `122 PASS / 0 FAIL`，annotations 为 0，v1.1 闭环。

遗留事项：

- v1.1 已闭环；后续版本不得复用其 Run API、Artifacts API 或原始 ZIP 作为新结论。

### v1.0 / 已有分类复用与 Run API 复判

日期：2026-07-26

核心变更：

- iOS `TaskEditorView` 与 macOS 快速新增从 `FocusStore.taskCategories` 派生非预设“已有分类”；清理显示名后使用固定 POSIX locale 做大小写、变音符号和宽度不敏感比较，按首次出现去重并保持 store 原顺序。
- 点击已有分类只修改 `category` / `accentHex` 表单草稿，不调用 `FocusStore` 保存、不 dismiss、不生成计划；代表色取 `store.tasks` 中首个同规范化分类任务，仅来自历史 session 时保留当前草稿颜色。自由文本和 5 个预设继续保留，没有新增、迁移或删除持久化字段。
- 两端已有分类项使用 checkmark、轮廓和 selected trait 表达选中状态，重复点击不清空；补齐 VoiceOver label/hint、Voice Control input labels，iOS 保持至少 44pt 点击高度，Mac 快照路径使用同一选项数据。
- `scripts/validate_ci_artifact.rb` 新增可选 `--run-metadata JSON`。它只允许在完整 archive 三参数和 `--artifact-metadata` 同时存在时启用，并复用非空、普通文件、拒绝 symlink、不超过 1 MiB 的包外 metadata 安全边界。
- 第四模式独立复判 workflow run API 的 response shape、id、run attempt、head SHA、head branch、workflow name、workflow path、completed status、success conclusion 和 repository，共十项 PASS/FAIL；既有目录-only、archive-only、archive + artifact metadata 三种模式保持兼容。
- Agent C 完整证据链要求在全新唯一目录中分别以 `.part` 保存精确 run API 和 artifacts API 原始响应，无覆盖原子改名为 `run-api.json`、`artifacts-api.json`；随后以 artifacts API 唯一 id 下载 ZIP `.part`，核对 size、digest 和 ZIP 结构后无覆盖改名、解包，并把两份 JSON、原始 ZIP 与解包目录共同交给 validator。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `md/prompt/v1（持续优化）/v1.0（已有分类复用与Run API复判）.md`
- `update_log.md`

验证结果：

- 按人工硬性约束，未运行任何本地测试、检查、验证脚本、`git diff --check`、Xcode、`xcodebuild`、`simctl` 或 Simulator。
- 实现 commit `7ccf408b82ce2ead457e5bce679f5cee1ac9ae33` 已 push 到 `origin/main`。GitHub Actions run `30192906663`（attempt `1`）成功，job `89769233620` 的项目验证、Mac build 和 iOS generic build 全部通过。
- Agent C 在 `/private/tmp/chronofocus-c-review-30192906663-BareEe/` 保存并核对精确 `run-api.json`、`artifacts-api.json` 和原始 ZIP；artifact `chronofocus-ci-v0.10-main-7ccf408-run30192906663-attempt1`（id `8629193568`，size `14394202`，digest `sha256:5d9a13ee2995960da6e9b6cd928ccc0f39e18b07bb42aae8f55184b4d44d8c94`，`expired=false`）经 validator 第四模式复判为 `121 PASS / 0 FAIL`。
- 三项 archive、八项 artifact metadata、十项 workflow run metadata、`Existing category reuse contracts verified.`、`CI workflow run API metadata contracts verified.`、manifest overall、Mac build 和 iOS build 均 PASS。完整日志未发现 Node 20 或 Action 弃用警告，仅有目标未依赖 AppIntents.framework 时跳过 metadata extraction 的已知良性警告。

遗留事项：

- 最终证据 commit `a76d1dbb2926297cbb05578b6b9cf781e08a1285` 的 GitHub Actions run `30193171049`（attempt `1`）成功，job `89769934710` 全步骤通过。Agent C 在 `/private/tmp/chronofocus-c-review-30193171049-QdKAhY/` 复判 artifact `chronofocus-ci-v0.10-main-a76d1db-run30193171049-attempt1`（id `8629271447`，size `14396212`，digest `sha256:e1baa096398e0016f708b6c86dcb8caf52d57a897c08c459dd2bee7e4f55760d`，`expired=false`）为 `121 PASS / 0 FAIL`，annotations 为 0；完整日志仅有两条 AppIntents metadata 跳过的已知良性警告，v1.0 闭环。
- v1.0 不改真实 StoreKit/EventKit 失败路径测试，也不新增分类管理、重命名、合并或删除能力；这些仍是后续独立轮次候选。

### v0.99 / iOS 计时队列展开与 Artifact API 元数据复判

日期：2026-07-26

核心变更：

- iOS `TimerView` 默认展示当前筛选结果前 4 项，超过阈值时提供动态“显示其余 N 项”与“收起”；展开显示全部筛选结果，分类或筛选结果数量变化时恢复收起。
- 展开状态仅属于 View 瞬态，不进入 `TimerEngine`、`FocusStore` 或持久化；计时运行中仍可展开浏览，任务行继续由 `engine.isRunning` 禁用，不改变当前任务。
- 展开控制使用系统 chevron、至少 44pt 点击高度、动态字体，并提供两态 VoiceOver label/value/hint 和以可见文案开头的 Voice Control 输入标签。
- `scripts/validate_ci_artifact.rb` 新增可选 `--artifact-metadata JSON`；metadata 必须与完整 archive 三参数共同提供，目录-only 和 archive-only 模式保持兼容。文件必须非空、不超过 1 MiB、为普通文件且拒绝 symlink，并使用 JSON 结构化解析。
- 完整 metadata 模式复判 `total_count=1`、唯一 artifact、正整数 id、预期 name、API/参数/实际 ZIP 三方一致的 size/digest、`expired=false` 和 `workflow_run.id/head_sha/head_branch`，输出八项独立 metadata PASS。API 不提供 `run_attempt`，attempt 继续由 workflow run、参数、artifact 名称和包内身份共同关联。
- Agent C 流程要求原始响应先写 `artifacts-api.json.part`，成功且非空后无覆盖原子改名，再用同一响应中的唯一 id 下载 ZIP `.part`；JSON、ZIP 和解包证据均位于全新唯一缓存目录，失败时默认保留。
- 项目验证新增 `Timer task queue expansion contracts verified.`、`CI artifact API metadata contracts verified.` 及两个 validator PASS；fixtures 覆盖 UI marker、API marker、参数矩阵、空/缺失/超限/非普通文件/symlink、JSON 形状、唯一性和各身份字段错误。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `md/prompt/v0（持续优化）/v0.99（iOS计时队列展开与Artifact API元数据复判）.md`
- `update_log.md`

验证结果：

- 按人工硬性要求未运行任何本地测试、检查、脚本、Xcode、`xcodebuild`、`simctl` 或 Simulator。
- 实现 commit `b54d11bf0dabf1d1c2a73308001867335f541c67` 对应 GitHub Actions run `30190889908`（attempt `1`）为 `success`，artifact `chronofocus-ci-v0.10-main-b54d11b-run30190889908-attempt1`（id `8628543223`，API size `14382466` bytes，digest `sha256:3629e9a6d2ecc434dd6fa93b57afc17555f3b015abd0aa33666465b74c868f49`，`expired=false`）经原始 API JSON、ZIP 和 validator 复判得到 `109 PASS / 0 FAIL`；Mac/iOS build、八项 metadata、三项 archive、UI/API marker 均通过。
- Agent C 静态审查发现提示词要求的独立 `total_count=0` 负向 fixture 缺失，因此该 run 不作为 v0.99 最终通过结论；Agent B 在修复 commit `c65693fe49e0c6ade7ff9751c5dda00103a9c37b` 补充零值 fixture，并由 run `30191096124`（attempt `1`）重新完成全套云端验证。
- 修复 run 结论为 `success`；artifact `chronofocus-ci-v0.10-main-c65693f-run30191096124-attempt1`（id `8628621407`，API size `14384904` bytes，digest `sha256:b5a3386abc747ec2577dd85c3cd40e2f049bc664dc6324597ddc85971103a94b`，`expired=false`）保留于 `/private/tmp/chronofocus-c-review-30191096124-xIntDI/`。Agent C validator 为 `109 PASS / 0 FAIL`，八项 metadata、三项 archive、manifest overall、UI/API marker、Mac/iOS build 均 PASS；完整日志无 Node 20 或弃用告警，仅有两端未依赖 AppIntents.framework 时系统元数据提取器的预期跳过告警。

遗留事项：

- v0.99 实现与修复已完成；本次证据记录提交必须再经自身最新 `origin/main` GitHub Actions 与 artifact 复判后闭环。后续版本不得复用 `b54d11b`、`c65693f` 或 v0.98 结果作为通过证据。

### v0.98 / 日程分类空态互斥与 CI 失败摘要直出

日期：2026-07-26

核心变更：

- iOS `ScheduleView` 仅在存在分类筛选且 `visibleTasks` 非空时显示 `SelectedCategorySummaryView`；分类筛选无结果时只显示现有 `ScheduleCategoryEmptyStateView` 双操作。
- macOS `MacTaskListPanelView` 应用相同互斥条件；正常与 snapshot rendering 路径继续复用现有 `MacScheduleCategoryEmptyStateView`，不增加快照专用业务状态。
- 两端非空摘要的分类、计数、新增和清除接线保持不变；空态新增继续预填当前分类，清除继续恢复全部分类，既有辅助功能语义不变。
- `.github/workflows/ci-results.yml` 的 `Final CI status` 使用 `tee -a "$GITHUB_STEP_SUMMARY" < ci-results/ci-failure-summary.md`，在四阶段 outcome 判断前把同一摘要同时写入步骤 stdout 与 Step Summary；artifact 文件、目录、manifest、index、上传路径和保留策略不变。
- `scripts/verify_project.sh` 强化 iOS/macOS 日程摘要与空态互斥契约，新增 `CI failure summary output contracts verified.`、`ci_failure_summary_cat_workflow_fixture` 和自检接线；`scripts/validate_ci_artifact.rb` 新增 `PASS verify_project ci failure summary output contracts`，并由 `negative_ci_failure_summary_output_marker_fixture` 覆盖 marker 缺失拒绝路径。

Agent C 云端验收证据：

- 实现 commit `9f26f865ab84c7874763bb3eef59a6a5c513a7c4` 对应 GitHub Actions run `30189412591`（attempt `1`），run 结论为 `success`；job `89759759272` 全步骤成功且 annotations 为 `0`。
- Artifact 为 `chronofocus-ci-v0.10-main-9f26f86-run30189412591-attempt1`（id `8628068160`，API size `14382692` bytes，digest `sha256:36b099026d830adb266034b9d70a776ee5dce696270d8288ceb1bb768d5de28f`，`expired=false`），验收缓存保留于 `/private/tmp/chronofocus-c-review-30189412591-v098-3HD4HX/`。
- Validator 完整复判为 `99 PASS / 0 FAIL`，包含三个 archive PASS、iOS/Mac 日程分类空态 marker PASS、CI failure summary marker PASS、manifest overall PASS、Mac build PASS 和 iOS build PASS。
- 完整云端日志共 `2412` 行、`490801` bytes，确认 `actions/checkout@v5` 与 `actions/upload-artifact@v6`；Node.js 20、Node 20、`DEP0040`、`punycode`、`DEP0169`、`url.parse` 和 `DeprecationWarning` 均为零匹配。
- `Final CI status` stdout 实际包含 failure summary 标题及四个阶段的 `success` 结果，证明摘要已同时直出步骤日志；v0.98 最新云端 CI 与 Agent C 原始 artifact 验收通过。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `.github/workflows/ci-results.yml`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `md/prompt/v0（持续优化）/v0.98（日程分类空态互斥与CI失败摘要直出）.md`
- `update_log.md`

验证结果：

- 未运行任何本地测试或检查命令；人工明确要求全部测试与验收只走 GitHub Actions/CI。
- GitHub Actions run `30189412591`（attempt `1`）结论为 `success`，Agent C 对对应原始 ZIP 和解包目录的完整 validator 复判为 `99 PASS / 0 FAIL`；Mac/iOS build、日程互斥和 failure summary stdout/marker 均通过。

遗留事项：

- v0.98 无未补写的云端验收事项；后续版本必须使用自身最新 `origin/main` run 和 artifact，不得复用本轮证据。

### v0.97 / iOS 计时筛选上下文与 Artifact 归档完整性

日期：2026-07-26

核心变更：

- iOS 计时页仅在分类筛选结果非空时显示摘要，展示分类名与筛选数/总数，并提供“新增此分类”和“清除筛选”双操作；分类无结果时只显示原有双操作空态，避免重复上下文和清除入口。
- 摘要通过 `ViewThatFits` 在横排和纵排间自适应；新增动作复用既有 `showingCategoryEditor` 与 `TaskEditorView(initialCategory:)`，保存返回后保持当前筛选并由 `FocusStore` 派生列表刷新计数。
- `TaskRow.showsCategoryBadge` 默认保持 `true`；计时分类筛选态隐藏重复视觉 badge，未筛选态不变，整行任务名、分类、选中/运行状态、提示、selected trait 和 Voice Control 语义继续独立保留。
- `scripts/validate_ci_artifact.rb` 增加可选 `--archive`、`--archive-size`、`--archive-digest`，要求三参数全有或全无；完整参数组复判实际 byte count、SHA-256 和 ZIP 结构并输出三个独立 PASS，不传归档参数的目录-only 调用保持兼容。
- `scripts/verify_project.sh` 增加 `CI artifact archive integrity contracts verified.` 和对应 validator PASS；成功 fixture 使用真实 ZIP，并覆盖部分参数拒绝、等长篡改摘要失败、截断大小失败、摘要匹配但非 ZIP 结构失败及 marker 缺失失败。
- Agent C 下载规范改为先查询 GitHub API artifact 元数据，在唯一目录中下载到 `.zip.part` 并有限重试；size/SHA-256/ZIP 校验通过后才同文件系统原子改名，默认拒绝覆盖、删除或复用已有缓存和解包目录。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `md/prompt/v0（持续优化）/v0.97（iOS计时筛选上下文与Artifact归档完整性）.md`
- `update_log.md`

验证结果：

- 未运行本地项目测试、验证脚本、构建、Xcode、Simulator 或设备命令；人工硬性要求全部测试与验收只走 GitHub Actions/CI。只读 CI reviewer 曾误执行一次无输出的 `git diff --check`，该偏差已如实记录，结果不作为本轮测试或验收证据。
- 修复提交 `d0b5c9b8baac7e2c510a4f077b864bd10d2b59d2` 已直推 `origin/main`；GitHub Actions run `30188580713`（attempt `1`）结论为 `success`，唯一 job 全步骤成功且 annotations 为 0。
- Agent C 已下载并复判 artifact `chronofocus-ci-v0.10-main-d0b5c9b-run30188580713-attempt1`（artifact id `8627808615`，API size `14384284` bytes，digest `sha256:6c95510ac4a3dec3dda2ff451dbb1a92b69eeeb67a64eed113217b215b828ea9`，`expired=false`）；原始 ZIP 实际 size/digest 与 API 完全一致，`unzip -t` 通过，缓存保留于 `/private/tmp/chronofocus-c-review-30188580713-v097-9aihRD/`。
- `scripts/validate_ci_artifact.rb` 完整 archive 参数调用为 `98 PASS / 0 FAIL`，包含三个 artifact archive PASS、`PASS verify_project timer category empty state action contracts`、`PASS verify_project ci artifact archive integrity contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`；manifest 与 run context 的 branch、完整 commit、run id、attempt 和 artifact 名称均一致。
- 完整云端日志共 `2383` 行、`487657` bytes，确认 `actions/checkout@v5` 与 `actions/upload-artifact@v6`；Node.js 20、Node 20、`DEP0040`、`punycode`、`DEP0169`、`url.parse` 和 `DeprecationWarning` 均为零匹配。
- 首次实现提交 `6c814746b52670c4dd0fa15cf9c2289a7feb4ec5` 的 GitHub Actions run `30188477650`（attempt `1`）中静态检查、Mac build 和 iOS generic build 成功，但项目验证因顶层仍匹配旧“项可启动”文案而失败；artifact `8627765962` 的 API size `92074` bytes、digest `sha256:dd9a9021afa5601cc97cbf0366c7c1f61ae8229661c8d46e66b58001123d2b37` 与下载 ZIP 一致且 ZIP 结构完整。修复已改为精确匹配新的筛选数/总数文案，并由上述后续成功 run 重新验收；该失败结果包未被复用为通过证据。

遗留事项：

- v0.97 当前范围已由最新云端 CI 与 Agent C 原始 ZIP 完整复判通过；后续 UI 细节仍需在下一轮小步目标中继续优化并重新走云端闭环。

### v0.96 / Mac 计时筛选上下文与 CI Action 运行时升级

日期：2026-07-26

核心变更：

- macOS 计时待办队列在已选分类且结果非空时显示常驻上下文条，展示分类名和筛选数/总数，并提供“新增此分类”和“清除筛选”动作。
- 上下文条使用宽度自适应横排/纵排布局；新增动作复用既有 `onAddTaskInCategory` 和唯一 `MacQuickAddRequest`，清除动作只重置本地分类筛选。
- `MacTaskRowView.showsCategoryBadge` 默认保持显示；计时分类筛选态隐藏重复视觉 badge，未筛选态和其他调用端不变，整行仍保留任务名、分类名、选中/运行状态、提示和 Voice Control 输入标签。
- Mac 快照脚本额外渲染正常非空分类筛选态和 220pt 窄宽上下文条，检查非空、前景内容和缺失控件占位；两张检查图不加入正式 artifact manifest，既有 5 张快照精确清单不变。
- `.github/workflows/ci-results.yml` 将 `actions/checkout@v4` 升级为 `actions/checkout@v5`，将 `actions/upload-artifact@v4` 升级为 `actions/upload-artifact@v6`，其余 checkout 参数、artifact 内容、名称、失败时上传、保留期和最终状态行为保持不变。
- `scripts/verify_project.sh` 增加 `CI action Node.js 24 contracts verified.`，并加入 `checkout_v4_workflow_fixture`、`upload_v4_workflow_fixture` 与 `negative_ci_action_node24_marker_fixture`；`scripts/validate_ci_artifact.rb` 增加 `PASS verify_project ci action Node.js 24 contracts`。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 v0.96 当前真实实现与云端验收要求。

关键文件：

- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `.github/workflows/ci-results.yml`
- `scripts/render_mac_snapshots.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.96（Mac计时筛选上下文与CI Action运行时升级）.md`
- `update_log.md`

验证结果：

- 未运行任何本地测试或检查；人工明确要求全部测试/验收只走 GitHub Actions/CI。
- 实现提交 `d09eb9153dfb52554cb186741453f9e233198b41` 已直推 `origin/main`；GitHub Actions run `30187038330`（attempt `1`）结论为 `success`。
- Agent C 已下载并复判 artifact `chronofocus-ci-v0.10-main-d09eb91-run30187038330-attempt1`（artifact id `8627359824`，`14383544` bytes，API digest `sha256:e17d8bc1016f5efcfe7718d4426ef20af2b43ceaad1af531e6785a46b3172977`）；API 身份与大小、ZIP 完整性以及 manifest、artifact index、run context 的 `branch=main`、完整 commit SHA、run id、run attempt 和 artifact 名称均一致。
- `scripts/validate_ci_artifact.rb` 对该云端结果包完整通过，包含 `PASS verify_project ci action Node.js 24 contracts`、`PASS verify_project mac timer category queue contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded`、`PASS ios build succeeded` 以及快照 manifest、名称、尺寸和字节数检查。
- 完整云端日志共 `2384` 行、`487731` bytes，确认下载 `actions/checkout@v5` 与 `actions/upload-artifact@v6`；Node 20/Node.js 20、`DEP0040`、`punycode`、`DEP0169`、`url.parse`、`DeprecationWarning` 均为零匹配。

遗留事项：

- 正常非空分类筛选态和 220pt 窄宽上下文条两张额外状态图仅在云端运行期完成渲染与断言，未进入正式 artifact 的 5 张快照清单，结果包无法供后续人工直接复看这两张临时图。

### v0.95 / Mac 计时分类队列与声明边界韧性

日期：2026-07-26

核心变更：

- macOS 计时详情待办队列增加全部/分类筛选、筛选数/总数和重复点击清除。
- 选中分类没有待办时显示自适应操作空态，可清除筛选或转到日程快速新增。
- `MacDetailSelection` 使用带唯一 id 的一次性 `MacQuickAddRequest` 切到日程；`MacScheduleDetailView` 消费并清空请求后复用 `prepareQuickAdd(_:)` 预填分类和聚焦标题。
- `MacTimerDetailView()` 与 `MacScheduleDetailView()` 保留默认参数；原计时详情快照继续覆盖正常队列，云端脚本另行渲染零待办分类和 220pt 窄宽空态，覆盖双操作与纵排回退且不扩展 artifact 清单。
- `scripts/verify_project.sh` 的三个通用 accessibility helper 和七个调用边界去除 `private` 访问级别耦合。
- CI 增加 `Mac timer category queue contracts verified.`、`Declaration boundary resilience contracts verified.`、两个 artifact validator PASS 和各自 marker 缺失负向 fixture。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 v0.95 真实实现与云端验收要求。

关键文件：

- `ChronoFocusMac/Views/MacDetailView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `scripts/render_mac_snapshots.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.95（Mac计时分类队列与声明边界韧性）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求全部测试/验收只走 GitHub Actions/CI。
- 实现提交 `4b4b246d5618ba34ec9a51388c7faf8060d4fa20` 已直推 `origin/main`；GitHub Actions run `30185850571`（attempt `1`）结论为 `success`。
- Agent C 已下载并复判 artifact `chronofocus-ci-v0.10-main-4b4b246-run30185850571-attempt1`（artifact id `8627016196`，`14382073` bytes）；manifest 的 `branch=main`、commit SHA、run id、run attempt 和 artifact 名称均与最新提交一致。
- `scripts/validate_ci_artifact.rb` 对该云端结果包完整通过，包含 `PASS verify_project mac timer category queue contracts`、`PASS verify_project declaration boundary resilience contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。
- 验收记录提交 `0afa5cd841222348e61b94d257c86c0f0e0e430a` 对应最终 run `30186142749`（attempt `1`）同样为 `success`；Agent C 已复判 artifact `chronofocus-ci-v0.10-main-0afa5cd-run30186142749-attempt1`（artifact id `8627109980`，`14383424` bytes），全部身份、marker、Mac/iOS build 和快照检查继续 PASS。

遗留事项：

- 总目标仍未完成；下一轮继续评估 Mac 计时筛选态的分类上下文和 CI action 运行时升级。

### v0.94 / 计时页分类空态新增入口

日期：2026-07-12

核心变更：

- iOS 计时页在选中分类且无可启动待办时，空态直接提供“新增此分类”和“清除筛选”。
- “新增此分类”打开预填当前分类的 `TaskEditorView` sheet；“清除筛选”退出分类筛选。
- 新增/清除操作使用 `ViewThatFits` 在横排与纵排之间自适应，降低窄屏和大号动态字体下的标签压缩风险。
- `TaskEditorView` 提升为跨文件可见，供计时页复用。
- `scripts/verify_project.sh` 新增 `Timer category empty state action contracts verified.` 源码契约、成功 fixture marker 和 `negative_timer_category_empty_state_marker_fixture`。
- 修正验证脚本中两处仍依赖 `private struct TaskEditorView` 的源码切片边界，并把自适应操作布局纳入同一源码契约。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project timer category empty state action contracts` 复判。
- README、测试规范、核心流程和 Agent A 提示词同步计时页分类空态新增入口与 artifact 复判。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/prompt/v0（持续优化）/v0.94（计时页分类空态新增入口artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 首个实现 commit `f5dc3115c2dd11e0bed659700b4cac34777dcfa6` 的 GitHub Actions run `29167467255` attempt `1` 失败；Mac/iOS build 均成功，结果包显示验证脚本仍以 `private struct TaskEditorView` 作为源码切片边界。
- 修复 commit `55f523c` 更新两处声明边界；后续 commit `f0d6f4e6f40cb07415424eb3beb13d787a69cd55` 补充操作区动态布局与对应契约，均已 push 到 `origin/main`。
- GitHub Actions run `30184604454` attempt `1` 成功，artifact 为 `chronofocus-ci-v0.10-main-f0d6f4e-run30184604454-attempt1`。
- 完整 artifact 下载到 `/private/tmp/chronofocus-c-review-30184604454-v094/complete/`；Agent C validator 输出全 PASS，包含 `PASS verify_project timer category empty state action contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.94 云端通过后可继续评估 Mac 计时分类空态、日程面板信息密度或更多分类快捷操作。

### v0.93 / Mac 日历范围空态快速新增

日期：2026-07-11

核心变更：

- macOS 日历面板当前范围没有待办时，空态显示当前选中日期并提供“新增到此日期”动作。
- 动作把当前选中日期传回左侧快速新增表单，保留原截止时间的时分，只替换年月日并聚焦任务名称。
- 快照路径复用静态 action view；真实按钮补充稳定点击区、日期可访问标签、操作提示和 Voice Control input labels。
- `scripts/verify_project.sh` 新增 `Mac calendar range empty state quick add contracts verified.` 源码契约、成功 fixture marker 和 `negative_mac_calendar_range_empty_state_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac calendar range empty state quick add contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 Mac 日历范围空态快速新增与 artifact 复判。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.93（Mac日历范围空态快速新增artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- commit `2a4a598a5c4d867879a3614dbe2d89145a310dcc` 已 push 到 `origin/main`，GitHub Actions run `29138489338` attempt `1` 成功。
- 已下载 artifact `chronofocus-ci-v0.10-main-2a4a598-run29138489338-attempt1` 到 `/private/tmp/chronofocus-c-review-29138489338-v093/`。
- Agent C artifact validator 输出全 PASS，包含 `PASS verify_project mac calendar range empty state quick add contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；下一轮可继续评估计时页分类空态新增入口、Mac 日程面板信息密度或 CI artifact 身份契约。

### v0.92 / Mac 日程分类空态操作

日期：2026-07-07

核心变更：

- macOS 日程详情页在选中分类且没有未完成待办时，分类空态直接提供“新增此分类”和“清除筛选”动作。
- “新增此分类”复用现有快速新增预填和聚焦路径，“清除筛选”退出当前分类筛选。
- `scripts/verify_project.sh` 新增 `Mac schedule category empty state action contracts verified.` 源码契约、成功 fixture marker 和 `negative_mac_schedule_category_empty_state_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac schedule category empty state action contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 Mac 日程分类空态操作与 artifact 复判。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.92（Mac日程分类空态操作artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- commit `1343a7c55f2860c45abaccb53c3ae9cdf6753736` 已 push 到 `origin/main`，GitHub Actions run `28856532433` attempt `1` 成功。
- 已下载 artifact `chronofocus-ci-v0.10-main-1343a7c-run28856532433-attempt1` 到 `/private/tmp/chronofocus-c-review-28856532433-v092/`。
- Agent C artifact validator 输出全 PASS，包含 `PASS verify_project mac schedule category empty state action contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；下一轮可继续评估 CI run 身份契约、Mac 日历范围空态或更多分类快捷操作。

### v0.91 / iOS 日程分类空态操作

日期：2026-07-07

核心变更：

- iOS 日程页在选中分类且当前范围没有待办时，改用 `ContentUnavailableView` 展示分类无结果空态。
- 分类空态直接提供“新增此分类”和“清除筛选”动作；新增复用现有待办编辑 sheet 并沿用当前筛选分类，清除会退出分类筛选。
- `scripts/verify_project.sh` 新增 `Schedule category empty state action contracts verified.` 源码契约、成功 fixture marker 和 `negative_schedule_category_empty_state_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project schedule category empty state action contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 iOS 日程分类空态操作与 artifact 复判。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.91（iOS日程分类空态操作artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `ebc889ad5a3d50285841c85c23cdf6bddcc85c3c` 已 push 到 `origin/main`；GitHub Actions `ChronoFocus CI Results` run `28850427559` attempt `1` 中 Mac/iOS build 成功，但项目验证失败于新空态契约切片过窄。
- 追加修复提交 `a94c2116d4265d7cb894c9f663af7bff0046ee0b` 修正 `scripts/verify_project.sh` 中 input labels 的源码契约复判范围，并已 push 到 `origin/main`。
- GitHub Actions `ChronoFocus CI Results` run `28851503306` attempt `1`（commit `a94c2116d4265d7cb894c9f663af7bff0046ee0b`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-a94c211-run28851503306-attempt1` 到 `/private/tmp/chronofocus-c-review-28851503306-v091/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit a94c2116d4265d7cb894c9f663af7bff0046ee0b --run-id 28851503306 --attempt 1` 全 PASS，包含 `PASS verify_project schedule category empty state action contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.91 云端通过后可继续评估 iOS 日程分类空态文案密度、CI run 身份契约或更多分类快捷操作。

### v0.90 / Mac 快速新增标题分类上下文

日期：2026-07-07

核心变更：

- macOS 日程快速新增的“任务名称”输入框新增当前分类可访问标签，读出“当前将新增到 X 分类”。
- 任务名称输入框新增按分类的 Voice Control input labels，覆盖“任务名称”“新增 X 分类待办”和“X 分类任务名称”。
- `scripts/verify_project.sh` 新增 `Mac quick add title field category context contracts verified.` 源码契约、成功 fixture marker 和 `negative_mac_quick_add_title_context_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac quick add title field category context contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步 Mac 快速新增标题分类上下文与 artifact 复判。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.90（Mac快速新增标题分类上下文artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `0ea81a92fe1c936922b392ad6fcc2ce56ced567f` 已 push 到 `origin/main`；GitHub Actions `ChronoFocus CI Results` run `28846853968` attempt `1` 通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-0ea81a9-run28846853968-attempt1` 到 `/private/tmp/chronofocus-c-review-28846853968-v090/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit 0ea81a92fe1c936922b392ad6fcc2ce56ced567f --run-id 28846853968 --attempt 1` 全 PASS，包含 `PASS verify_project mac quick add title field category context contracts`、`PASS verify_project mac quick add action accessibility contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.90 云端通过后可继续评估 iOS 日程分类筛选无结果空态、CI 运行身份契约或更多分类快捷操作。

### v0.89 / 统计分类投入占比可读性

日期：2026-07-07

核心变更：

- iOS 和 macOS 统计页“分类投入”行的百分比 pill 从内联 `.caption` 字体调整为 `categorySharePercentFont()` helper。
- 百分比 pill 使用 `.subheadline.bold()` 动态字体，提升分类投入占比的扫读可读性。
- `scripts/verify_project.sh` 新增 `Analytics category share percent readability contracts verified.` 源码契约、成功 fixture marker 和 `negative_analytics_category_share_percent_readability_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share percent readability contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步统计分类投入占比可读性与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.89（统计分类投入占比可读性artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `a057103da6e336beea94944261a1f1a6a8d6baa9` 已 push 到 `origin/main`；reviewer 指出占比 helper 契约需要绑定 helper 本体后，追加修复提交 `4c76bd0370afc0e44a6251b2712eb013c519a7b8` 并重新 push。
- GitHub Actions `ChronoFocus CI Results` run `28845366161` attempt `1`（commit `4c76bd0370afc0e44a6251b2712eb013c519a7b8`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-4c76bd0-run28845366161-attempt1` 到 `/private/tmp/chronofocus-c-review-28845366161-v089/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit 4c76bd0370afc0e44a6251b2712eb013c519a7b8 --run-id 28845366161 --attempt 1` 全 PASS，包含 `PASS verify_project analytics category share percent readability contracts`、`PASS verify_project analytics category share metadata readability contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.89 云端通过后可继续评估统计页分类筛选入口、分类投入 row 密度或更多 CI artifact 负向路径。

### v0.88 / 统计分类投入元信息可读性

日期：2026-07-07

核心变更：

- iOS 和 macOS 统计页“分类投入”行的专注次数与排行位置元信息从 `.caption2.weight(.medium)` 调整为 `.caption` 动态字体，减少辅助信息过小导致的可读性问题。
- iOS 和 macOS 统计页共用 `categoryShareMetadataFont()` helper，保持分类投入元信息字体契约一致。
- `scripts/verify_project.sh` 新增 `Analytics category share metadata readability contracts verified.` 源码契约、成功 fixture marker 和 `negative_analytics_category_share_metadata_readability_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share metadata readability contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步统计分类投入元信息可读性与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.88（统计分类投入元信息可读性artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `23bd76a112bfc42e26a9a6badbefe8fa78e07171` 已 push 到 `origin/main`；GitHub Actions `ChronoFocus CI Results` run `28844000775` attempt `1` 通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-23bd76a-run28844000775-attempt1` 到 `/private/tmp/chronofocus-c-review-28844000775-v088/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit 23bd76a112bfc42e26a9a6badbefe8fa78e07171 --run-id 28844000775 --attempt 1` 全 PASS，包含 `PASS verify_project analytics category share metadata readability contracts`、`PASS verify_project analytics category share empty state contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.88 云端通过后可继续评估统计页分类筛选入口、分类投入 row 密度或更多 CI artifact 负向路径。

### v0.87 / 统计分类投入空态语义

日期：2026-07-07

核心变更：

- iOS 统计页“分类投入”无数据时改为 `ContentUnavailableView`，显示“暂无分类统计”和完成带分类番茄钟后的下一步说明。
- macOS 统计页“分类投入”空态改用与 iOS 同名 helper，空态可访问标签与 Voice Control input labels 同步包含分类统计上下文。
- `scripts/verify_project.sh` 新增 `Analytics category share empty state contracts verified.` 源码契约、成功 fixture marker 和 `negative_analytics_category_share_empty_state_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share empty state contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步统计分类投入空态语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.87（统计分类投入空态语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `efd4dc3224faa4709d38a11347e8fcc2391e6ed3` 已 push 到 `origin/main`；GitHub Actions `ChronoFocus CI Results` run `28842425987` attempt `1` 通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-efd4dc3-run28842425987-attempt1` 到 `/private/tmp/chronofocus-c-review-28842425987-v087/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit efd4dc3224faa4709d38a11347e8fcc2391e6ed3 --run-id 28842425987 --attempt 1` 全 PASS，包含 `PASS verify_project analytics category share empty state contracts`、`PASS verify_project analytics category share sort context contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；后续可继续评估统计页分类筛选入口、分类投入有数据行的紧凑文案或更多 CI artifact 负向路径。

### v0.86 / 统计分类投入排序依据语义

日期：2026-07-07

核心变更：

- iOS 和 macOS 统计页“分类投入”区显示“按投入时长排序”，让用户明确排行依据。
- 分类投入整行可访问标签与 Voice Control input labels 同步包含排序依据、分类名和排行位置。
- `scripts/verify_project.sh` 新增 `Analytics category share sort context contracts verified.` 源码契约、成功 fixture marker 和 `negative_analytics_category_share_sort_context_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share sort context contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步统计分类投入排序依据语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.86（统计分类投入排序依据语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 实现提交 `674f6f0c8788e310ba90160b54ffa0d0fa5ab51a` 已 push 到 `origin/main`；GitHub Actions `ChronoFocus CI Results` run `28840377768` attempt `1` 通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-674f6f0-run28840377768-attempt1` 到 `/private/tmp/chronofocus-c-review-28840377768-v086/`，运行 `ruby scripts/validate_ci_artifact.rb ... --commit 674f6f0c8788e310ba90160b54ffa0d0fa5ab51a --run-id 28840377768 --attempt 1` 全 PASS，包含 `PASS verify_project analytics category share sort context contracts`、`PASS verify_project analytics category share ranking contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；后续可继续评估统计页分类筛选入口、分类投入空态升级或更多 CI artifact 负向路径。

### v0.85 / 统计分类投入排行语义

日期：2026-07-07

核心变更：

- iOS 和 macOS 统计页“分类投入”行基于 `FocusStore.categoryBreakdown()` 的既有降序结果显示“第 N 位”排行位置。
- 分类投入整行可访问标签与 Voice Control input labels 同步包含分类名和排行位置，辅助技术不需要仅靠视觉顺序判断排序。
- `scripts/verify_project.sh` 新增 `Analytics category share ranking contracts verified.` 源码契约、成功 fixture marker 和 `negative_analytics_category_share_ranking_marker_fixture`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share ranking contracts` 复判。
- README、测试规范、核心流程、流程图和 Agent A 提示词同步统计分类投入排行语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.85（统计分类投入排行语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- GitHub Actions `ChronoFocus CI Results` run `28839027627` attempt `1`（commit `cc27ca06f484ef694dc971485d88928776fbad92`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-cc27ca0-run28839027627-attempt1` 至 `/private/tmp/chronofocus-c-review-28839027627-v085/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28839027627-v085/chronofocus-ci-v0.10-main-cc27ca0-run28839027627-attempt1 --commit cc27ca06f484ef694dc971485d88928776fbad92 --run-id 28839027627 --attempt 1` 通过，包含 `PASS verify_project analytics category share ranking contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.85 云端通过后可继续评估统计页分类筛选入口、分类排序解释文案或更多 CI artifact 负向路径。

### v0.84 / 统计分类投入次数上下文

日期：2026-07-06

核心变更：

- `CategoryFocus` 新增非持久化 `sessionCount`，`FocusStore.categoryBreakdown()` 按已完成专注会话聚合分类专注次数。
- iOS 和 macOS 统计页“分类投入”行显示“X 次专注”，整行可访问标签与 Voice Control input labels 同步包含次数上下文。
- Mac 核心测试补充分类统计专注次数断言。
- `scripts/verify_project.sh` 新增 `Analytics category share session count contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share session count contracts` 复判。
- README、测试规范、核心流程和流程图同步分类投入次数上下文与 artifact 复判。

关键文件：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Services/FocusStore.swift`
- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/test_mac_core.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.84（统计分类投入次数上下文artifact复判）.md`
- `update_log.md`

验证结果：

- `git diff --check` 通过。
- `ruby -c scripts/validate_ci_artifact.rb` 通过，输出 `Syntax OK`。
- `bash -n scripts/verify_project.sh` 通过。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'` 通过，输出 `yaml ok`。
- `bash scripts/verify_project.sh` 未能在当前 Linux 容器完成，第一步因缺少 macOS/Xcode 工具 `plutil` 失败；完整项目验证、Mac build 和 iOS generic build 待 push 后由 GitHub Actions `ChronoFocus CI Results` 执行并由 Agent C 下载最新 artifact 复判。
- GitHub Actions `ChronoFocus CI Results` run `28811711142` attempt `1`（commit `fa1c6fc8c92769d344b23f5c0f68af6da7d57a9c`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-fa1c6fc-run28811711142-attempt1` 至 `/private/tmp/chronofocus-c-review-28811711142/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28811711142/chronofocus-ci-v0.10-main-fa1c6fc-run28811711142-attempt1 --commit fa1c6fc8c92769d344b23f5c0f68af6da7d57a9c --run-id 28811711142 --attempt 1` 通过，包含 `PASS verify_project analytics category share session count contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.84 通过后可继续评估统计页分类筛选入口、分类排序解释或更多 CI artifact 负向路径。

### v0.83 / 待办编辑取消分类语义

日期：2026-07-07

核心变更：

- iOS 待办新增/编辑表单的取消按钮新增取消新增/取消编辑动作、任务名和分类名可访问标签。
- 取消按钮 Voice Control input labels 支持“取消”、动作名、任务名、分类名和分类取消等说法。
- `scripts/verify_project.sh` 新增 `Task editor cancel category accessibility contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project task editor cancel category accessibility contracts` 复判。
- README、测试规范和核心流程文档同步待办取消按钮分类语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.83（待办编辑取消分类语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- GitHub Actions `ChronoFocus CI Results` run `28808992516` attempt `1`（commit `efa7bfc4f19255ed3a53eb498fe81f7274e04445`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-efa7bfc-run28808992516-attempt1` 至 `/private/tmp/chronofocus-c-review-28808992516/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28808992516 --commit efa7bfc4f19255ed3a53eb498fe81f7274e04445 --run-id 28808992516 --attempt 1` 通过，包含 `PASS verify_project task editor cancel category accessibility contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.83 云端通过后可继续评估统计页筛选入口、日程编辑表单模式切换语义或更多 CI artifact 负向路径。

### v0.82 / 待办编辑保存分类语义

日期：2026-07-07

核心变更：

- iOS 待办新增/编辑表单的保存按钮新增任务名、分类名和计划方式可访问标签。
- 保存按钮 Voice Control input labels 支持“保存”、动作名、任务名、分类名、分类保存等说法。
- 按轮次任务读出“预计 N 轮”，只设开始任务读出“只设开始”，避免把开放式计时误读为一轮任务。
- `scripts/verify_project.sh` 新增 `Task editor save category accessibility contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project task editor save category accessibility contracts` 复判。
- README、测试规范和核心流程文档同步待办保存按钮分类语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.82（待办编辑保存分类语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- GitHub Actions `ChronoFocus CI Results` run `28807596891` attempt `1`（commit `a5ead287a0e1083b2e47f2eb7d4655d30704a1de`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-a5ead28-run28807596891-attempt1` 至 `/private/tmp/chronofocus-c-review-28807596891/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28807596891 --commit a5ead287a0e1083b2e47f2eb7d4655d30704a1de --run-id 28807596891 --attempt 1` 通过，包含 `PASS verify_project task editor save category accessibility contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.82 云端通过后可继续评估统计页筛选入口、日程编辑取消动作语义或更多 CI artifact 负向路径。

### v0.81 / 统计计划回顾分类语义

日期：2026-07-06

核心变更：

- iOS 统计页“日程计划回顾”计划项新增分类 badge，使用分类预设图标/颜色并回退到计划项颜色。
- 计划回顾行新增任务、分类、计划开始时间和轮次的整行可访问标签，并补齐任务名/分类名 Voice Control input labels。
- `scripts/verify_project.sh` 新增 `Analytics plan review category accessibility contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics plan review category accessibility contracts` 复判。
- README、测试规范和核心流程文档同步统计计划回顾分类语义与 artifact 复判。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.81（统计计划回顾分类语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- GitHub Actions `ChronoFocus CI Results` run `28806040820` attempt `1`（commit `567c003a0d9ffc9b8aaae1532f6ff3c7bfa72500`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-567c003-run28806040820-attempt1` 至 `/private/tmp/chronofocus-c-review-28806040820/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28806040820 --commit 567c003a0d9ffc9b8aaae1532f6ff3c7bfa72500 --run-id 28806040820 --attempt 1` 通过，包含 `PASS verify_project analytics plan review category accessibility contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.81 通过后可继续评估待办编辑保存按钮分类语义或统计页更多分类筛选入口。

### v0.80 / 分类筛选反选清除 artifact 复判

日期：2026-07-06

核心变更：

- `scripts/verify_project.sh` 将 iOS 日程、iOS 计时和 macOS 日程分类筛选 chip 再次点击已选分类清除筛选的源码契约提升为独立 marker：`Category filter toggle contracts verified.`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project category filter toggle contracts` 复判。
- `scripts/verify_project.sh` 的小型成功 fixture 补齐新 marker，并新增 `negative_category_filter_toggle_marker_fixture`。
- README、测试规范和核心流程文档同步分类筛选反选清除 artifact 复判。

关键文件：

- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.80（分类筛选反选清除artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- GitHub Actions `ChronoFocus CI Results` run `28804310685` attempt `1`（commit `79ea6b04311f2d9cc9f7f0f417466a6ba3519772`）通过。
- Agent C 下载 artifact `chronofocus-ci-v0.10-main-79ea6b0-run28804310685-attempt1` 至 `/private/tmp/chronofocus-c-review-28804310685/`，运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28804310685 --commit 79ea6b04311f2d9cc9f7f0f417466a6ba3519772 --run-id 28804310685 --attempt 1` 通过，包含 `PASS verify_project category filter toggle contracts`、`PASS manifest overall outcome`、`PASS mac build succeeded` 和 `PASS ios build succeeded`。

遗留事项：

- 总目标仍未完成；v0.80 通过后可优先评估统计页计划回顾分类 badge 或待办编辑保存按钮分类语义。

### v0.79 / 当前任务选择分类语义 artifact 复判

日期：2026-07-06

核心变更：

- `scripts/verify_project.sh` 将 iOS 计时页、macOS 详细计时页和 macOS 小窗当前任务选择行分类语义检查提升为独立 marker：`Current task selection accessibility contracts verified.`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project current task selection accessibility contracts` 复判。
- `scripts/verify_project.sh` 的小型成功 fixture 补齐新 marker，并新增 `negative_current_task_selection_marker_fixture`。
- README、测试规范和核心流程文档同步当前任务选择分类语义 artifact 复判。

关键文件：

- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.79（当前任务选择分类语义artifact复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28803184384` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-4a6fdfc-run28803184384-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS verify_project current task selection accessibility contracts`、`PASS manifest overall outcome` 和 `PASS index artifact name`。

遗留事项：

- 总目标仍未完成；v0.79 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.78 / 统计最近记录分类上下文

日期：2026-07-06

核心变更：

- iOS 统计页最近记录每条 session 新增分类 badge，并读出任务、分类、模式、开始时间、实际时长和完成状态。
- macOS 统计详情最近记录同步新增分类 badge 和整行可访问语义。
- 最近记录 Voice Control input labels 支持任务名、分类名、分类和分类记录。
- `scripts/verify_project.sh` 新增 `Analytics recent session category contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics recent session category contracts` 复判。
- README、测试规范和核心流程文档同步统计最近记录分类上下文。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.78（统计最近记录分类上下文）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28800167506` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-926737f-run28800167506-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS verify_project analytics recent session category contracts`、`PASS manifest overall outcome` 和 `PASS index artifact name`。

遗留事项：

- 总目标仍未完成；v0.78 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.77 / 计时主控任务分类语义

日期：2026-07-06

核心变更：

- iOS 计时页开始/继续/暂停、停止、跳过和只设开始任务完成按钮补齐当前任务名与分类语义。
- macOS 详细计时页计时主控按钮补齐当前任务名与分类语义。
- macOS 状态栏小窗计时主控按钮补齐当前任务名与分类语义。
- macOS 快照静态计时操作 chip 同步任务/分类语义，保持与真实按钮一致。
- `scripts/verify_project.sh` 新增 `Timer action accessibility contracts verified.` 源码契约和 marker 缺失负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project timer action accessibility contracts` 复判。
- README、测试规范和核心流程文档同步计时主控任务/分类语义。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.77（计时主控任务分类语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28796479544` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-9be2b02-run28796479544-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS verify_project timer action accessibility contracts`、`PASS manifest overall outcome` 和 `PASS index artifact name`。

遗留事项：

- 总目标仍未完成；v0.77 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.76 / CI manifest 总结果复判

日期：2026-07-06

核心变更：

- CI manifest 新增 `overallOutcome`，由 static checks、项目验证、Mac build 和 iOS build 四个阶段推导。
- `ci-failure-summary.md` 新增 `Overall outcome` 行，和 manifest 总结果保持一致。
- `scripts/validate_ci_artifact.rb` 新增 `manifest overall outcome` 复判，并把总结果纳入 failure summary outcomes 检查。
- `scripts/verify_project.sh` 的小型成功 fixture 补齐 `overallOutcome`，并新增 manifest 总结果篡改负向 fixture。
- README、测试规范和核心流程文档同步 CI manifest 总结果复判范围。

关键文件：

- `.github/workflows/ci-results.yml`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.76（CI manifest 总结果复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28794441344` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-92cb035-run28794441344-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS manifest overall outcome`、`PASS index artifact name` 和 `PASS run context exact keys`。

遗留事项：

- 总目标仍未完成；v0.76 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.75 / 待办行操作分类语义

日期：2026-07-06

核心变更：

- iOS 待办行完成、启用、编辑操作的可访问标签和 Voice Control input labels 补齐分类语义。
- iOS swipe 编辑/删除操作补齐任务名和分类语义。
- macOS 待办行完成、启用、删除操作同步读出任务名和分类。
- macOS 快照静态操作控件同步分类语义，保持与真实按钮一致。
- `scripts/verify_project.sh` 升级现有 `Schedule task action accessibility contracts verified.` 源码契约，覆盖分类语义。
- README、测试规范和核心流程文档同步待办行操作分类语义。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.75（待办行操作分类语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28793065027` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-39a057a-run28793065027-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS verify_project schedule task action accessibility contracts` 和 `PASS index artifact name`。

遗留事项：

- 总目标仍未完成；v0.75 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.74 / CI artifact index 名称锚点复判

日期：2026-07-06

核心变更：

- `.github/workflows/ci-results.yml` 在 `ci-artifact-index.json` 顶层写入 `artifactName`。
- `scripts/validate_ci_artifact.rb` 新增 `index artifact name` 复判，要求 index、manifest、run context 和固定规则计算出的 artifact 名称一致。
- `scripts/verify_project.sh` 的小型成功 fixture 补齐 index `artifactName`，并新增 index artifactName 篡改负向 fixture。
- README、测试规范和核心流程文档同步 index artifactName 与云端结果包复判范围。

关键文件：

- `.github/workflows/ci-results.yml`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.74（CI artifact index 名称锚点复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28791667497` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-843226c-run28791667497-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS index artifact name`。

遗留事项：

- 总目标仍未完成；v0.74 通过后可继续做 v0.75 待办行操作分类语义或其他 UI 分类可用性小步优化。

### v0.73 / 计划项分类徽标

日期：2026-07-06

核心变更：

- iOS 自动计划项将分类从 metadata 文本拆出为可见分类 badge。
- macOS 自动计划项同步新增分类 badge，使用分类预设图标和颜色，缺失预设时回退到计划项颜色和 `tag.fill`。
- iOS/macOS 计划项分类 badge 补齐分类名可访问标签和 Voice Control input labels。
- `scripts/verify_project.sh` 新增 `Plan category badge contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project plan category badge contracts` 复判。
- README、测试规范和核心流程文档同步计划项分类 badge 与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.73（计划项分类徽标）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端 GitHub Actions run `28789905825` attempt `1` 通过；artifact `chronofocus-ci-v0.10-main-8586cd2-run28789905825-attempt1` 已由 Agent C 下载复判，validator 全 PASS，包含 `PASS verify_project plan category badge contracts`。

遗留事项：

- 总目标仍未完成；v0.73 通过后继续寻找下一处分类 UI 可读性或 CI artifact 复判缺口。

### v0.72 / CI 运行上下文精确复判

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `EXPECTED_RUN_CONTEXT_KEYS`，对 `ci-run-context.txt` 执行精确键集复判。
- validator 新增 `run context exact keys` 检查，拒绝重复 key、额外 key 或缺失 key 的 run context。
- `scripts/verify_project.sh` 新增 run context 额外字段负向 fixture，要求输出 `FAIL run context exact keys`。
- README、测试规范和核心流程文档同步 run context 精确键集、无重复和无额外字段复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.72（CI运行上下文精确复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.72 通过后可继续实现 v0.73 计划项分类 badge 可见化。

### v0.71 / 分类输入上下文

日期：2026-07-06

核心变更：

- iOS 新增/编辑待办表单的分类输入区域新增当前分类上下文胶囊，跟随手写分类或预设分类更新。
- macOS 快速新增表单的分类输入区域新增当前分类上下文；从筛选摘要预填时保留“已预填”语义。
- iOS/macOS 分类输入框补齐当前分类可访问标签、提示和 Voice Control input labels。
- `scripts/verify_project.sh` 新增 `Category input context contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project category input context contracts` 复判。
- README、测试规范和核心流程文档同步分类输入上下文与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.71（分类输入上下文）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.71 通过后继续寻找下一处分类录入效率、统计可读性或 CI artifact 复判缺口。

### v0.70 / 统计分类占比语义

日期：2026-07-06

核心变更：

- iOS 统计页“分类投入”行新增分类投入占比胶囊，按当前分类汇总总量计算占比。
- macOS 统计页“分类投入”行同步新增分类投入占比胶囊。
- iOS/macOS 分类投入行补齐整行可访问标签和 Voice Control input labels，暴露分类、投入时长和占比。
- `scripts/verify_project.sh` 新增 `Analytics category share accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project analytics category share accessibility contracts` 复判。
- README、测试规范和核心流程文档同步统计分类占比语义与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/AnalyticsView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.70（统计分类占比语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 首个云端 run `28783215492` 的 Mac/iOS build 已通过，但 `Project verification` 因 `verify_project.sh` 中 heredoc 内误用 `ruby -e` 语法失败；已在后续 v0.70 修复 commit 中改为原生 Ruby 代码块。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.70 通过后继续寻找下一处分类录入效率、统计可读性或 CI artifact 复判缺口。

### v0.69 / JUnit 失败元素复判

日期：2026-07-06

核心变更：

- `.github/workflows/ci-results.yml` 生成 JUnit `testsuite` 时显式写入 `errors="0"`。
- `scripts/validate_ci_artifact.rb` 新增 `junit errors` 和 `junit failure elements` 复判，要求 errors 计数为 0 且 testcase 内不含 `failure` 或 `error` 元素。
- `scripts/verify_project.sh` 的小型成功 fixture 同步 JUnit `errors="0"`，并新增 JUnit errors 计数与 failure/error 元素负向 fixture。
- README、测试规范和核心流程文档同步 JUnit errors/failure 元素复判范围。

关键文件：

- `.github/workflows/ci-results.yml`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.69（JUnit失败元素复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.69 通过后继续寻找下一处小型 UI 分类体验或 CI artifact 复判缺口。

### v0.68 / CI 结果包名称锚点复判

日期：2026-07-06

核心变更：

- `.github/workflows/ci-results.yml` 在 `ci-artifact-manifest.json` 中写入 `artifactName`。
- `scripts/validate_ci_artifact.rb` 新增 `manifest artifact name` 复判，要求 manifest、run context 和固定规则计算出的 artifact 名称一致。
- `scripts/verify_project.sh` 的小型成功 fixture 增加 manifest artifactName，并新增 manifest artifactName 篡改负向 fixture。
- README、测试规范和核心流程文档同步 manifest artifactName 复判范围。

关键文件：

- `.github/workflows/ci-results.yml`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.68（CI结果包名称锚点复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.68 通过后可继续寻找下一处小型 UI 语义或 CI artifact 身份复判缺口。

### v0.67 / Mac 小窗快捷面板语义

日期：2026-07-06

核心变更：

- macOS 小窗快捷面板的模式按钮补齐当前模式、切换动作、运行中不可切换提示、Voice Control input labels 和 selected trait。
- macOS 小窗快捷面板的专注时长按钮补齐当前已选、设置动作、运行中不可调整提示、Voice Control input labels 和 selected trait。
- macOS 小窗快捷面板的铃声、试听、日程、统计和设置按钮补齐动作语义与 Voice Control input labels。
- `scripts/verify_project.sh` 新增 `Mac mini quick panel accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac mini quick panel accessibility contracts` 复判。
- README、测试规范和核心流程文档同步 Mac 小窗快捷面板按钮语义与云端结果包复判范围。

关键文件：

- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.67（Mac小窗快捷面板语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.67 通过后可继续评估 CI manifest artifactName 复判或其他小型 UI 语义缺口。

### v0.66 / Mac 快速新增操作语义

日期：2026-07-06

核心变更：

- macOS 日程详情页快速新增真实按钮补齐当前分类和预计轮次可访问标签。
- macOS 日程详情页快速新增真实按钮补齐按分类新增的 Voice Control input labels。
- macOS 快照静态“新增待办”按钮保留短可见标题，并通过可访问覆盖文本保留分类和预计轮次语义。
- `scripts/verify_project.sh` 新增 `Mac quick add action accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac quick add action accessibility contracts` 复判。
- README、测试规范和核心流程文档同步 Mac 快速新增提交按钮语义与云端结果包复判范围。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.66（Mac快速新增操作语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.66 通过后可继续评估 Mac 小窗快捷面板按钮语义或 JUnit failure 元素复判。

### v0.65 / CI 版本复判

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `EXPECTED_CI_PROCESS_VERSION = "v0.10"`，并新增 `ci process version` 复判。
- artifact name 预期值改为使用固定 process version 常量，避免直接信任 manifest 自带 version。
- `scripts/verify_project.sh` 新增旧 `v0.09` process version 负向 fixture，要求 validator 输出 `FAIL ci process version`。
- README、测试规范和核心流程文档同步固定 CI process version 复判与旧版本错包拒绝范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.65（CI版本复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 后续若 bump `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION`，必须同步 validator 常量和文档；总目标仍未完成，可继续评估 Mac 快速新增按钮分类/轮次语义。

### v0.64 / iOS 新增入口分类上下文

日期：2026-07-06

核心变更：

- iOS 日程页 toolbar “新增待办”按钮在选中分类筛选时读出当前分类，并提示新增表单会预填该分类。
- iOS 日程页 toolbar “新增待办”按钮补齐 Voice Control input labels，支持“新增此分类”和按分类名新增。
- `scripts/verify_project.sh` 新增 `Schedule toolbar add category context contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project schedule toolbar add category context contracts` 复判。
- README、测试规范和核心流程文档同步 iOS 日程 toolbar 新增入口分类语义与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.64（iOS新增入口分类上下文）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.64 通过后可继续评估 Mac 快速新增按钮分类/轮次语义或 CI process version 固定复判。

### v0.63 / 计划面板操作语义

日期：2026-07-06

核心变更：

- iOS 自动计划面板“按日程生成”和“清空”操作补齐当前未完成计划轮数可访问标签与 Voice Control input labels。
- macOS 自动计划面板真实按钮补齐同等语义，快照静态按钮保留短可见标题并通过可访问覆盖文本保留当前轮数语义。
- `scripts/verify_project.sh` 新增 `Plan panel action accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project plan panel action accessibility contracts` 复判。
- README、测试规范和核心流程文档同步计划面板生成/清空操作语义与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.63（计划面板操作语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.63 通过后继续评估更多 UI 分类操作效率或 CI artifact 复判边界。

### v0.62 / Mac 计划分类上下文

日期：2026-07-06

核心变更：

- macOS 自动计划项副标题补齐分类文本，和 iOS 计划行保持任务、时间段、轮次、分类四类上下文一致。
- macOS 计划开始按钮可访问标签、Voice Control input labels 和快照静态按钮补齐分类语义。
- `scripts/verify_project.sh` 新增 `Mac plan category context contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project mac plan category context contracts` 复判。
- README、测试规范和核心流程文档同步 Mac 计划分类上下文与云端结果包复判范围。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.62（Mac计划分类上下文）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.62 通过后继续评估更多 UI 分类操作效率或 CI artifact 复判边界。

### v0.61 / 计划开始语义

日期：2026-07-06

核心变更：

- iOS 自动计划项开始按钮补齐任务名、时间段、轮次和分类可访问标签，并支持任务名 Voice Control input labels。
- macOS 自动计划项真实开始按钮补齐任务名、时间段和轮次可访问标签与 Voice Control input labels，快照静态按钮保留同等语义。
- `scripts/verify_project.sh` 新增 `Plan start action accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project plan start action accessibility contracts` 复判。
- README、测试规范和核心流程文档同步计划开始操作语义与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.61（计划开始语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.61 通过后继续评估更多 UI 分类操作效率或 CI artifact 复判边界。

### v0.60 / JUnit 元数据复判

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `junit metadata` 复判，要求 JUnit suite name 为 `ChronoFocus CI Results`，所有 testcase classname 为 `ChronoFocusCI`。
- `scripts/verify_project.sh` 增加 `negative_junit_metadata_fixture`，篡改 suite name 和 testcase classname 后要求 validator 输出 `FAIL junit metadata`。
- README、测试规范和核心流程文档同步 JUnit suite/classname 元数据复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.60（JUnit元数据复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.60 通过后继续评估计划项“开始”按钮任务/轮次上下文或更多 UI 分类操作效率。

### v0.59 / 日程任务操作语义

日期：2026-07-06

核心变更：

- iOS 日程任务行完成/标记未完成、启用/停用和编辑按钮补齐任务名级别可访问标签与 Voice Control input labels。
- macOS 日程任务行完成/标记未完成、启用/停用和删除控件补齐任务名级别可访问标签与 Voice Control input labels，快照静态控件同步保留语义。
- `scripts/verify_project.sh` 新增 `Schedule task action accessibility contracts verified.` 源码契约 marker 和缺失 marker 负向 fixture。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project schedule task action accessibility contracts` 复判。
- README、测试规范和核心流程文档同步日程任务操作语义与云端结果包复判范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.59（日程任务操作语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.59 通过后继续评估计划项“开始”按钮任务/轮次上下文或 JUnit suite/classname 复判增强。

### v0.58 / 快照生成时间复判

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `snapshot manifest generated at` 复判，要求 Mac 快照 manifest 的 `generatedAt` 是 ISO8601 时间。
- `scripts/verify_project.sh` 增加 `invalid_snapshot_generated_at_fixture`，把成功 fixture 的快照 manifest `generatedAt` 改为无效字符串，要求 validator 输出 `FAIL snapshot manifest generated at`。
- README、测试规范和核心流程文档同步快照 manifest 生成时间复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.58（快照生成时间复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.58 通过后继续评估任务行操作按钮任务名语义或更多分类空态操作效率。

### v0.57 / 日历日期格可访问语义

日期：2026-07-06

核心变更：

- iOS 日程页日期格补齐日期、待办数、已选中状态、非本月状态、选择提示、selected trait 和 Voice Control input labels。
- macOS 日程详情日期格补齐同等可访问语义。
- `scripts/verify_project.sh` 增加 iOS/Mac 日期格源码契约，锁定日期文本、状态文本、hint、selected trait 和语音标签。
- README、测试规范和核心流程文档同步日历日期格可访问行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.57（日历日期格可访问语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.57 通过后继续评估快照 manifest `generatedAt` 复判或任务行操作按钮任务名语义。

### v0.56 / CI 索引精确清单

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `index unexpected entries` 复判，要求 artifact index 的 entry path 集合与 `EXPECTED_INDEX_ENTRIES` 精确一致。
- `scripts/verify_project.sh` 增加 `unexpected_index_entry_fixture`，向成功 fixture 的 index 额外加入 optional missing entry，要求 validator 输出 `FAIL index unexpected entries`。
- README、测试规范和核心流程文档同步 artifact index 精确清单和未预期 entry 负向 fixture。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.56（CI索引精确清单）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.56 通过后继续评估 Mac/iOS 日历日期格可访问语义或快照 manifest `generatedAt` 复判。

### v0.55 / 当前任务语音选择标签

日期：2026-07-06

核心变更：

- iOS 计时页当前任务选择行补齐任务名、任务名待办和分类待办 Voice Control input labels。
- macOS 详细计时任务行补齐同等当前任务选择 Voice Control input labels。
- macOS 菜单栏小窗待办按钮补齐同等当前任务选择 Voice Control input labels。
- 三端未选中任务在计时运行中会提示不可切换当前待办，避免禁用状态仍读成可选择。
- `scripts/verify_project.sh` 增加三端当前任务选择语音标签和运行中提示源码契约。
- README、测试规范和核心流程文档同步当前任务选择语音控制行为。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.55（当前任务语音选择标签）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.55 通过后继续评估 CI artifact index 精确 allowlist 或日历日期格可访问语义。

### v0.54 / 当前任务选择语义

日期：2026-07-06

核心变更：

- iOS 计时页当前日程任务行补齐已选中/未选中可访问标签、选择提示和 selected trait。
- macOS 详细计时任务行补齐同等当前任务选择语义。
- macOS 小窗待办按钮补齐当前任务选择标签、提示和 selected trait。
- `scripts/verify_project.sh` 增加三端当前任务选择语义源码契约。
- README、测试规范和核心流程文档同步当前任务选择可访问性行为。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.54（当前任务选择语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.54 通过后继续评估更多分类录入效率或 CI artifact 复判细节。

### v0.53 / CI 元数据复判

日期：2026-07-06

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 manifest short SHA、workflow/project/scheme/destination、createdAt 和 project reports allowlist 复判。
- validator 新增 artifact index version 与 createdAt 复判，要求 index version 与 manifest version 一致。
- `scripts/verify_project.sh` 的小型成功 fixture 补齐 manifest/index 元数据，并新增 manifest 元数据篡改负向 fixture，要求输出 `FAIL manifest metadata`。
- README、测试规范和核心流程文档同步 CI 元数据复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.53（CI元数据复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.53 通过后继续评估当前任务选择 selected trait 或更多分类操作效率细节。

### v0.52 / Mac 分类 badge 语音标签

日期：2026-07-06

核心变更：

- macOS 详细计时任务行分类 badge 补齐分类名 Voice Control input labels。
- macOS 菜单栏小窗当前任务分类 badge 补齐分类名可访问标签和 Voice Control input labels。
- Mac 任务行和小窗分类 badge 优先使用 `TaskCategoryPreset` 预设色与图标，再回退到任务自带强调色和 `tag.fill`。
- `scripts/verify_project.sh` 增强 Mac 任务行和小窗分类 badge 源码契约，锁定预设色兜底、可访问标签和 Voice Control 输入标签。
- README、测试规范和核心流程文档同步 Mac 分类 badge 可访问语义。

关键文件：

- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.52（Mac分类Badge语音标签）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.52 通过后继续评估 CI manifest 元数据复判或当前任务选择 selected trait。

### v0.51 / Mac 快速新增保留分类

日期：2026-07-06

核心变更：

- macOS 日程详情快速新增成功后保留刚创建任务的规范化分类，便于连续录入同类待办。
- 当前存在 `selectedCategory` 时仍优先使用筛选分类；无筛选时使用 `FocusStore.addTask(...)` 返回任务的 `task.category` 和 `task.accentHex` 回填表单。
- `scripts/verify_project.sh` 增加 Mac 快速新增连续录入源码契约，锁定新增后保留分类和预设色兜底。
- README、测试规范和核心流程文档同步 Mac 连续快速新增保留分类行为。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.51（Mac快速新增保留分类）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.51 通过后继续评估 Mac 分类 badge 语义或更多分类录入效率细节。

### v0.50 / CI 额外 artifact 拒绝

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `unexpected local artifacts` 复判，拒绝 artifact 根目录、`project-reports` 和 Mac 快照目录中的未声明额外文件。
- `.xcresult` 内部保持 Xcode 原生结构兼容，不做固定文件 allowlist。
- `scripts/verify_project.sh` 增加 `unexpected_local_artifact_fixture`，复制成功 fixture 后写入 `unexpected-root.log`，要求 validator 输出 `FAIL unexpected local artifacts`。
- README、测试规范和核心流程文档同步额外 artifact 文件拒绝范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.50（CI额外artifact拒绝）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.50 通过后继续评估 Mac 分类 badge 语义或连续快速新增体验。

### v0.49 / 日程任务行分类 Voice Control

日期：2026-07-05

核心变更：

- iOS 日程页 `ScheduleTaskCell` 的分类 badge 补充分类名 Voice Control input labels。
- 日程任务行分类 badge 与计时页任务分类 badge 的语音控制语义保持一致，均支持任务分类名和“某分类”两种输入标签。
- `scripts/verify_project.sh` 增加 iOS 日程任务行分类 badge Voice Control 输入标签源码契约。
- README、测试规范和核心流程文档同步日程任务行分类语音标签范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.49（日程任务行分类VoiceControl）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.49 通过后继续评估 Mac 分类 badge 语义、连续快速新增体验或 CI artifact 额外文件拒绝能力。

### v0.48 / 分类摘要 marker 负向 fixture

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 新增 `negative_summary_marker_fixture`，复制小型成功 artifact 后移除 `Category summary action contracts verified.`。
- 该负向 fixture 要求 `scripts/validate_ci_artifact.rb` 输出 `FAIL verify_project category summary action contracts`，防止缺失分类摘要动作 marker 的结果包被放行。
- `scripts/verify_project.sh` 自检 marker 增加负向 fixture 名称和失败文案。
- README、测试规范和核心流程文档同步分类摘要 marker 缺失负向 fixture。

关键文件：

- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.48（分类摘要marker负向fixture）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.48 通过后继续评估更多分类操作效率或 CI artifact 一致性检查。

### v0.47 / 分类摘要契约日志复判

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 在分类摘要动作、按钮语义和点击区源码契约通过后输出 `Category summary action contracts verified.`。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project category summary action contracts` 复判项，要求下载的 `verify_project.log` 包含该 marker。
- `scripts/verify_project.sh` 的小型成功 fixture 同步补齐新 marker，并锁定 validator 必须包含该 marker 复判逻辑。
- README、测试规范和核心流程文档同步分类摘要动作 contract marker 复判。

关键文件：

- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.47（分类摘要契约日志复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.47 通过后继续评估更多分类操作效率或 CI artifact 一致性检查。

### v0.46 / Mac 日程摘要按钮点击区

日期：2026-07-05

核心变更：

- macOS 日程详情选中分类摘要的“新增此分类”和“清除”真实按钮增加稳定最小宽度和高度。
- Mac 快照渲染用的 `MacSummaryStaticActionView` 同步真实按钮宽高，避免快照路径与真实布局尺寸漂移。
- `scripts/verify_project.sh` 增加 Mac 日程摘要按钮点击区契约，锁定真实新增/清除按钮和快照静态按钮尺寸。
- README、测试规范和核心流程文档同步 Mac 日程摘要按钮点击区。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.46（Mac日程摘要按钮点击区）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.46 通过后继续评估更多分类操作效率或 CI artifact 一致性检查。

### v0.45 / 日程摘要按钮分类语义

日期：2026-07-05

核心变更：

- iOS 日程页选中分类摘要的“新增此分类”和“清除”按钮补齐分类名可访问标签。
- iOS 日程摘要按钮补充 Voice Control input labels，支持“新增此分类”“新增某分类待办”“新增某分类”“清除筛选”和“清除某分类”语音入口。
- macOS 日程详情选中分类摘要的真实新增/清除按钮补齐同等分类名可访问标签和 Voice Control input labels。
- `scripts/verify_project.sh` 增加 iOS/Mac 日程摘要按钮级源码契约，锁定新增/清除按钮的分类 label、Voice Control input labels 和 iOS 44pt 点击区。
- README、测试规范和核心流程文档同步日程摘要按钮分类语义。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.45（日程摘要按钮分类语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.45 通过后继续评估更多分类操作效率或 CI artifact 一致性检查。

### v0.44 / 计时页摘要清除语义

日期：2026-07-05

核心变更：

- `TimerSelectedTaskCategorySummaryView` 的“清除”按钮补齐分类名可访问标签。
- 同一按钮补充 Voice Control input labels，支持“清除筛选”和“清除某分类”语音入口。
- `scripts/verify_project.sh` 增加计时页摘要清除按钮契约，锁定按钮、44pt 点击区、分类 label 和 Voice Control input labels。
- README、测试规范和核心流程文档同步计时页摘要清除入口。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.44（计时页摘要清除VoiceControl）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.44 通过后继续评估日程摘要按钮分类语义或更多 CI artifact 一致性检查。

### v0.43 / Mac 快照 manifest 大小复判

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `snapshot byte counts` 复判，要求 Mac 快照 manifest 中每张 PNG 的 `byteCount` 等于下载 artifact 内对应文件的实际大小。
- `scripts/verify_project.sh` 锁定 validator 的 `snapshot byte counts` marker。
- `scripts/verify_project.sh` 增加快照 manifest 大小篡改负向 fixture，防止 manifest 与实际 PNG 大小不一致时被放行。
- README、测试规范和核心流程文档同步 Mac 快照 byteCount 复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.43（Mac快照byteCount复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.43 通过后继续评估计时页摘要清除按钮 Voice Control 标签、日程摘要按钮分类语义或更多 CI artifact 一致性检查。

### v0.42 / 计时页分类空态清除入口

日期：2026-07-05

核心变更：

- `TimerTaskCategoryEmptyView` 使用分类预设色彩渲染空态图标和清除按钮，未知分类回退 `#3DE8C5`。
- 空态清除按钮补齐 44pt 点击区、分类名可访问标签和 Voice Control input labels。
- 空态容器补充“暂无可启动待办，可清除筛选”的可访问说明。
- `scripts/verify_project.sh` 增加计时页分类空态清除入口契约，锁定 preset、按钮、44pt、可访问标签和 Voice Control input labels。
- README、测试规范和核心流程文档同步计时页分类空态清除入口。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.42（计时页分类空态清除可访问）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.42 通过后继续评估更多计时页分类信息密度、iOS 分类操作效率或 CI artifact 复判强度。

### v0.41 / 计时页分类 badge 可访问标签

日期：2026-07-05

核心变更：

- `TimerTaskCategoryBadge` 改用 `Label(task.category, systemImage: categorySymbolName)`，统一图标和分类文字语义。
- 计时页任务行分类 badge 补充 `accessibilityLabel` 和 Voice Control input labels，辅助技术可直接识别分类名。
- `scripts/verify_project.sh` 增加计时页分类 badge 契约，锁定 preset 匹配、Label、可访问标签和 Voice Control input labels。
- README、测试规范和核心流程文档同步计时页分类 badge 可访问语义。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.41（计时页分类badge可访问标签）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.41 通过后继续评估更多分类信息密度、空态操作或 CI 结果包一致性检查。

### v0.40 / iOS 日程任务行分类 badge

日期：2026-07-05

核心变更：

- `ScheduleTaskCell` 将纯文本分类升级为带图标、代表色和背景的分类 badge。
- 分类 badge 使用 `TaskCategoryPreset.matching(task.category)` 匹配预设图标和颜色，未知分类回退任务强调色和 `tag.fill`。
- 截止时间、循环和自动开始仍作为分类 badge 旁路元数据展示，不再与分类互相替代。
- `scripts/verify_project.sh` 增加 iOS 日程任务行分类 badge 契约，锁定分类 badge、可访问标签和 due date 旁路元数据。
- README、测试规范和核心流程文档同步 iOS 日程任务行分类上下文。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.40（iOS日程任务行分类badge）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.40 通过后继续评估更多 iOS 分类信息密度或 CI 结果包一致性检查。

### v0.39 / CI artifact index 本地元数据复算

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `index required local metadata` 复判，逐项复算下载目录中 required file 的 `byteCount` 和 directory 的 `fileCount` / `recursiveByteCount`。
- `scripts/verify_project.sh` 锁定 validator 的本地元数据复判 marker。
- `scripts/verify_project.sh` 增加本地文件大小篡改负向 fixture，防止下载产物被改动但 index 未更新时被放行。
- README、测试规范和核心流程文档同步 artifact index 本地元数据复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.39（CI-artifact-index本地元数据复算）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.39 通过后继续评估 iOS 日程任务行分类 badge 或更多 CI 结果包一致性检查。

### v0.38 / CI JUnit outcome 复判

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `junit testcase outcomes` 复判，要求每个 JUnit `system-out` 的 `outcome=` 与 manifest 对应阶段 outcome 一致。
- `scripts/verify_project.sh` 锁定 validator 的 `EXPECTED_JUNIT_OUTCOMES` 和 `junit testcase outcomes` marker。
- `scripts/verify_project.sh` 增加错误 JUnit outcome 负向 fixture，防止 JUnit 摘要与 manifest 阶段状态不一致时被放行。
- README、测试规范和核心流程文档同步 JUnit outcome 复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.38（CI-JUnit-outcome复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.38 通过后继续评估 artifact index 本地 size 复算或 iOS 日程任务行分类 badge。

### v0.37 / Mac 任务行分类 badge

日期：2026-07-05

核心变更：

- `MacTaskRowView` 改为始终显示任务分类 badge，并在任务有时间时把时间作为旁路元数据展示。
- Mac 计时详情队列和日程详情待办列表复用同一任务行，因此都会保留分类上下文。
- `scripts/verify_project.sh` 增加 Mac 任务行分类 badge 契约，防止回退到“有时间则用时间替代分类”的模式。
- README、测试规范和核心流程文档同步 Mac 任务行分类信息密度。

关键文件：

- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.37（Mac任务行分类badge）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.37 通过后继续评估 JUnit outcome 复判或 artifact index 本地 size 复算。

### v0.36 / CI failure summary 身份复判

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `failure summary identity` 复判，要求 summary 中的 version、branch、commit、run attempt 与本轮 manifest/参数一致。
- `scripts/validate_ci_artifact.rb` 新增 `failure summary outcomes` 复判，要求 summary 中四个阶段 outcome 与 manifest 对应字段一致。
- `scripts/verify_project.sh` 锁定 validator 必须包含 failure summary 身份和 outcome 复判 marker。
- README、测试规范和核心流程文档同步 failure summary 复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.36（CI-failure-summary身份复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.36 通过后继续评估 Mac 行内分类信息密度、JUnit outcome 复判或 artifact index 本地 size 复算。

### v0.35 / 分类预设按钮可访问语义

日期：2026-07-05

核心变更：

- iOS 新建/编辑待办的常用分类预设按钮补充分类 label、已选中状态、选择提示、selected trait 和 Voice Control input labels。
- macOS 快速新增表单的常用分类预设按钮补充同样的可访问语义。
- `scripts/verify_project.sh` 增加 iOS/Mac 分类预设按钮可访问契约，云端项目验证会锁定对应实现。
- README、测试规范和核心流程文档同步分类预设按钮可访问范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.35（分类预设按钮可访问语义）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.35 通过后继续评估 Mac 行内分类信息密度或 CI failure summary 身份复判。

### v0.34 / 分类摘要动作可访问提示

日期：2026-07-05

核心变更：

- iOS 日程页选中分类摘要的可访问标签补充“可新增此分类待办或清除筛选”。
- iOS 计时页选中分类摘要的可访问标签补充“可清除筛选”。
- `scripts/verify_project.sh` 增加摘要动作可访问提示静态契约，云端项目验证会锁定对应文案。
- README、测试规范和核心流程文档同步筛选摘要动作提示范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.34（分类摘要动作可访问提示）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.34 通过后继续寻找更多 UI 分类细节优化点或 CI 结果包复判薄弱点。

### v0.33 / CI Xcode 版本日志复判

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `xcode version log` 复判项，要求下载的 `xcode-version.log` 包含 `Xcode` 和 `Build version`。
- `scripts/verify_project.sh` 的 validator 正向 fixture 同步补齐 `Build version`，并锁定 validator 必须包含 Xcode 版本日志复判。
- README、测试规范和核心流程文档同步 Xcode 版本日志复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.33（CI-Xcode版本日志复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.33 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.32 / 分类筛选 Voice Control 标签

日期：2026-07-05

核心变更：

- iOS 日程页、iOS 计时页和 macOS 日程详情的分类筛选 chip 增加 Voice Control input labels。
- 输入标签使用分类名和“分类名分类”，让语音控制可直接按分类名触发筛选，不需要说出数量或状态。
- 保留可见 UI、重复点击清除筛选、VoiceOver label/hint 和 selected trait 行为。
- `scripts/verify_project.sh` 的三端分类 chip 可访问 contract 增加 input labels 源码检查。
- README、测试规范和核心流程文档同步分类 chip Voice Control 标签行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.32（分类筛选Voice Control标签）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.32 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.31 / CI 静态检查日志复判

日期：2026-07-05

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `static checks log markers` 复判项，要求下载的 `static-checks.log` 包含 whitespace、plist lint、workflow YAML parse 和 `yaml ok` marker。
- `scripts/verify_project.sh` 的 validator 正向 fixture 同步补齐 static-checks 三段日志 marker，并锁定 validator 必须包含 `EXPECTED_STATIC_CHECK_MARKERS`。
- README、测试规范和核心流程文档同步 static-checks 日志 marker 复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.31（CI静态检查日志复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.31 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.30 / 分类筛选 selected trait

日期：2026-07-05

核心变更：

- iOS 日程页、iOS 计时页和 macOS 日程详情的分类筛选 chip 在选中时暴露 `.isSelected` 可访问 trait。
- 保留 v0.28 的可访问 label/hint 文案和 v0.26 的重复点击清除筛选行为。
- `scripts/verify_project.sh` 的三端分类 chip 可访问 contract 增加 selected trait 源码检查。
- README、测试规范和核心流程文档同步分类 chip selected trait 行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.30（分类筛选selected trait）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.30 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.29 / CI 分类可访问日志复判

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 在三端分类 chip 可访问源码 contract 通过后输出稳定日志 marker。
- `scripts/validate_ci_artifact.rb` 新增 `verify_project category accessibility contracts` 复判项，要求下载的 `verify_project.log` 包含该 marker。
- `verify_project.sh` 同步锁定 validator 必须包含分类可访问 marker 复判逻辑。
- README、测试规范和核心流程文档同步 CI 结果包对分类可访问 contract marker 的复判行为。

关键文件：

- `scripts/verify_project.sh`
- `scripts/validate_ci_artifact.rb`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.29（CI分类可访问日志复判）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.29 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.28 / 分类筛选可访问提示

日期：2026-07-05

核心变更：

- iOS 日程页、iOS 计时页和 macOS 日程详情的分类筛选 chip 补充可访问状态与操作提示。
- VoiceOver label 现在包含分类名、数量和“已选中”状态。
- VoiceOver hint 会区分“筛选此分类”“再次点击清除筛选”“显示全部分类”和“当前显示全部分类”。
- `scripts/verify_project.sh` 增加三端分类 chip 可访问 label/hint 源码 contract。
- README、测试规范和核心流程文档同步分类筛选可访问提示行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.28（分类筛选可访问提示）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.28 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.27 / Mac 分类摘要快捷新增

日期：2026-07-05

核心变更：

- macOS 日程详情选中分类摘要新增“新增此分类”入口。
- 点击“新增此分类”时不直接创建空任务，而是把左侧快速新增表单切回当前筛选分类、同步预设色并聚焦任务名称输入框。
- 保留原有“清除”、分类 chip 重复点击退出筛选、左侧快速新增预填提示和真实 `addTask` 逻辑。
- `scripts/verify_project.sh` 增加 Mac 分类摘要新增入口、父视图动作传递、预填分类和聚焦标题输入的源码 contract。
- README、测试规范和核心流程文档同步 Mac 分类摘要快捷新增行为。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.27（Mac分类摘要快捷新增）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.27 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.26 / 分类筛选点击切换与 CI 索引汇总校验

日期：2026-07-05

核心变更：

- iOS 日程页、iOS 计时页和 macOS 日程详情页的分类筛选 chip 支持重复点击已选分类后退出筛选。
- 保留原有“全部”、筛选摘要清除、iOS 新增此分类和 Mac 快速新增预填行为，只减少退出筛选的操作成本。
- `scripts/validate_ci_artifact.rb` 新增 artifact index totals 与 entries 聚合一致性复算，覆盖 entryCount、missingRequiredCount、fileByteCount 和 directoryRecursiveByteCount。
- `scripts/verify_project.sh` 增加三端分类 chip 点击切换源码 contract，并新增 artifact index totals 篡改负向 fixture。
- README、测试规范和核心流程文档同步分类点击切换与 index totals 校验范围。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocus/Views/TimerView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.26（分类筛选点击切换与CI索引汇总校验）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.26 通过后继续寻找更多 UI 分类细节优化点或 StoreKit/EventKit 自动化测试替身。

### v0.25 / iOS 日程筛选计数

日期：2026-07-05

核心变更：

- iOS 日程页待办列表标题右侧新增筛选计数反馈。
- 未选中分类时继续显示当前日/周/月范围总数；选中分类且当前范围有待办时显示 `筛选数/总数 项`。
- 当前时间范围总数为 0 时显示 `0 项`，避免旧筛选状态下出现 `0/0`。
- 计数文本加上 caption、单行和缩放约束，降低窄屏挤压风险。
- `scripts/verify_project.sh` 增加 iOS 日程筛选计数属性片段 marker。
- README、测试规范和核心流程文档同步 iOS 日程筛选计数行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.25（iOS日程筛选计数）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.25 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.24 / CI 索引身份负向 fixture

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 在 validator 小型成功 fixture、artifactName mismatch 负向 fixture 和本地缺失产物负向 fixture 之外，新增 artifact index 身份错包负向 fixture。
- 新负向 fixture 复制成功 artifact 目录后篡改 `ci-artifact-index.json` 的 `commitSha`，确认 validator 会拒绝 index 身份与本轮 commit 不一致的结果包。
- 负向检查显式匹配 `FAIL index commit`，避免 validator 因其他失败原因被误认为覆盖目标场景。
- README、测试规范和核心流程文档同步 validator 成功、artifactName 错包、index 身份错包和残缺下载四类 fixture 覆盖范围。

关键文件：

- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.24（CI索引身份负向fixture）.md`
- `update_log.md`

验证结果：

- 未运行本地测试命令；人工明确要求“不得在本地测试，都去云端”。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.24 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.23 / CI 本地缺失产物负向 fixture

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 在 validator 小型成功 fixture 和 artifactName mismatch 负向 fixture 后新增本地缺失产物负向 fixture。
- 新负向 fixture 复制成功 artifact 目录后删除 `static-checks.log`，保留 artifact index 原样，确认 validator 会检查下载后本地文件完整性。
- 负向检查显式匹配 `FAIL index required local artifacts`，避免 validator 因其他失败原因被误认为覆盖目标场景。
- README、测试规范和核心流程文档同步 validator 成功、错包和残缺下载三类 fixture 覆盖范围。

关键文件：

- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.23（CI本地缺失产物负向fixture）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.23 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.22 / Mac 待办筛选计数

日期：2026-07-05

核心变更：

- macOS 日程详情待办列表标题右侧新增筛选计数反馈。
- 未选中分类时继续显示总未完成数；选中分类时显示 `筛选数/总数 项未完成`。
- 当前未完成总数为 0 时显示 `0 项未完成`，避免旧筛选状态下出现 `0/0`。
- 计数文本加上 caption、单行和缩放约束，降低详细窗口较窄时的挤压风险。
- `scripts/verify_project.sh` 增加 Mac 待办筛选计数属性片段 marker。
- README、测试规范和核心流程文档同步 Mac 待办筛选计数行为。

关键文件：

- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.22（Mac待办筛选计数）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已查看 `/tmp/chronofocus-mac-snapshots/detail-schedule.png`，未见黄色缺失控件占位、明显裁切或挤压。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.22 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.21 / 分类摘要测试收紧

日期：2026-07-05

核心变更：

- `scripts/verify_project.sh` 新增分类摘要源码 contract 检查，覆盖 iOS 日程页、iOS 计时页和 macOS 日程详情。
- 新增源码片段检查，确认三个分类摘要插入点都早于对应空态分支，避免摘要落入不可达 UI。
- 新增动作接线检查，在摘要调用点到空态分支之前的片段内确认 iOS 日程摘要能打开新增 sheet 和清除筛选，iOS 计时摘要走统一清除函数，Mac 日程摘要能清空筛选。
- README、测试规范和核心流程文档同步分类摘要插入点/动作接线检查范围。

关键文件：

- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.21（分类摘要测试收紧）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.21 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.20 / 计时页分类筛选摘要

日期：2026-07-05

核心变更：

- iOS 计时页“当前日程”面板在选中分类后显示筛选摘要。
- 摘要展示分类图标、分类名、当前可启动待办数和“清除”入口，让有任务分类、空分类和当前待办变为 0 的旧筛选状态都能直接退出筛选。
- `TimerTaskCategoryEmptyView` 的清除动作统一走 `clearTaskCategoryFilter()`，避免散落第二套筛选状态。
- `scripts/verify_project.sh` 增加计时页分类筛选摘要、可启动数量、accessibility 文案 marker 和摘要清除动作接线检查。
- README、测试规范和核心流程文档同步计时页分类筛选摘要行为。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.20（计时页分类筛选摘要）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.20 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.19 / CI 结果包负向 fixture

日期：2026-07-04

核心变更：

- `scripts/verify_project.sh` 在 validator 小型成功 fixture 后新增 artifactName mismatch 负向 fixture。
- 负向 fixture 复制小型 artifact 目录并覆写 `ci-run-context.txt` 的 artifactName，确认 `scripts/validate_ci_artifact.rb` 必须返回失败。
- 负向检查显式匹配 `FAIL run context artifact name`，避免 validator 因其他原因失败时被误认为覆盖到目标场景。
- README、测试规范和核心流程文档同步 validator 正向/负向 fixture 覆盖范围。

关键文件：

- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.19（CI结果包负向fixture）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -c scripts/validate_ci_artifact.rb`，输出 `Syntax OK`。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已用 v0.18 最新下载结果包运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28712188602 --commit 10c041f7d0a2ddd95de02a00643725f9f25cd809 --run-id 28712188602 --attempt 1`，输出全 PASS。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.19 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.18 / CI 运行上下文复判

日期：2026-07-04

核心变更：

- `scripts/validate_ci_artifact.rb` 新增 `ci-run-context.txt` 解析，按 key 核对 artifactName、branch、commitSha、runId 和 runAttempt。
- validator 根据 manifest version、branch slug、短 SHA、run id 和 attempt 计算预期 artifact 名称，防止结果包身份与下载 run 脱节。
- `scripts/verify_project.sh` 的小型 artifact fixture 补齐 artifactName，并增加 run context 相关 marker。
- README、测试规范和核心流程文档同步 run context / artifact 名称复判范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.18（CI运行上下文复判）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -c scripts/validate_ci_artifact.rb`，输出 `Syntax OK`。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已用 v0.17 最新下载结果包运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28711609373 --commit 4e4e02de23856f914c71f1647663906d6b80de30 --run-id 28711609373 --attempt 1`，输出包含 run context 检查的全 PASS。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.18 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.17 / 分类筛选快捷新增

日期：2026-07-04

核心变更：

- iOS 日程页选中分类后，筛选摘要新增“新增此分类”入口，直接打开新增待办 sheet 并沿用当前分类预填。
- iOS 分类空态文案改为指向摘要内快捷新增入口，减少用户返回右上角新增的绕行。
- macOS 日程详情左侧快速新增面板在选中分类时显示“已预填该分类”提示，让已有预填行为更明确。
- `scripts/verify_project.sh` 增加 iOS 分类快捷新增和 Mac 预填提示 marker。
- README、测试规范和核心流程文档同步当前 UI 分类行为。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（持续优化）/v0.17（分类筛选快捷新增）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已查看 `/tmp/chronofocus-mac-snapshots/detail-schedule.png`，未见黄色缺失控件占位、明显裁切或挤压。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.17 通过后继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.16 / CI 结果包校验收紧

日期：2026-07-04

核心变更：

- `scripts/validate_ci_artifact.rb` 显式核对 manifest 关键路径字段、artifact index 必需路径和 kind、下载后本地文件/目录非空状态。
- validator 增加 JUnit 四个 testcase 名称与日志入口、failure summary 日志入口和 Mac 快照本地文件存在性检查。
- `scripts/verify_project.sh` 增加小型 CI artifact fixture，覆盖 validator 新增路径 contract。
- README、测试规范和核心流程文档同步结构化复判覆盖范围。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/prompt/v0（持续优化）/v0.16（CI结果包校验收紧）.md`
- `update_log.md`

验证结果：

- 已运行 `ruby -c scripts/validate_ci_artifact.rb`，输出 `Syntax OK`。
- 已用 v0.15 最新下载结果包运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28709905752 --commit dd52b6a0c55ea13b8e94d9cae94d7d0954b48a92 --run-id 28709905752 --attempt 1`，输出全 PASS。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.16 通过后可继续寻找更多 UI 分类细节优化点或补 StoreKit/EventKit 自动化测试替身。

### v0.15 / StoreKit 与日历同步本地说明

日期：2026-07-04

核心变更：

- README 增加 StoreKit 2 商品配置、App Store Connect sandbox / StoreKit 配置要求、失败状态和禁止伪造 Pro 权益的说明。
- README 增加 EventKit 日历同步的权限、日程 UI Pro gating、从今天零点起 45 天范围内非全天事件导入规则和手工验证步骤。
- `md/test/test.md` 增加 StoreKit / EventKit 本地人工验证边界，明确默认 CI 不访问真实 App Store 或系统日历数据。
- `md/flow/flow.md` 和遗留问题同步为“已有配置说明，自动化 mock 后续可补”。

关键文件：

- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/prompt/v0（持续优化）/v0.15（StoreKit日历本地说明）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.15 通过后可继续收紧 CI artifact 校验脚本或寻找更多 UI 分类细节优化点。

### v0.14 / iOS 模拟器构建基线

日期：2026-07-04

核心变更：

- 新增 `scripts/resolve_ios_simulator_destination.rb`，从 `xcrun simctl list devices available -j` 解析可用 iOS Simulator destination。
- 脚本支持 `--simctl-json` fixture、`--name` 指定设备优先级和 `--print-build-command` 打印完整本机 iOS simulator build 命令。
- 脚本会在 `DEVELOPER_DIR` 未设置且本机存在完整 Xcode 时自动使用 `/Applications/Xcode.app/Contents/Developer`，降低 Command Line Tools 环境下找不到 `simctl` 的概率；打印 build 命令时会尊重用户已有 `DEVELOPER_DIR`。
- `scripts/verify_project.sh` 增加脚本语法、关键标记和小型 simctl JSON fixture 解析检查。
- README 和测试规范增加本机 iOS simulator destination 与 build 命令说明。

关键文件：

- `scripts/resolve_ios_simulator_destination.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.14（iOS模拟器构建基线）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -c scripts/resolve_ios_simulator_destination.rb`，输出 `Syntax OK`。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已用内置 fixture 验证 `scripts/resolve_ios_simulator_destination.rb` 默认选择 Booted iOS simulator，指定 `--name` 时优先选择指定设备，并能打印包含该 destination 的 iOS simulator build 命令。
- 已运行脱沙箱只读命令 `ruby scripts/resolve_ios_simulator_destination.rb --print-build-command`，成功输出包含本机 iOS Simulator UDID 的 `xcodebuild` 命令；完整本机 iOS simulator build 未默认运行。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.14 通过后继续寻找 StoreKit/EventKit 本地 mock 说明或更多 UI 分类细节优化点。

### v0.13 / CI 结果包校验脚本

日期：2026-07-04

核心变更：

- 新增 `scripts/validate_ci_artifact.rb`，用于 Agent C 下载 CI artifact 后做结构化复判。
- 校验覆盖 manifest branch/commit/run/attempt、各阶段 outcome、artifact index required entries、JUnit、failure summary、`verify_project.log`、Mac/iOS build 成功标记和 Mac 快照 manifest。
- `scripts/verify_project.sh` 增加结果包校验脚本语法和关键标记检查。
- README、测试规范和核心流程文档增加脚本使用说明。

关键文件：

- `scripts/validate_ci_artifact.rb`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.13（CI结果包校验脚本）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -c scripts/validate_ci_artifact.rb`，输出 `Syntax OK`。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已用 v0.12 下载结果包运行 `ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-28706344917 --commit 2332c2a8feee9c71bb68147da4872de2c435109d --run-id 28706344917 --attempt 1`，输出全 PASS。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.13 通过后继续寻找 StoreKit/EventKit 本地 mock 说明、iOS 模拟器构建基线或更多 UI 分类细节优化点。

### v0.12 / Mac 小窗分类上下文

日期：2026-07-04

核心变更：

- macOS 小窗“当前待办”任务行同时展示任务标题、分类 badge 和时间/轮次上下文。
- 分类 badge 使用 `FocusTask.category`、任务强调色和 `TaskCategoryPreset.matching` 的图标信息，让小窗选任务时能快速区分分类。
- 无时间任务会显示“只设开始”或剩余轮次，避免右侧信息空白。
- `scripts/verify_project.sh` 增加 Mac 小窗分类 badge、上下文 helper 和分类预设匹配标记检查。

关键文件：

- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.12（Mac小窗分类上下文）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已查看 `/tmp/chronofocus-mac-snapshots/mini-timer.png`，三条任务行和分类 badge 完整可见，未见黄色缺失控件占位。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.12 通过后继续寻找 StoreKit/EventKit 本地 mock 说明、iOS 模拟器构建基线或更多 UI 分类细节优化点。

### v0.11 / iOS 铃声选择

日期：2026-07-04

核心变更：

- iOS 设置页新增“铃声与音色”区域，支持查看当前音色、Pro 解锁后选择全部 `CompletionSound` 音色，并提供 App 内试听入口。
- 非 Pro 状态会在 iOS 根视图和设置页自动把 Pro 音色回退为默认 `.chime`，避免持久保留未解锁音色。
- iOS `NotificationService` 的 App 内完成提示音和试听音改为按 `TimerSettings.completionSound` 生成不同频率、时长和包络的音色；后台系统本地通知仍使用系统默认通知声。
- `scripts/verify_project.sh` 增加 iOS 设置页音色选择、试听、根视图非 Pro 回退和 iOS 通知音色生成标记检查。

关键文件：

- `ChronoFocus/Views/SettingsView.swift`
- `ChronoFocus/Views/DashboardView.swift`
- `ChronoFocus/Services/NotificationService.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.11（iOS铃声选择）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.11 通过后继续寻找下一轮 Mac 小窗任务上下文、StoreKit/EventKit 本地 mock 说明或 CI 验收体验优化点。

### v0.10 / CI 结果包索引

日期：2026-07-04

核心变更：

- `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION` 更新为 v0.10。
- CI 结果包新增 `ci-artifact-index.json`，记录关键 artifact 文件和目录的存在性、类型、字节数、目录递归字节数和文件数量。
- `ci-artifact-manifest.json` 新增 `artifactIndexPath`，并在 `projectSpecificReports` 中登记 `artifact_index`。
- artifact index 覆盖 manifest、summary、JUnit、静态检查日志、项目验证日志、Mac/iOS build 日志、Xcode 版本、run context、Mac/iOS `.xcresult`、Mac 快照目录、快照 manifest 和五张 Mac 快照。
- `scripts/verify_project.sh` 增加 artifact index workflow 标记检查。

关键文件：

- `.github/workflows/ci-results.yml`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.10（CI结果包索引）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 workflow 内嵌 Python 编译检查，输出 `embedded python ok`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.10 通过后继续寻找下一轮 Mac 小窗任务上下文、iOS 铃声选择或 UI 分类细节优化点。

### v0.9 / 计时页分类筛选待办

日期：2026-07-04

核心变更：

- iOS 计时页“当前日程”面板新增分类筛选 chip，可按当前待办分类快速筛选任务。
- 计时页分类筛选复用 `TaskCategoryPreset.prioritizedFilterOptions`，按当前可启动待办数量优先显示有任务分类。
- 选中分类时任务列表只显示该分类待办，空分类显示清除筛选入口。
- 计时页任务行新增分类 badge，即使任务有开始时间也能直接看到分类。
- `scripts/verify_project.sh` 增加计时页分类筛选、过滤列表和分类 badge 标记检查。

关键文件：

- `ChronoFocus/Views/TimerView.swift`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.9（计时页分类筛选待办）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 本轮未默认运行完整本机 Xcode build；最终 Mac/iOS 编译结论以本轮 push 后 GitHub Actions artifact 为准。

遗留事项：

- 总目标仍未完成；v0.9 通过后继续寻找下一轮 Mac 小窗任务上下文、iOS 铃声选择或 CI artifact 完整性优化点。

### v0.8 / Mac 快捷入口与 CI 错误摘录

日期：2026-07-04

核心变更：

- macOS 小窗快捷面板的“日程”“统计”“设置”入口会直接打开或切换到对应详情 Tab。
- `MacStatusBarController` 持有共享 `MacDetailSelection`，详情窗口已打开时复用窗口并更新选中 Tab。
- 右键菜单和 `CHRONOFOCUS_MAC_OPEN_DETAILS` 仍默认打开计时详情。
- `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION` 更新为 v0.8。
- `ci-failure-summary.md` 在任一阶段失败时追加 `Failure Excerpts`，按阶段从对应日志摘录有限关键错误行。
- `scripts/verify_project.sh` 增加 Mac 小窗直达详情入口和 CI 错误摘录实现标记检查。

关键文件：

- `ChronoFocusMac/App/MacStatusBarController.swift`
- `ChronoFocusMac/Views/MacDetailView.swift`
- `ChronoFocusMac/Views/MacMiniTimerView.swift`
- `scripts/render_mac_snapshots.swift`
- `.github/workflows/ci-results.yml`
- `scripts/verify_project.sh`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.8（Mac快捷入口与CI错误摘录）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已查看 `/tmp/chronofocus-mac-snapshots/mini-timer.png`，小窗快捷面板布局正常，未见黄色缺失控件占位。
- 已运行 `python3 -m json.tool /tmp/chronofocus-mac-snapshots/manifest.json`，确认 5 张快照均有正数尺寸和字节数。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.8 通过后继续寻找下一轮 iOS 分类入口、Mac 小窗任务上下文或 CI artifact 完整性优化点。

### v0.7 / 分类筛选摘要与快照清单

日期：2026-07-04

核心变更：

- iOS 日程待办列表在选中分类时显示筛选摘要，包含分类名、当前范围数量和一键清除入口。
- macOS 日程详情待办列表同步增加选中分类摘要，并在快照渲染时使用静态清除 chip。
- 选中分类且列表为空时，iOS/macOS 空态文案明确提示可清除筛选或新增该分类待办。
- Mac 快照脚本生成 `/tmp/chronofocus-mac-snapshots/manifest.json`，记录 5 张快照的文件名、像素尺寸、字节数和生成时间。
- `scripts/verify_project.sh` 检查分类摘要实现标记、快照 manifest 存在性和 5 张快照元数据。
- `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION` 更新为 v0.7，并在 artifact manifest 中记录 `mac_snapshot_manifest`。

关键文件：

- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `scripts/render_mac_snapshots.swift`
- `scripts/verify_project.sh`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（持续优化）/v0.7（分类筛选摘要与快照清单）.md`
- `update_log.md`

验证结果：

- 已运行 `git diff --check`，通过。
- 已运行 `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`，输出 `yaml ok`。
- 已运行 `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`，输出 `ChronoFocus.xcodeproj/project.pbxproj: OK`。
- 已运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照和 `/tmp/chronofocus-mac-snapshots/manifest.json`。
- 已查看 `/tmp/chronofocus-mac-snapshots/manifest.json`，包含 `mini-timer.png`、`detail-timer.png`、`detail-schedule.png`、`detail-analytics.png`、`detail-settings.png` 五个条目，且每项有正数尺寸和字节数。
- 云端结论以本轮 push 后 Agent C 下载的最新 `origin/main` artifact 为准。

遗留事项：

- 总目标仍未完成；v0.7 通过后继续寻找下一轮 UI 和 CI 优化点。

### v0.6 / 优化分类新建预填和筛选排序

日期：2026-07-04

核心变更：

- 新增非持久化 `TaskCategoryFilterOption` 和 `TaskCategoryPreset.prioritizedFilterOptions`，让分类筛选按当前范围内任务数量优先展示有任务分类。
- iOS 日程页选中分类后新增待办会自动预填该分类和匹配预设色；编辑已有待办不受当前筛选影响。
- macOS 日程详情把待办分类筛选状态上提，选中分类时同步快速新增区域的分类和预设色。
- iOS 分类筛选 chip 和常用分类快选按钮提升到 44pt 最小高度。
- Mac 计时详情页在快照渲染时使用静态操作按钮，避免 CI `ImageRenderer` 将原生按钮渲为黄色缺失控件占位。
- Mac 日程详情页在快照渲染时使用静态日程操作 chip 和启用状态 pill，覆盖快速新增、日历导航、日历同步、计划操作和任务列表启用控件。
- Mac 统计详情页在快照渲染时使用静态统计操作 chip，覆盖 Pro 预览态购买/恢复按钮。
- Mac 设置详情页在快照渲染时使用静态设置操作 chip，覆盖通知授权、Pro 购买/恢复和铃声试听按钮。
- `scripts/test_mac_core.swift` 增加空白分类归一、默认分类顺序、预设元数据、筛选排序和 fallback 元数据断言。
- `scripts/verify_project.sh` 增加分类排序 helper、新建预填、44pt 点击高度和 macOS binding/onChange 标记检查。
- `.github/workflows/ci-results.yml` 的 `CI_PROCESS_VERSION` 更新为 v0.6。

关键文件：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Views/ScheduleView.swift`
- `ChronoFocusMac/Views/MacScheduleDetailView.swift`
- `ChronoFocusMac/Views/MacTimerDetailView.swift`
- `ChronoFocusMac/Views/MacAnalyticsDetailView.swift`
- `ChronoFocusMac/Views/MacSettingsDetailView.swift`
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
- 首次本地运行 `bash scripts/verify_project.sh` 发现新增 grep 标记在 `set -u` 下误展开 `$selectedCategory`，已改为单引号字面量。
- 修复后本地运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照。
- 首次 v0.6 云端 run `28682521455` 的 static、Mac build 和 iOS build 成功，但 project verification 因 `detail-timer.png` missing-control placeholder 失败。
- 已将 Mac 计时详情页操作按钮加入快照安全静态路径，并重新本地运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`。
- v0.6 修复提交云端 run `28701309467` 的 static、Mac build 和 iOS build 成功，但 project verification 因 `detail-schedule.png` missing-control placeholder 失败。
- 已将 Mac 日程详情页快速新增、日历导航、日历同步、计划操作、任务列表启用状态加入快照安全静态路径。
- v0.6 第二次追加修复云端 run `28702188484` 的 static、Mac build 和 iOS build 成功，但 project verification 因 `detail-settings.png` missing-control placeholder 失败。
- 已将 Mac 设置详情页通知授权、高级功能和 Pro 铃声按钮加入快照安全静态路径；同时补强 Mac 统计详情页 Pro 预览态购买/恢复按钮的快照安全路径。
- 已重新运行 `git diff --check`，通过。
- 已重新运行 `bash scripts/verify_project.sh`，输出 `Project structure verified.`，并生成 5 张 Mac 快照。
- 已查看 `/tmp/chronofocus-mac-snapshots/detail-schedule.png`，分类快选、快速新增区域、日历导航、日历同步和计划按钮显示正常，未见黄色缺失控件占位。
- 已查看 `/tmp/chronofocus-mac-snapshots/detail-settings.png`，设置开关、音量、铃声和授权按钮显示正常，未见黄色缺失控件占位。
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
