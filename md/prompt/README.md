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
- 本地默认只跑 `md/test/test.md` 要求的轻量检查；除非人工明确要求，不默认跑完整本机 Xcode build。
- 完成后按版本号提交本轮相关文件，并 `git push origin main` 触发 `.github/workflows/ci-results.yml`。
- Agent B 输出必须包含本地检查命令、结果、commit SHA、push 状态、workflow run 信息和 artifact 名称。
- Agent C 必须用 `gh auth login` 后查询最新 `origin/main` 对应 run 的原始 artifacts API JSON，先写入全新目录中的 `.part`，成功且非空后无覆盖原子改名，再结构化核对唯一 artifact 的 id、name、`size_in_bytes`、`digest`、`expired=false` 和 workflow run 身份；API 不直接提供或证明 run attempt。
- Agent C 每次使用全新 `/private/tmp/chronofocus-c-review-<run_id>-<unique>/` 目录。原始 JSON 必须非空、不超过 1 MiB、为普通文件且不是 symlink；原始 ZIP 使用同一 JSON 中的唯一 id 下载到 `.zip.part` 并进行有限重试，size、SHA-256 和 ZIP 结构全部通过后，才在同一文件系统无覆盖原子改名并解包到全新目录。已有目录或目标文件存在时默认停止并更换唯一目录，禁止删除或覆盖。
- Agent C 必须将解包目录、原始 ZIP、原始 API JSON 和 API size/digest 一并交给 validator，并核对八项 metadata PASS、三个 archive PASS、`ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、主日志、`.xcresult` 和项目专属快照；目录-only 与 archive-only validator 调用仅用于兼容场景，不能替代最新原始证据验收。
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

- v0.98：`md/prompt/v0（持续优化）/v0.98（日程分类空态互斥与CI失败摘要直出）.md`。
- UI 范围：iOS/macOS 日程分类筛选结果非空时显示摘要，结果为空时只显示现有双操作分类空态，保持新增预填、清除筛选与辅助功能接线。
- CI 范围：`Final CI status` 通过 `tee` 将同一 failure summary 同时输出到步骤 stdout 与 Step Summary；新增 `CI failure summary output contracts verified.`、对应 validator PASS、`cat` 回退 fixture 和 marker 缺失 fixture，不改变 artifact 结构。
- 状态：未运行任何本地测试或检查；实现 commit `9f26f865ab84c7874763bb3eef59a6a5c513a7c4` 的 GitHub Actions run `30189412591`（attempt `1`）已成功，job `89759759272` 全步骤成功且 annotations 为 `0`。Agent C 已复判 artifact `chronofocus-ci-v0.10-main-9f26f86-run30189412591-attempt1`（id `8628068160`，size `14382692`，digest `sha256:36b099026d830adb266034b9d70a776ee5dce696270d8288ceb1bb768d5de28f`，`expired=false`），validator 为 `99 PASS / 0 FAIL`；三个 archive、日程互斥、CI failure summary marker、manifest overall 和 Mac/iOS build 均 PASS，v0.98 云端验收完成。
- v0.99：`md/prompt/v0（持续优化）/v0.99（iOS计时队列展开与Artifact API元数据复判）.md`。
- UI 范围：iOS 计时待办默认显示前 4 项并支持展开/收起，在分类或筛选数量变化时重置；运行中仍可只读浏览，任务行继续禁用，并保留 44pt、动态字体、VoiceOver 与 Voice Control 语义。
- CI 范围：validator 接收原始 artifacts API JSON，按 1 MiB/普通文件/非 symlink 和参数矩阵约束，输出八项 metadata PASS；新增 `Timer task queue expansion contracts verified.`、`CI artifact API metadata contracts verified.`、对应 PASS 及字段/marker 负向 fixtures，API 不直接证明 attempt。
- 状态：未运行任何本地测试或检查；首次实现 commit `b54d11bf0dabf1d1c2a73308001867335f541c67` 的云端结果包内容虽为 `109 PASS / 0 FAIL`，但 Agent C 静态审查发现缺少独立 `total_count=0` fixture，因此退回。修复 commit `c65693fe49e0c6ade7ff9751c5dda00103a9c37b` 的 GitHub Actions run `30191096124`（attempt `1`）已成功，artifact `chronofocus-ci-v0.10-main-c65693f-run30191096124-attempt1`（id `8628621407`，size `14384904`，digest `sha256:b5a3386abc747ec2577dd85c3cd40e2f049bc664dc6324597ddc85971103a94b`，`expired=false`）经原始 API JSON/ZIP 与 validator 复判为 `109 PASS / 0 FAIL`，v0.99 实现验收通过；本证据记录提交仍须完成自身最新云端复判。
