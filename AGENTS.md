# AGENTS.md

ChronoFocus 的长期开发入口。当前会话直接理解目标、规划、实现、自查和交付，不再设置角色召唤、角色交接或强制版本提示词；除非用户明确要求，不启动子智能体或额外聊天。

## 1. 项目事实与架构边界

- ChronoFocus 是 SwiftUI 番茄钟原型，包含 iOS 主 App、Live Activity 扩展和 macOS 状态栏 App。
- 共享模型、计时状态机、计划生成、统计和持久化；平台能力通过 iOS/macOS 服务隔离，不复制一套业务逻辑。
- `TimerEngine` 是唯一计时状态机。开始、暂停、恢复、跳过、完成、自动流转和恢复都从这里进入，View 不维护第二套计时状态。
- `FocusStore` 是唯一核心仓库。任务、设置、会话、计划和活跃计时快照通过它保存为 `UserDefaults` JSON，不新增散落持久化。
- 通知通过 `TimerNotificationServicing`，Live Activity/占位通过 `TimerLiveActivityServicing` 接入；平台服务不持有核心业务规则。
- 新增共享模型字段使用 `decodeIfPresent` 加默认值等向后兼容解码，保留既有数据。
- 使用 SwiftUI、Swift 并发和平台原生 API，未经用户要求不引入第三方依赖。
- macOS target 不依赖 UIKit 或真实 ActivityKit UI；iOS target 不依赖 AppKit。

关键文件：

- 共享层：`ChronoFocus/Models/AppModels.swift`、`ChronoFocus/Services/FocusStore.swift`、`ChronoFocus/Services/TimerEngine.swift`、`ChronoFocus/Services/TimerPlatformServices.swift`、`Shared/SharedExtensions.swift`、`Shared/CalendarReadAccess.swift`、`Shared/PomodoroActivityAttributes.swift`。
- iOS 层：`ChronoFocus/ChronoFocusApp.swift`、`ChronoFocus/Views/`、通知/Live Activity/日历/Pro 服务及 `ChronoFocusLiveActivity/`。
- macOS 层：`ChronoFocusMac/App/`、`ChronoFocusMac/Services/`、`ChronoFocusMac/Views/`。

## 2. 文档分工与阅读顺序

| 文档 | 唯一职责 | 何时阅读或更新 |
| --- | --- | --- |
| [AGENTS.md](AGENTS.md) | 长期规则、架构边界、开发流程 | 开始任务先读；仅稳定规则变化时更新 |
| [work.md](work.md) | 当前任务计划、进度、证据和下一步 | 开始或恢复任务必读，推进时更新，完成后清空任务正文 |
| [md/flow/flow.md](md/flow/flow.md) | 当前真实架构、数据流和执行流 | 按任务读取；架构或职责变化才更新 |
| [md/flow/flowchart.md](md/flow/flowchart.md) | 当前核心流程图 | 流程变化时更新，每张图前保留中文读图说明 |
| [md/test/test.md](md/test/test.md) | 测试选择、云端入口和证据要求 | 实现前选择本轮相关验证；测试制度或入口变化才更新 |
| [README.md](README.md) | 用户功能和上手方式 | 用户可见行为或使用方式变化才更新 |
| [update_log.md](update_log.md) | 版本、重要任务、验证结果和遗留事项 | 需要历史依据时按主题阅读；有意义的任务收口时追加 |
| [md/prompt/README.md](md/prompt/README.md) | 历史提示词归档说明 | 仅追溯历史需求，不是当前指令或开发前置条件 |

开始时读取本文件、`work.md`、`git status --short --branch` 和最近提交，再按范围定位 flow、test、源码、脚本和必要 workflow。不要求每次通读整个更新日志或历史提示词。

源码与工程配置优先于当前流程/测试文档；当前用户目标与本文件优先于历史提示词。不要盲从旧方案，先核对实际实现。

## 3. 目标驱动开发流程

1. 确认目标、非目标、验收标准、风险和本轮文件范围；能合理判断就自主推进，只有需求冲突、权限或不可逆决策才询问用户。
2. 在 `work.md` 写下可执行的小步骤和最小验证选择。先读相关实现再改，复杂任务拆成有独立验收点的小步，不要求另写版本提示词。
3. 沿现有架构小步实现，维护本轮编辑记录；不顺手重构无关模块，不覆盖、回滚或混入用户已有改动。
4. 每完成一个步骤、改变方案、遇到失败或准备上下文压缩时，立即更新 `work.md` 的进度、证据、未解决项和下一步。
5. 按 [测试规范](md/test/test.md) 自查并选择本轮相关云端验证。失败先读真实日志，修复后追加提交；不因流程仪式扩大测试或开发范围。
6. 同步真正受影响的文档，检查 diff、提交范围、未验证项和远端影响；只有目标及其必要验证完成才交付为完成。
7. 将值得保留的结论写入 `update_log.md` 或最终交付，清空 `work.md` 当前任务正文，保留文件和“当前无进行中的任务”状态。

出现用户要求停止、无法判断归属的冲突、缺少账号/密钥/付费决策，或同一阻塞连续三次仍无新证据时，停止重复尝试，保留 `work.md` 并说明需要什么。不得无限重跑、回滚掩盖失败或未完成先清空任务。

## 4. work.md 接续约定

`work.md` 是当前工作台，不是日志，也不替代实际源码、Git 状态或云端证据。每次任务至少记录：

