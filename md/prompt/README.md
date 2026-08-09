# Prompt 目录

本目录保存每轮 Agent A 写给 Agent B 的详细实现提示词。Agent A 负责把人工目标转成可执行方案，默认不直接改代码。

## 角色召唤

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 用户消息以 `agentx`、`x:` 或 `X:` 开头，表示召唤 Agent X。
- 没有这些前缀时，按普通 Codex 任务处理；如果任务需要明确 A/B/C/X 边界，先说明本轮采用的身份或提醒人工指定角色。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`
- Agent X 最终回复第一行必须写：`我是 Agent X。`

## 命名建议

- `md/prompt/v0（项目初始化）/v0.1（建立迭代文档）.md`
- `md/prompt/v0（项目初始化）/v0.2（优化测试规范）.md`
- `md/prompt/v1（核心功能）/v1.0（实现主流程）.md`
- `md/prompt/v1（核心功能）/v1.1（修复主流程问题）.md`

## 版本管理规则

- Agent A 每次写提示词都必须写入版本号。
- 人工指定版本时，以人工指定为准。
- 人工未指定版本时，Agent A 自动判断版本，从 `v0.1` 开始。
- 同一阶段的小任务、修复、优化递增小版本，例如 `v0.1` -> `v0.2` -> `v0.3`。
- 大任务、架构阶段、核心功能阶段或重要里程碑新开大版本，例如 `v0.x` -> `v1.0`。
- 同一大版本下的提示词放在同一个目录，例如 `md/prompt/v0（项目初始化）/`、`md/prompt/v1（核心功能）/`。
- 文件名使用 `v0.1（简要说明）.md`，说明要短，能表达本轮目标。

## Agent X 提示词管理规则

- Agent X 可以围绕人工总目标拆分多个小轮次，但每个实现轮次仍必须要求 Agent A 生成版本化提示词。
- Agent X 不得用自己的调度说明替代 Agent A 提示词；如果需要进入实现，必须先产出或引用对应 `md/prompt/` 文件。
- 每轮提示词必须包含本轮目标、非目标、当前架构依据、实现步骤、关键文件、验证命令、CI workflow、artifact 下载、Agent C 验收要求、风险和禁止项。
- Agent X 判断继续下一轮时，应引用上一轮 Agent C 结论，并为下一轮 Agent A 明确新增目标或修复目标。
- 如果 Agent C 验收失败，Agent X 只能要求 Agent B 基于同一提示词或追加修复提示词继续，不得跳过 artifact 复判直接进入新功能轮。

## 每份提示词必须包含

- 版本号。
- 版本分配依据：人工指定或 Agent A 自动判断。
- 背景。
- 目标。
- 非目标。
- 当前架构依据。
- 实现步骤。
- 关键文件。
- 测试要求。
- 文档更新要求。
- 验收标准。
- 风险和禁止项。
- `main` 同步、提交和 push 要求。
- GitHub Actions workflow、run id、artifact 下载和 Agent C 复判要求。

## 云端阶段要求

Agent A 写给 Agent B 的提示词必须明确：

- 本轮固定使用 `main` 作为唯一上传、提交、推送和云端验证分支。
- 开始前执行 `git fetch origin`、`git switch main`、`git pull --ff-only origin main`，并确认无无关 diff。
- 当前硬性约束下不运行本地项目测试、validator、Xcode、`xcodebuild`、`simctl` 或 Simulator；只做静态审阅，最终测试和验收全部由 push 后的 GitHub Actions 提供。
- 完成后按版本号提交本轮相关文件，并 `git push origin main` 触发 `.github/workflows/ci-results.yml`。
- Agent B 输出必须说明未运行本地测试，包含静态审阅范围、commit SHA、push 状态、workflow run 信息和 artifact 名称。
- Agent C 必须用 `gh auth login` 后查询最新 `origin/main` 对应精确 workflow run API 和 artifacts API。两份原始响应分别先写 `run-api.json.part`、`artifacts-api.json.part`，成功且非空后无覆盖原子改名；run JSON 结构化核对 attempt、workflow、状态、结论和仓库，artifacts JSON 结构化核对唯一 artifact 的 id、name、size、digest、expired 和 workflow run 身份。
- Agent C 每次使用全新 `/private/tmp/chronofocus-c-review-<run_id>-<unique>/` 目录。原始 JSON 必须非空、不超过 1 MiB、为普通文件且不是 symlink；原始 ZIP 使用同一 JSON 中的唯一 id 下载到 `.zip.part` 并进行有限重试，size、SHA-256 和 ZIP 结构全部通过后，才在同一文件系统无覆盖原子改名并解包到全新目录。已有目录或目标文件存在时默认停止并更换唯一目录，禁止删除或覆盖。
- Agent C 必须将解包目录、原始 ZIP、两份原始 API JSON 和 API size/digest 一并交给 validator 第四模式；v1.2 起核对十四项 run metadata（含 push/actor/triggering actor/head repository 来源）、八项 artifact metadata、三项 archive、manifest、failure summary、JUnit、主日志、`.xcresult` 和项目专属快照。前三种较弱模式仅用于兼容，不能替代最新原始证据验收。
- Agent C 发现失败或结果包不一致时，退回 Agent B 在 `main` 追加修复 commit，不做回滚式处理。
- 本轮不引入 `smalldata_test`、`develop`、`codeb/...`、PR 合并流，也不照搬 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png` 等项目特例。

