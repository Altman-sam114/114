# AGENTS.md

本文是 ChronoFocus 项目的入口记忆、总览、基本规则和多 Agent 迭代工作流。后续 Codex/Agent 开始任务前必须先读本文件，再按任务范围读取相关文档和源码。

## 1. 项目一句话总览

ChronoFocus 是一个 SwiftUI 番茄钟 App 原型，包含 iOS 主 App、iOS Live Activity 扩展和 macOS 状态栏 App；核心模型、计时状态机、计划生成、统计和持久化逻辑共享，平台能力通过 iOS/macOS 专用服务隔离。

## 2. 必读文件

按顺序阅读：

1. `AGENTS.md`：入口规则、协作流程、禁止项。
2. `update_log.md`：版本记录、历史决策、遗留问题。
3. `md/flow/flow.md`：当前真实架构、核心数据流、执行流。
4. `md/flow/flowchart.md`：核心逻辑和 Agent 迭代流程图。
5. `md/test/test.md`：测试分层、命令、触发条件、当前基线。
6. `README.md`：用户视角功能、打开方式、本地验证。
7. `md/prompt/README.md`：提示词目录、角色召唤和云端阶段要求。
8. `.github/workflows/`：云端验证和结果包规则。
9. 任务相关源码、脚本、最近 git 记录。

## 3. 项目基本规则

- 使用 SwiftUI 和 Swift 并发/平台原生 API；不要引入第三方依赖，除非用户明确要求。
- 共享业务逻辑，平台层分离。不要为 Mac 版或 iOS 版复制一套核心模型、计时状态机、统计逻辑或计划生成逻辑。
- `TimerEngine` 是唯一计时状态机；开始、暂停、恢复、跳过、完成、自动流转必须从这里进入。
- `FocusStore` 是核心数据仓库；任务、设置、会话、计划和活跃计时快照都通过它持久化到 `UserDefaults` JSON。
- 平台服务必须通过抽象边界接入：通知使用 `TimerNotificationServicing`，Live Activity/占位服务使用 `TimerLiveActivityServicing`。
- 新增共享模型字段必须使用向后兼容解码，例如 `decodeIfPresent` 加默认值。
- 不做无关重构，不回滚用户或其他 Agent 的改动，不伪造测试结果。
- 手写文件修改使用 `apply_patch`；大规模格式化或构建产物生成可以使用项目脚本。
- 默认协作分支是 `main`，也是唯一上传、提交、推送和云端验证分支；现存 `smalldata_test` 只记录现状，不纳入默认流程。
- 默认验证策略是本地轻量检查 + `origin/main` 云端重验证；除非人工明确要求，不默认在本机跑完整 Xcode build。

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

项目采用“人工目标 -> Agent A 设计提示词 -> Agent B 基于最新 `origin/main` 实现、轻量检查、commit 并 push 到 `origin/main` -> GitHub Actions 上传未加密 CI 结果包 -> Agent C 下载结果包验收 -> 有问题退回 Agent B 在 `main` 追加修复 commit -> 通过后人工复核 -> 下一轮”的循环。