- 目标、非目标、验收标准、当前状态及必要上下文。
- 分步计划和完成标记，当前正在做的步骤。
- 本轮编辑文件、已有改动边界、分支和基线；有远端操作时记录 commit/push 状态。
- 验证选择：`baseline + direct + optional`、关联理由、未执行项；已执行时记录真实命令、结论及必要的 SHA/run/attempt/artifact。
- 失败原因、风险、阻塞和下一步可直接执行的动作。

恢复任务时先读本文件和 `work.md`，再核对 Git 与云端现状，不能只相信已勾选状态。任务未完成、必要 CI 未结束或用户暂时中断时保留记录；新目标到来时先区分替换、追加或暂停，不静默覆盖未完成任务。

完成后移走需要长期保存的结论，删除任务计划、临时上下文、勾选项和过期证据链接，只保留简短空闲状态；保留 `work.md` 文件。不要为了给文档写入自身提交号而制造无限的文档提交与 CI 循环。

## 5. 云端优先与相关测试

- 默认禁止本机编译、运行和测试：包括项目测试、Swift/Swift 编译器、Xcode、`xcodebuild`、`simctl`、Simulator、validator、测试脚本及 YAML/JSON/Plist 等配置校验。定位问题和 CI 失败不构成本机测试授权。
- 本机仅做静态阅读、`rg` 定位、Git diff/格式审阅、路径核对及 Git/`gh` 远端操作；`git diff --check` 只作补丁空白检查，不算产品验证。不启动浏览器代替云端验证。
- 只有用户明确要求“本机测试”“本地 build”等，才在本轮授权范围内执行；不能沿用参考项目或历史提示词里的本机构建规则。
- 经明确授权进行本机 iOS 编译或运行时，只能使用现有且 UDID 以 `FAC4325D` 开头的唯一模拟器。若不存在或不能唯一确认，停止并报告；严禁创建或选择其他设备。云端 runner 不受该本机设备限制。
- 以本轮编辑记录和实际依赖选择 `baseline + direct + optional`；其他会话的文件、历史需求、累计旧测试清单不自动扩大范围。必要关联回归不能省，无关平台、UI、Release、失败注入和全量 CI 不默认运行。
- 纯 Markdown 改动且不影响可执行配置/fixture 时，只静态检查内容、链接和 diff，不编译产品、不运行项目测试、validator 或整套 CI。
- 代码及配置需要的自动化验证默认在 `origin/main` 的 GitHub Actions 执行。当前 workflow 是完整固定链，不存在按任务裁剪的 profile；需要较小云端入口时先核实并补齐入口及对应合同，不伪造开关、不私自放宽验收，也不把“只能跑全量”当成启动无关测试的理由。
- 仅接受对应精确 SHA/run/attempt 的真实结果；未执行、失败、过时或缺少产物都必须说明，不能用旧结果、静态合同或文字承诺冒充本轮验证。

## 6. Git 与交付

- 保留本项目 `main` 直推约定；默认不创建分支、PR 或额外 worktree，不照搬参考项目的 `smalldata_test`/候选分支流程。
- 开始时检查已有改动，再 `git fetch origin`、确认 `main` 并在不会影响已有工作时 `git pull --ff-only origin main`。分支错误、存在无法安全同步的改动或归属不明的冲突时先报告，不强制切换或覆盖。
- 提交前按本轮编辑记录审查 diff，仅暂存本轮相关文件/片段，不使用无差别 `git add .`。已有无关改动保留且不提交；工作中发现新的非本轮变更时停止并与用户确认。
- 有意义的任务在 `update_log.md` 记录任务名、日期、核心变更、关键文件、实际验证和遗留项。产品版本按用户指定或实际发布需要管理，文档/流程维护不强制增加产品版本或新增历史 prompt。
- 提交说明简短聚焦；有产品版本时使用 `vX.Y: 简要说明`，纯维护可用 `docs:`/`chore:` 等。
- 默认提交本轮相关改动并推送 `origin/main`。推送前再次核对分支、远端、授权账号 `Altman-sam114` 和待推送提交范围。
- 只有待推送内容全部为无需运行验证的 Markdown 文档时，才可在提交说明使用 `[skip ci]`，避免现有 push workflow 触发无关产品链。含代码、工程、workflow、测试/fixture 或其他可执行配置时禁止这样跳过必要验证。
- 需要云端验证的提交，跟进相关 run、日志和必要 artifact，自行核对身份与结论。完整结果包的只读独立 review、API/ZIP 安全链保持不变，详见测试规范；不再要求另一个角色验收。
- 删除文件或目录默认使用 `trash <path>`；只有临时文件/构建产物且用户已确认才使用 `rm`。不删除历史提示词或证据，不提交凭证、DerivedData 或无关大文件。

## 7. 文档与最终回复

- 稳定入口不写逐版流水账；flow 只描述当前真实逻辑，test 只描述可复用制度，历史与单次证据放更新日志。
- 仅更新受本轮影响的文档，不要求每次机械改全套 Markdown；修正活动链接，历史 prompt 的旧路径可以保留但不作为当前入口。
- 最终回复使用中文，简要列出改动与关键文件、分支及提交/推送影响、实际验证命令与结果、未执行项及原因、已知风险或下一步；不需要角色身份开场。
- 产品构建成功不等于真实购买、系统权限、真机后台或正式发行通过；这些边界必须明确保留。