## Agent A 最低工作要求

1. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`。
2. 阅读任务相关源码、脚本、测试和最近 git 记录。
3. 明确本轮范围，不把未要求的重构塞进提示词。
4. 写出能让 Agent B 直接执行的步骤和验收标准。
5. 对每个测试要求给出触发原因和命令。
6. 写清 `main` push 后的云端结果包验收标准。

## 当前实现轮次

- v1.4：`md/prompt/v1（持续优化）/v1.4（可启动待办一致性与Archive目录绑定）.md`。
- UI 范围：日程保留停用任务展示，计时队列、计划启动、日程接力和 TimerEngine 使用统一的 startable 查询；空闲选择失效时回到自由专注，运行中/暂停中保留快照。
- CI 范围：完整 archive 模式把原始 ZIP 与 validator 自建临时解包树逐路径绑定，比较类型、大小和 SHA-256，并拒绝不安全 ZIP 条目；目标基线 `131 PASS / 0 FAIL`。
- 状态：首次实现 commit `3779f26` 的 run `31291481389` 因提示词 EOF 空行和旧 iOS handoff contract 失败，Mac/iOS build 与 artifact 上传成功；已追加最小修复，等待新的 `origin/main` GitHub Actions 及 Agent C 最新 artifact 复判。未运行任何本地项目测试或检查。

- v1.4.1：`md/prompt/v1（持续优化）/v1.4.1（CI fixture archive binding稳定性）.md`。
- 范围：只修复 CI fixture 的 fixed-point index、冻结 run-metadata 目录/ZIP/metadata 同源绑定，以及 archive-backed marker 负向 fixture 的单失败隔离；不改 UI、Swift、validator 安全语义或 artifact 结构。
- 状态：基于 commit `5067079` 的云端 run `31294009115` 项目验证失败结果包，当前修复待提交推送；未运行任何本地测试、validator、构建或模拟器，预期恢复 `131 PASS / 0 FAIL` 后由 Agent C 复判。

- v1.4.2：`md/prompt/v1（持续优化）/v1.4.2（Mac core CI 编译接线）.md`。
- 范围：只在 Mac core `swiftc` 源列表补入 `TimerEngine.swift` 和 `TimerPlatformServices.swift`，与 snapshot 编译顺序一致；不改 UI、产品 Swift、测试断言、validator 或 workflow。
- 状态：针对 run `31295311282` 的 Mac core `TimerEngine` 缺失编译失败完成静态接线；未运行任何本地测试、validator、构建或模拟器，等待新 `origin/main` run 和 Agent C artifact 复判。

- v1.4.3：`md/prompt/v1（持续优化）/v1.4.3（Mac core 计划失效断言）.md`。
- 范围：仅调整停用任务触发自动计划重生成后的 Mac core 断言，接受计划项合法消失或开始时间保持不变；不改产品逻辑、UI、CI workflow、validator 或 artifact 结构。
- 状态：commit `9efdec763716e722fd1985feb5551a1dc5da2850` 的 run `31296565259`（attempt `1`）已成功。Agent C 使用 `gh` 核对 artifact `chronofocus-ci-v0.10-main-9efdec7-run31296565259-attempt1`（id `9033169188`，size `14359355`，digest `sha256:f6b2eaab0e8428cf7e7e5142ec606b4464359c76a0f79d222201f1f182ee6481`，`expired=false`），原始 ZIP、manifest、index、run context、JUnit、日志、`.xcresult` 和 Mac 快照均匹配；未运行本地测试或 validator。

- v1.4.4：`md/prompt/v1（持续优化）/v1.4.4（Mac计时队列展开与筛选重置）.md`。
- 范围：macOS 计时队列从完整筛选结果派生默认前 7 项，超过阈值支持展开/收起；分类、完整筛选数量变化和 handoff 重置展开状态，运行中仍可浏览但任务行不可切换，并补齐两态 44pt、VoiceOver 和 Voice Control 语义。快照 fixture 只证明云端运行期 overflow，正式五张 manifest 清单不变；复用既有 Mac queue marker，不新增 validator contract。
- 状态：实现 commit `a6726b3e2407d051f734171f386434ef7ada16c5` 的 run `31298401138`（attempt `1`）已成功；文档收尾 commit `9a1253a9e33122ef7c93ec24769d5ce8a95c3dcc` 的 run `31299100036`（attempt `1`）也已成功。Agent C 使用 `gh` 复判最新 artifact `chronofocus-ci-v0.10-main-9a1253a-run31299100036-attempt1`（id `9033963477`，size `14358537`，digest `sha256:30692dcbfc4b1fe0bd80baa0ffe30a001c57c69e2539e97d08abc6a78f75471a`，`expired=false`）为 `131 PASS / 0 FAIL`，JUnit `4/0/0`；正式五张快照、archive、artifact metadata、run metadata 和所有 contracts 均通过。该证据不得复用为后续版本结论，后续仍禁止本地项目测试、Xcode、`xcodebuild`、`simctl`、Simulator 和浏览器。

- v1.4.5：`md/prompt/v1（持续优化）/v1.4.5（日程日期格分类计数一致性）.md`。
- 范围：iOS/macOS 日程日期格、范围计数、列表和空态共享当前分类筛选；日期格只在有分类筛选时统计该分类，未筛选时保留全量 `dueDate` 自然日计数，日期格可访问标签与视觉计数使用同一上下文；快照 fixture 将任务固定到同一自然日，不改变正式五张 manifest 清单或 validator 安全语义。
- 状态：实现与文档待在 `main` 提交并 push；当前尚无 v1.4.5 对应 run/artifact，等待最新 `origin/main` 云端 artifact 第四模式复判。禁止本地项目测试、validator、Xcode、`xcodebuild`、`simctl`、Simulator、浏览器及本地解析检查。

- v0.98：`md/prompt/v0（持续优化）/v0.98（日程分类空态互斥与CI失败摘要直出）.md`。
- UI 范围：iOS/macOS 日程分类筛选结果非空时显示摘要，结果为空时只显示现有双操作分类空态，保持新增预填、清除筛选与辅助功能接线。
- CI 范围：`Final CI status` 通过 `tee` 将同一 failure summary 同时输出到步骤 stdout 与 Step Summary；新增 `CI failure summary output contracts verified.`、对应 validator PASS、`cat` 回退 fixture 和 marker 缺失 fixture，不改变 artifact 结构。
- 状态：未运行任何本地测试或检查；实现 commit `9f26f865ab84c7874763bb3eef59a6a5c513a7c4` 的 GitHub Actions run `30189412591`（attempt `1`）已成功，job `89759759272` 全步骤成功且 annotations 为 `0`。Agent C 已复判 artifact `chronofocus-ci-v0.10-main-9f26f86-run30189412591-attempt1`（id `8628068160`，size `14382692`，digest `sha256:36b099026d830adb266034b9d70a776ee5dce696270d8288ceb1bb768d5de28f`，`expired=false`），validator 为 `99 PASS / 0 FAIL`；三个 archive、日程互斥、CI failure summary marker、manifest overall 和 Mac/iOS build 均 PASS，v0.98 云端验收完成。
- v0.99：`md/prompt/v0（持续优化）/v0.99（iOS计时队列展开与Artifact API元数据复判）.md`。
- UI 范围：iOS 计时待办默认显示前 4 项并支持展开/收起，在分类或筛选数量变化时重置；运行中仍可只读浏览，任务行继续禁用，并保留 44pt、动态字体、VoiceOver 与 Voice Control 语义。
- CI 范围：validator 接收原始 artifacts API JSON，按 1 MiB/普通文件/非 symlink 和参数矩阵约束，输出八项 metadata PASS；新增 `Timer task queue expansion contracts verified.`、`CI artifact API metadata contracts verified.`、对应 PASS 及字段/marker 负向 fixtures，API 不直接证明 attempt。
- 状态：未运行任何本地测试或检查；首次实现 commit `b54d11bf0dabf1d1c2a73308001867335f541c67` 的云端结果包内容虽为 `109 PASS / 0 FAIL`，但 Agent C 静态审查发现缺少独立 `total_count=0` fixture，因此退回。修复 commit `c65693fe49e0c6ade7ff9751c5dda00103a9c37b` 的 GitHub Actions run `30191096124`（attempt `1`）已成功，artifact `chronofocus-ci-v0.10-main-c65693f-run30191096124-attempt1`（id `8628621407`，size `14384904`，digest `sha256:b5a3386abc747ec2577dd85c3cd40e2f049bc664dc6324597ddc85971103a94b`，`expired=false`）经原始 API JSON/ZIP 与 validator 复判为 `109 PASS / 0 FAIL`，v0.99 实现验收通过；本证据记录提交仍须完成自身最新云端复判。
- v1.0：`md/prompt/v1（持续优化）/v1.0（已有分类复用与Run API复判）.md`。
- UI 范围：iOS 新增/编辑和 macOS 快速新增从 `store.taskCategories` 派生非预设已有分类，按固定 locale 规范化、首次出现去重和稳定顺序展示；点击只更新草稿并复用首个同分类任务代表色，session-only 分类保留当前颜色，不新增持久化。
- CI 范围：validator 新增 archive + artifact metadata + run metadata 第四模式，并对精确 run API 输出 response shape、id、attempt、SHA、branch、name、path、status、conclusion、repository 十项独立结果；Agent C 使用 `run-api.json.part -> run-api.json`、artifacts JSON 和原始 ZIP 完成包外证据链。
- 状态：未运行任何本地测试或检查；实现 commit `7ccf408b82ce2ead457e5bce679f5cee1ac9ae33` 的 run `30192906663` 已通过。最终证据 commit `a76d1dbb2926297cbb05578b6b9cf781e08a1285` 的 GitHub Actions run `30193171049`（attempt `1`）成功，Agent C 复判 artifact `chronofocus-ci-v0.10-main-a76d1db-run30193171049-attempt1`（id `8629271447`，size `14396212`，digest `sha256:e1baa096398e0016f708b6c86dcb8caf52d57a897c08c459dd2bee7e4f55760d`，`expired=false`）为 `121 PASS / 0 FAIL`；annotations 为 0，v1.0 已闭环。
- v1.1：`md/prompt/v1（持续优化）/v1.1（已有分类使用量上下文）.md`。
- UI 范围：iOS/macOS 已有分类按同一规范化 key 派生全部当前任务数量，有任务显示数量，session-only 显示“历史”；不持久化、不按数量排序，并保留 v1.0 的代表色、草稿和辅助功能边界。
- CI 范围：新增 `Existing category usage context contracts verified.`、validator PASS 和 marker 缺失负向 fixture，继续由最新 run 的 Run API、Artifacts API 和 ZIP 第四模式复判。
- 状态：主线程未运行本地测试或检查，但 CI 子 Agent 误运行过一次 `git diff --check`，其结果不作为验收证据。实现 commit `0666b4efae1822e978adf21f08df145e43a99aa8` 的 run `30193636728` 因旧 VoiceOver 契约失败；修复 commit `46546e703668025a43ed467cafc46571916ad7eb` 的 run `30193805133` 通过。最终证据 commit `db27324eb1a3ddf1fcf7672fdd66c1a326194946` 的 run `30194008859`（attempt `1`）成功，Agent C 复判 artifact `chronofocus-ci-v0.10-main-db27324-run30194008859-attempt1`（id `8629538360`，size `14392402`，digest `sha256:0b40f8edb49e7aff56761b1fef21d79449098af3666211df661b79311f18a16a`，`expired=false`）为 `122 PASS / 0 FAIL`，annotations 为 0，v1.1 闭环。
- v1.2：`md/prompt/v1（持续优化）/v1.2（已有分类搜索与Run来源复判）.md`。
- UI 范围：iOS/macOS 在至少 6 个非预设已有分类时提供规范化名称子串搜索、结果数/总数、清除和无结果反馈；搜索只过滤 View option，不修改分类草稿或持久化。
- CI 范围：Run API 完整模式增加 `event`、`actor.login`、`triggering_actor.login`、`head_repository.full_name` 四项授权来源复判，并增加独立项目 marker/PASS 和负向 fixtures。
- 状态：已闭环。未运行任何本地测试或检查。首次 run `30194825035` 虽为 `128 PASS / 0 FAIL`，但因云端快照缺少筛选结果 chip 被退回；返修 commit `0802d252056e99c704db8fe4bdaf8d26bb39a846` 的 run `30195201551` 通过实现验收。最终证据 commit `001875c842a2a2368346c043af59498c75a68788` 的 run `30195874234`（attempt `1`）成功，Agent C 复判 artifact `chronofocus-ci-v0.10-main-001875c-run30195874234-attempt1`（id `8630116575`，size `14377358`，digest `sha256:1ac0c627198c6d64cb77911a767c487a61d6c0604a383a6220f189e6aad4f007`，`expired=false`）为 `128 PASS / 0 FAIL`，annotations 为 0；`detail-schedule.png` 清晰显示“产品”结果 chip，无重叠、占位或截断。
- v1.3：`md/prompt/v1（持续优化）/v1.3（日程分类接力到计时）.md`。
- UI 范围：iOS/macOS 从日程分类摘要或任务行发出带唯一 id 的瞬态接力请求，切到计时并恢复分类/合法任务选择；运行中不替换任务，且绝不自动开始。
- CI 范围：新增 `Schedule to timer handoff contracts verified.`、对应 validator PASS 和 marker 缺失负向 fixture；两张 Mac 快照覆盖接力入口与计时终态，预期基线 `129 PASS / 0 FAIL`。
- 状态：实现验收通过，最终证据 commit 待云端复判。前两次 run `30322093934`、`30322395891` 分别暴露并修复两个旧源码切片边界；实现 commit `a5d5a85ac7095fe5718f45ba3c310c7252acb56d` 的 run `30322671653`（attempt `1`）成功，Agent C 在全新目录复判 artifact `8674620314` 为 `129 PASS / 0 FAIL`，JUnit `4/0/0`、annotations `0`，两端 build 与关键快照均通过。未运行本地项目测试或验证；主线程误执行的两次 `/dev/null` 空 `git diff --check --no-index` 均未读取项目文件且不作为证据。
