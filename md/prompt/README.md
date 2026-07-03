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
- Agent C 必须用 `gh auth login` 后下载最新 `origin/main` 对应 artifact 到 `/private/tmp/chronofocus-c-review-<run_id>/`。
- Agent C 必须核对 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、主日志、`.xcresult` 和项目专属快照。
- Agent C 发现失败或结果包不一致时，退回 Agent B 在 `main` 追加修复 commit，不做回滚式处理。
- 本轮不引入 `smalldata_test`、`develop`、`codeb/...`、PR 合并流，也不照搬 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png` 等项目特例。

## Agent A 最低工作要求

1. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`。
2. 阅读任务相关源码、脚本、测试和最近 git 记录。
3. 明确本轮范围，不把未要求的重构塞进提示词。
4. 写出能让 Agent B 直接执行的步骤和验收标准。
5. 对每个测试要求给出触发原因和命令。
6. 写清 `main` push 后的云端结果包验收标准。