### 角色召唤和身份标识

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C 边界，提醒用户指定角色或说明本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`

### main 直推和云端验收

- 每轮默认从 `main` 开始，并先执行 `git fetch origin`、`git switch main`、`git pull --ff-only origin main`。
- 推送前必须确认当前分支是 `main`、目标远端是 `origin/main`、工作区没有无关 diff。
- 本轮不使用 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并流；如后续人工要改流程，必须先更新本文件和 `md/flow/*`。
- Agent B 完成后在本地提交，并直接 `git push origin main` 触发 GitHub Actions。
- GitHub Actions 必须上传未加密 CI 结果包，至少包含 manifest、failure summary、JUnit 或等价摘要、主日志和项目专属验证产物。
- Agent C 必须先 `gh auth login`，再下载 `origin/main` 最新 commit 对应 run 的 artifact；默认缓存目录为 `/private/tmp/chronofocus-c-review-<run_id>/`。
- Agent C 只验收 manifest 中 `branch=main` 且 `commitSha`、run id、run attempt 与 `origin/main` 最新 commit 完全一致的结果包。
- 云端失败时不回滚；Agent C 写退回清单，Agent B 在 `main` 追加修复 commit 后继续 push。
- Agent C 若必须补齐验收文档，也必须按 `main` 追加 commit/push/云端验收处理，不能只留本地改动。

### Agent A：目标分析与提示词

Agent A 默认不直接写代码，负责把人工目标转成可执行实现提示词。

必须完成：

- 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md` 和任务相关源码。
- 明确本轮目标、非目标、边界、依赖、风险和验收标准。
- 设计实现步骤、涉及模块、数据流/状态流变化、测试要求和文档更新要求。
- 确定版本号：人工指定则按人工指定；未指定则从现有 `md/prompt/` 和 `update_log.md` 自动递增。
- 将提示词写入 `md/prompt/v0（简要标题）/v0.1（简要说明）.md` 这类版本目录。
- 在提示词中写清本轮 `main` 同步、轻量检查、commit/push、CI workflow、artifact 下载和 Agent C 核对要求。

提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现与测试

Agent B 按 Agent A 提示词小步实现。

必须完成：

- 阅读 Agent A 提示词和入口文档。
- 同步最新 `origin/main`，确认在 `main` 上工作且没有无关 diff。
- 阅读相关源码、脚本和测试。
- 按现有架构实现，不扩大范围。
- 根据 `md/test/test.md` 选择本地轻量检查；除非人工明确要求，不默认跑完整本机 Xcode build。
- 更新 `README.md`、`update_log.md`、`md/test/test.md`、`md/flow/*` 或脚本中受影响的部分。
- 按版本号提交本轮相关文件，push 到 `origin/main` 触发 GitHub Actions。
- 输出改动说明、关键文件、本地检查命令和结果、云端 run/artifact 信息、未跑测试原因、已知风险、后续建议。

### Agent C：验收与核心逻辑更新

Agent C 负责验收 Agent B 结果，并维护核心逻辑文档。

必须完成：

- 阅读 Agent B 输出、实际 diff、测试结果和入口文档。
- 核对实现是否满足 Agent A 提示词和人工目标。
- 检查架构边界、测试覆盖、文档同步和未说明风险。
- 用 `gh auth login` 后下载最新 `origin/main` 对应的 GitHub Actions artifact。
- 核对 manifest、JUnit 或等价摘要、主日志、failure summary 和项目专属产物。
- 核对 manifest 的 `branch`、`commitSha`、run id、run attempt 与 `origin/main` 最新状态一致。
- 基于当前真实实现检查 `md/flow/flow.md` 与 `md/flow/flowchart.md` 是否同步；缺失时退回 Agent B 或追加文档 commit 后重新 push 验证。
- 形成正式版本或重要历史事项时，确认 `update_log.md` 已记录。
- 如果验收不通过：不得提交；必须列出问题、原因、证据和建议修复路径，并退回 Agent B 继续实现。
- 如果验收最终通过：确认 `main` 最新 run 通过且结果包核对无误。
- 输出通过/不通过、问题清单、已更新文档、提交结果、建议下一步。

### main 提交和推送规则

- 提交前必须确认工作区 diff，只提交本轮相关改动，不把无关文件混入版本。
- 提交前必须确认 `update_log.md` 已记录本轮版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 提交信息按版本号管理，格式为：`vX.Y: 简要说明本版本做了什么`。
- 提交说明要短，聚焦工作内容，不写长篇过程。例如：`v0.2: 调整 Agent C 验收提交流程`。
- 如需要提交正文，正文只概括核心变更、验证结果和遗留风险。
- push 前必须确认当前分支是 `main` 且目标是 `origin/main`。
- push 后必须记录 commit hash、run id、run attempt、artifact 名称和云端结论。
- 验收不通过、测试失败、文档未同步、版本号不明确或存在无关 diff 时，不得把该版本宣称为通过。

## 6. 测试规则

- 每次实现前先读 `md/test/test.md`。
- 默认从最小可证明本地轻量检查开始，并通过 `origin/main` GitHub Actions 做重验证。
- 每次改动后至少运行文档或代码对应的最低本地验证命令。
- 代码变更不得只说“已验证”，必须写出实际命令和结果。
- 文档-only 修改可只跑 `git diff --check` 和必要静态结构检查，但必须说明未跑完整业务测试的原因。
- 涉及 macOS UI、状态栏、小窗、详细窗口、共享模型、通知、StoreKit、EventKit 时，本地至少跑轻量检查；默认由云端 `ci-results.yml` 跑 `bash scripts/verify_project.sh` 和 Mac Xcode 构建。
- 只有人工明确要求“本机测试”“本地 build”“本地 xcodebuild”时，才把完整本机构建作为默认路径。

## 7. 文档规则

- `AGENTS.md` 只放入口规则、架构边界和工作流，不写流水账。
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
