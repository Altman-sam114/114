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
- 当前本地项目专属验证入口是 `bash scripts/verify_project.sh`，会检查项目结构、关键实现标记、计时页/日程页分类筛选摘要/预填/排序/快捷新增标记、iOS/Mac 日程日期格可访问语义、iOS/Mac 日程摘要按钮分类语义、Mac 日程摘要按钮点击区、计时页分类摘要清除入口、计时页分类空态清除入口、计时页分类 badge 可访问标签、iOS/Mac 当前任务选择 selected trait、提示、运行中不可切换提示与 Voice Control 输入标签、统计分类投入占比语义、分类 chip 点击切换、分类预设按钮可访问语义、可访问提示、selected trait 和 Voice Control input labels、摘要动作可访问提示、iOS 日程筛选计数、iOS 日程 toolbar 新增入口分类语义、iOS 日程任务行分类 badge 与 Voice Control 输入标签、iOS/Mac 日程任务行操作按钮任务名语义、iOS/Mac 计划项开始按钮任务名/时间段/轮次语义、iOS/Mac 计划面板生成/清空操作当前轮数语义、Mac 快速新增提交按钮分类/轮次语义、Mac 小窗快捷面板按钮语义、Mac 计划项分类上下文、分类摘要插入点和动作接线、Mac 待办筛选计数、Mac 任务行和小窗分类 badge 预设色兜底与 Voice Control 输入标签、Mac 分类摘要快捷新增、Mac 连续快速新增保留分类、Mac 分类预填提示、iOS 设置页音色选择、Mac 小窗分类上下文、CI 结果包校验脚本与小型成功、manifest artifactName 复判、旧 process version 负向、分类摘要 marker 缺失负向、日程任务操作 marker 缺失负向、计划开始 marker 缺失负向、Mac 计划分类 marker 缺失负向、计划面板操作 marker 缺失负向、日程 toolbar 新增 marker 缺失负向、Mac 快速新增 marker 缺失负向、Mac 小窗快捷面板 marker 缺失负向、统计分类占比 marker 缺失负向、JUnit 元数据负向、JUnit errors 负向、JUnit outcome 负向、JUnit failure/error 元素负向、artifactName mismatch 负向、manifest artifactName 负向、manifest 元数据负向、artifact index 身份错包负向、artifact index totals 篡改负向、artifact index 未预期 entry 负向、额外 artifact 文件负向、本地文件大小篡改负向、本地缺失产物负向 fixture、快照 manifest generatedAt 无效负向 fixture、快照 manifest 大小篡改负向 fixture、run context 复判、固定 CI process version、分类摘要动作/分类可访问/日程任务操作/计划开始/Mac 计划分类/计划面板操作/日程 toolbar 新增/Mac 快速新增/Mac 小窗快捷面板/统计分类占比 contract 日志复判、Mac 核心测试、Mac UI 快照和快照 manifest generatedAt/byteCount 复判。
- 当前默认协作体系要求后续按 Agent A/B/C 云端闭环迭代：Agent A 产出版本化实现提示词，Agent B 基于最新 `origin/main` 实现、本地轻量检查、commit 并 push 到 `origin/main`，GitHub Actions 生成未加密 CI 结果包，Agent C 下载 artifact 并核对 manifest、run context、artifact 名称、日志和产物；失败时退回 Agent B 在 `main` 追加修复 commit。可由 Agent X 围绕人工总目标拆分多轮并调度 A/B/C 闭环。
- 当前云端 CI 结果包覆盖静态检查、项目验证、`ChronoFocusMac` build、`ChronoFocus` iOS generic build、manifest artifactName、manifest short SHA、固定 CI process version、workflow/project/scheme/destination 元数据、project reports、artifact index version/createdAt、entry 精确清单、本地元数据复算、index totals 一致性、额外 artifact 文件拒绝、run context、JUnit suite/classname 元数据、errors 计数、outcome 和 failure/error 元素拒绝、failure summary 身份/outcome、static-checks 日志 marker、Xcode 版本日志、分类摘要动作 contract marker、分类可访问 contract marker、日程任务操作 contract marker、计划开始 contract marker、Mac 计划分类上下文 contract marker、计划面板操作 contract marker、日程 toolbar 新增 contract marker、Mac 快速新增 contract marker、Mac 小窗快捷面板 contract marker、统计分类占比 contract marker、Mac 快照 manifest generatedAt/byteCount 复判和失败阶段关键错误摘录。

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
