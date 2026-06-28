# AGENT.md

本文是 ChronoFocus 项目的入口记忆、总览、基本规则和多 Agent 迭代工作流。后续 Codex/Agent 开始任务前必须先读本文件，再按任务范围读取相关文档和源码。

## 1. 项目一句话总览

ChronoFocus 是一个 SwiftUI 番茄钟 App 原型，包含 iOS 主 App、iOS Live Activity 扩展和 macOS 状态栏 App；核心模型、计时状态机、计划生成、统计和持久化逻辑共享，平台能力通过 iOS/macOS 专用服务隔离。

## 2. 必读文件

按顺序阅读：

1. `AGENT.md`：入口规则、协作流程、禁止项。
2. `update_log.md`：版本记录、历史决策、遗留问题。
3. `md/flow/flow.md`：当前真实架构、核心数据流、执行流。
4. `md/flow/flowchart.md`：核心逻辑和 Agent 迭代流程图。
5. `md/test/test.md`：测试分层、命令、触发条件、当前基线。
6. `README.md`：用户视角功能、打开方式、本地验证。
7. 任务相关源码、脚本、最近 git 记录。

## 3. 项目基本规则

- 使用 SwiftUI 和 Swift 并发/平台原生 API；不要引入第三方依赖，除非用户明确要求。
- 共享业务逻辑，平台层分离。不要为 Mac 版或 iOS 版复制一套核心模型、计时状态机、统计逻辑或计划生成逻辑。
- `TimerEngine` 是唯一计时状态机；开始、暂停、恢复、跳过、完成、自动流转必须从这里进入。
- `FocusStore` 是核心数据仓库；任务、设置、会话、计划和活跃计时快照都通过它持久化到 `UserDefaults` JSON。
- 平台服务必须通过抽象边界接入：通知使用 `TimerNotificationServicing`，Live Activity/占位服务使用 `TimerLiveActivityServicing`。
- 新增共享模型字段必须使用向后兼容解码，例如 `decodeIfPresent` 加默认值。
- 不做无关重构，不回滚用户或其他 Agent 的改动，不伪造测试结果。
- 手写文件修改使用 `apply_patch`；大规模格式化或构建产物生成可以使用项目脚本。

## 4. 核心架构边界

共享层：

- `ChronoFocus/Models/AppModels.swift`
- `ChronoFocus/Services/FocusStore.swift`
- `ChronoFocus/Services/TimerEngine.swift`
- `ChronoFocus/Services/TimerPlatformServices.swift`
- `Shared/SharedExtensions.swift`
- `Shared/PomodoroActivityAttributes.swift`

iOS 平台层：

- `ChronoFocus/ChronoFocusApp.swift`
- `ChronoFocus/Views/*`
- `ChronoFocus/Services/NotificationService.swift`
- `ChronoFocus/Services/LiveActivityService.swift`
- `ChronoFocus/Services/CalendarSyncService.swift`
- `ChronoFocus/Services/PremiumAccessService.swift`
- `ChronoFocusLiveActivity/*`

macOS 平台层：

- `ChronoFocusMac/App/*`
- `ChronoFocusMac/Services/*`
- `ChronoFocusMac/Views/*`

禁止跨边界直接依赖：macOS target 不直接依赖 UIKit 或真实 ActivityKit UI 行为；iOS target 不直接依赖 AppKit。

## 5. 标准迭代工作流

项目采用“人工目标 -> Agent A 设计提示词 -> Agent B 实现测试 -> Agent C 验收并更新核心逻辑文档 -> 人工复核 -> 下一轮”的循环。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成可执行实现提示词。

必须完成：

- 阅读 `AGENT.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md` 和任务相关源码。
- 明确本轮目标、非目标、边界、依赖、风险和验收标准。
- 设计实现步骤、涉及模块、数据流/状态流变化、测试要求和文档更新要求。
- 确定版本号：人工指定则按人工指定；未指定则从现有 `md/prompt/` 和 `update_log.md` 自动递增。
- 将提示词写入 `md/prompt/v0（简要标题）/v0.1（简要说明）.md` 这类版本目录。

提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现与测试

Agent B 按 Agent A 提示词小步实现。

必须完成：

- 阅读 Agent A 提示词和入口文档。
- 阅读相关源码、脚本和测试。
- 按现有架构实现，不扩大范围。
- 根据 `md/test/test.md` 选择测试层级，运行测试并记录具体命令和结果。
- 更新 `README.md`、`update_log.md`、`md/test/test.md`、`md/flow/*` 或脚本中受影响的部分。
- 输出改动说明、关键文件、测试命令和结果、未跑测试原因、已知风险、后续建议。

### Agent C：验收与核心逻辑更新

Agent C 负责验收 Agent B 结果，并维护核心逻辑文档。

必须完成：

- 阅读 Agent B 输出、实际 diff、测试结果和入口文档。
- 核对实现是否满足 Agent A 提示词和人工目标。
- 检查架构边界、测试覆盖、文档同步和未说明风险。
- 基于当前真实实现更新 `md/flow/flow.md` 与 `md/flow/flowchart.md`。
- 形成正式版本或重要历史事项时，更新 `update_log.md`。
- 输出通过/不通过、问题清单、已更新文档、建议下一步。

## 6. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认从最小可证明测试开始，根据改动范围扩大到 Smoke、Stage Regression 或 Full。
- 每次改动后至少运行文档或代码对应的最低验证命令。
- 代码变更不得只说“已验证”，必须写出实际命令和结果。
- 文档-only 修改可只跑 `git diff --check` 和必要静态结构检查，但必须说明未跑完整业务测试的原因。
- 涉及 macOS UI、状态栏、小窗、详细窗口、共享模型、通知、StoreKit、EventKit 时，优先运行 `bash scripts/verify_project.sh`，必要时再运行 Mac Xcode 构建。

## 7. 文档规则

- `AGENT.md` 只放入口规则、架构边界和工作流，不写流水账。
- `update_log.md` 记录版本更新、关键决策、完成事项和遗留问题。
- `md/flow/flow.md` 只描述当前真实核心逻辑，不写历史废话。
- `md/flow/flowchart.md` 用 Mermaid 图展示当前核心数据流、执行流和 Agent 迭代流，每张图前必须有中文读图说明。
- `md/test/test.md` 记录测试分层、触发条件、命令和当前基线。
- `md/prompt/` 保存每轮 Agent A 给 Agent B 的详细实现提示词，按版本号管理。
- 改变架构、测试命令、核心流程、重要文件或完成状态时，必须同步更新相关文档。

## 8. 交付格式

最终回复必须包含：

- 改了什么。
- 关键文件。
- 测试命令和结果。
- 未跑测试及原因。
- 已知风险或遗留事项。

如果只是 Agent A 输出提示词，也要说明提示词版本、文件路径、覆盖范围和建议交给 Agent B 的下一步。

## 9. 禁止项

- 不读入口文档就改代码。
- 不读相关源码就按猜测改实现。
- 绕过 `TimerEngine` 直接在 View 中制造第二套计时状态。
- 绕过 `FocusStore` 直接写散落持久化。
- 让 iOS/macOS target 互相污染平台 API。
- 删除旧实现、回滚他人改动或扩大任务范围，除非用户明确要求。
- 用空泛模板替代项目真实文档。
- 用“应该能过”“已验证”替代具体命令输出。
- 忽略失败测试、编译错误、快照占位或 Xcode 构建错误。
