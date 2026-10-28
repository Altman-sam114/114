# 测试规范

本文件只维护可复用的验证制度、真实入口和证据边界。当前任务的选择与进度放 [work.md](../../work.md)，历史结果放 [update_log.md](../../update_log.md)，不把旧版本的全量清单当成每轮必测项。

## 1. 默认云端，不默认全量

- 编译、运行、测试、配置解析和 validator 默认只在 GitHub Actions 执行；本机仅静态阅读、diff/路径核对和 Git/`gh` 操作。`git diff --check` 是补丁格式审阅，不是产品测试。
- 不因调试、云端失败或参考项目允许而运行本机测试。只有用户明确要求本机验证时，才按其范围执行。
- 经授权的本机 iOS 编译/运行只使用现有且 UDID 以 `FAC4325D` 开头的唯一模拟器；没有该设备或无法唯一确认就停止，不创建、不选择其他设备。云端不受本机 UDID 限制。
- 每次实现前按本轮实际编辑及调用依赖选测试，不因历史提示词、其他会话文件或“保险起见”自动运行无关 CI。
- 先在 `work.md` 说明选择理由、云端入口、预期证据和未验证范围，再执行必要验证。未执行不能写成通过。

## 2. 选择模型：baseline + direct + optional

| 层级 | 选择规则 | 例子 |
| --- | --- | --- |
| baseline | 每轮必要的静态自查；代码再加最小可用相关构建/回归 | 本轮 diff、文件范围、链接、架构边界、受影响 target 编译 |
| direct | 本次行为直接改变的路径及必要关联回归 | 计时恢复、完成后提醒取消、分类查询、受影响页面可达性 |
| optional | 只有已说明的跨层风险、发布目标或用户要求才增加 | 双平台全回归、全部原生 UI、Release、受控失败注入 |

选择先看本轮编辑记录，再检查调用方、共享模型、工程引用和系统服务边界；不能为了省测试漏掉真实依赖，也不能因仓库里有测试就全跑。

| 本轮改动 | 必要的验证范围 | 不默认运行 |
| --- | --- | --- |
| 纯 Markdown，不影响可执行配置或 fixture | 静态内容、活动链接、路径和 diff 审阅 | 产品 build、core、UI、Release、validator、全套 CI |
| 仅 iOS View/交互 | iOS 构建、该行为及必要布局/辅助功能路径 | 无关 Mac 页面、Release、CI 失败注入 |
| 仅 Mac View/状态栏 | Mac 构建、该页面/小窗/状态栏及必要渲染 | 无关 iOS 场景、购买实测、失败注入 |
| 共享模型/Store/TimerEngine/计划/统计 | 对应 core 行为回归与两端受影响 target 构建；兼容解码和状态边界 | 与行为无关的全截图矩阵或发行链 |
| 通知/Live Activity/日历/Pro | 对应平台构建、服务边界及相关 core/UI；明确真实服务未覆盖项 | 无关平台能力或伪造系统服务成功 |
| 工程/target/scheme/隐私/资源 | 受影响 target、资源/配置合同；仅发布相关任务增加 Release | 无关交互场景和失败注入 |
| CI/validator/结果包安全链 | 改动的脚本语法/fixture、身份与包外证据链；涉及完整产品包合同才运行完整生产链 | 无关产品 UI；未改的注入阶段组合 |

纯文档提交只有在待推送内容全部为无需运行验证的 Markdown 时才能使用 `[skip ci]`；不能对混入代码、工程、workflow 或测试配置的提交使用。默认不手工 dispatch 一个与任务无关的完整 workflow。

## 3. 现有云端入口与实际能力

以下是当前真实接线，不代表已经实现按 changed-files 自动裁剪：

| 入口 | 当前行为 | 使用边界 |
| --- | --- | --- |
| [ci-results.yml](../../.github/workflows/ci-results.yml) | `main` push 或手动 dispatch；固定执行静态检查、项目验证、Mac/iOS Debug 构建与完整结果包 | 当前是完整产品 profile，没有按模块选择输入 |
| [ci-artifact-review.yml](../../.github/workflows/ci-artifact-review.yml) | 生产 run completed 后，只读来源门禁、下载与正式第四模式复判 | 验证生产结果包，不替代产品行为测试 |
| [ui-evidence.yml](../../.github/workflows/ui-evidence.yml) | 成功生产 push 后，固定运行 Mac、ios-390、ios-375、release 四项矩阵 | 当前没有按平台/场景选择输入；不能声称只跑了相关一项 |

上述 workflow 和结果包合同决定实际执行范围。现有完整入口仍会自动带出全量后续链；它不是“小范围测试”的别名，也不能凭文档声称已优化运行量。

需要代码验证但现有入口过宽时，先在 `work.md` 记录缺口：优先在任务范围内补充真正的定向云端入口及其合同，或由用户决定是否接受扩大范围。没有定向入口前，不擅造 `profile`/`only` 输入，不退回本机测试，不用 `[skip ci]` 跳过代码验证，不把未验证任务标成完成。完整产品验证只用于其覆盖确与本轮依赖相关或用户明确要求的场景。

如修改 workflow 实现范围选择，必须同时验证选择逻辑、必要关联项和真实执行项，不能只改文档、删除 required 产物或把 skipped 写成 success。不得为一个产品小修顺手改整套 CI。

## 4. 云端命令定位

以下命令是 runner 入口说明，不授权在本机执行。实际环境、参数、日志和结果以对应 workflow/脚本为准：

| 相关范围 | 真实入口 | 证据 |
| --- | --- | --- |
| 完整结构、合同、共享 core 和正式 Mac 快照 | `bash scripts/verify_project.sh` | `verify_project.log`、core 输出、快照 manifest；这是组合入口，不是轻量语法检查 |
| 独立 review 逻辑 | `python3 scripts/test_review_ci_artifact.py` | fixture 日志；不替代真实 API/ZIP 来源验证 |
| UI 来源/布局接线 | `python3 scripts/test_ui_evidence.py` | 实际 workflow 的 gate/命名/接线 fixture |
| iOS 原生证据校验 | `python3 scripts/test_ios_ui_evidence.py` | summary、测试树、设备/场景与失败诊断的正负例 |
| 隐私和 Release 产品校验 | `python3 scripts/test_release_readiness.py` | 配置与图标/隐私等产品校验 fixture |
| Mac 渲染 | `bash scripts/build_mac_snapshot_renderer.sh` 与 `scripts/render_mac_snapshots.swift` | 同源渲染器及 PNG/manifest；具体调用见 workflow |
| iOS 原生交互 | `bash scripts/prepare_ios_ui_simulator.sh`、`bash scripts/run_ios_ui_tests.sh` | build/test xcresult、原始 summary/tests/attachments 和完整命令 |
| 发布工程检查 | `bash scripts/run_release_readiness.sh` | Release 命令、真实 bundle/资源检查和独立证据包 |

生产构建是 `xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug -destination 'generic/platform=macOS' ... build` 及 `-scheme ChronoFocus -destination 'generic/platform=iOS' ... build`；保持 `CODE_SIGNING_ALLOWED=NO`，日志和 `.xcresult` 随包保存。

`scripts/resolve_ios_simulator_destination.rb` 只是云端 destination 辅助工具，不授权在本机自动选择其他模拟器。原生 UI 脚本当前只支持分阶段构建、测试和收集，不支持按单条用例筛选；不得臆造参数。

## 5. 行为与视觉验证边界

- 共享 core 覆盖模型兼容、Store 持久化、任务/分类/查询、计划统计、计时与恢复、循环完成身份、提醒取消、自动开始幂等、日历读取策略及倒计时边界。只声称真实执行日志证明的行为。
- 计时修改必须覆盖受影响的开始/暂停/恢复/停止/完成路径及运行/暂停快照保护；View 不得形成第二套状态机，完成入口不得取消其他任务的提醒。
- UI 修改关注受影响页面的实际可达性、44pt 操作区、长文本、亮暗对比、辅助字号与必要窄屏；不能只用“元素存在”、截图非空或源码 marker 证明没有遮挡。
- Mac 生产包保持五张正式图：`mini-timer.png`、`detail-timer.png`、`detail-schedule.png`、`detail-analytics.png`、`detail-settings.png`；manifest 中尺寸、字节数和生成时间有效。内容区有前景，无黄色缺失控件占位，popover 保留局部空白负例。独立辅助 UI 图与正式包分开。
- 完整 iOS 原生证据要求当前脚本登记的精确测试集合全部 Passed、无失败或跳过；按原始测试树关联 summary、唯一 UDID、有限非负耗时、具名场景及 PNG 尺寸/摘要。具体身份与场景以 `verify_ios_ui_evidence.py` 和实际 UITests 为准，不沿用历史数量。
- 构建和云端 boot 可并行，但双成功且 UDID 一致后才运行测试；失败/超时仍收集真实结果，不能自动重跑掩盖首次失败，诊断表不替代接受条件。
- 产品逻辑增加行为回归，不为每次 UI 文案调整机械增加 validator marker；源码合同是辅助结构证据，不等价于运行质量。

## 6. 云端结果核对

需要运行验证的任务，由当前会话跟进，不设置独立人工角色交接：

1. 使用 `gh auth status` 确认项目授权账号 `Altman-sam114`；仅在未授权时由用户处理登录。跟进本轮 commit 对应的 run、attempt、job 及日志。
2. 接受结果前确认 `origin/main`、实际 checkout、源 SHA/run/attempt、artifact 名称与 manifest/index/run context 一致。main 或源 attempt 变化即 stale；旧 SHA 的绿色结果只能作为历史。
3. 核对实际执行范围、失败摘要、JUnit/原生摘要、主日志、`.xcresult` 和相关专属产物；必要 job 被跳过、上传失败或缺证据不能通过。
4. 完整生产包必须取得独立只读 review 的正式第四模式结论；定向入口若以后新增，须有明确的独立证据合同，不能假称已通过完整产品 validator。
5. 读取受影响页面的实际截图或相关运行证据；构建成功不能代替视觉、权限、购买或真机验证。
6. 失败时先区分源码/合同/环境问题并保存证据，再在 `main` 追加相关修复提交；不回滚、忽略错误或自动切换宽松 profile。

记录真实命令、结论和未执行项。有远端验证时附 SHA、workflow/run/attempt、必要 artifact 及独立 review 结论；纯文档不虚构 run 或 artifact，也不为了补写验证编号重跑产品链。

### 完整生产包安全合同

这些约束保持现有实现，仅在使用完整生产链或修改该安全链时适用，不要求普通文档任务执行：

- 独立 review 仅响应 `ChronoFocus CI Results` 的 completed 事件；checkout 前通过原始 workflow/run/event/main API 核对固定 workflow ID `306720987`、静态名称、精确 path、active 状态及源身份。只 checkout 已核对 SHA，`persist-credentials: false`。
- `GITHUB_TOKEN` 仅 `contents: read`、`actions: read`，其他权限为 none；不使用 PAT、额外 secret、OIDC、写操作或不可信缓存，不执行解包代码。源 actor 与 triggering actor 均为 `Altman-sam114`，repository/head repository 均为 `Altman-sam114/114`。
- 产品成功仅接受授权 `push + completed + success`，源 title 登记 `failure_mode=none`。受控失败只在任务明确要求时由授权用户 dispatch 允许的 `failure_mode`，以包外 display title、精确 attempt jobs API、原始注入日志和包内 stage outcome 联合证明；job 必须 completed/failure，唯一目标步骤 completed，其 conclusion 可因 continue-on-error 为 success 或 failure。失败 push、成功 dispatch、取消或超时不能降级成受控成功。
- 下载前及最终结论前复查 main SHA、源 attempt 和 workflow 身份，漂移即 stale；不把 review 自身 SHA/run/attempt 当作源身份。
- 每次证据使用全新唯一目录，原始 `run-api.json`、`artifacts-api.json`、ZIP、下载残留和 validator 日志与 `extracted/` 分离。JSON 为非空普通非 symlink 文件且最多 1 MiB；响应先写独占 `.part`，成功后同盘无覆盖原子晋升，不用过滤重建的 JSON 代替原文。
- 从精确 run artifacts API 选唯一未过期 artifact，下载到独占 `.zip.part` 并有限重试。实际字节数、API SHA-256、ZIP CRC/安全结构通过后才同盘无覆盖原子改名，再解包到全新目录。拒绝路径穿越、重复/前缀冲突、symlink、特殊文件、加密或超限 ZIP；保留所有失败证据，不覆盖、清空或删除旧证据。
- 正式第四模式同时提供目录、完整 archive 三参数、artifact metadata 与 run metadata。validator 在 Actions 中结构化复判 run 的十四项来源/身份、artifact metadata、ZIP 完整性和逐路径目录绑定；artifacts API 不提供 attempt，不能单独证明重试身份。
- 四种 success 兼容模式仍保留，但目录-only、archive-only 或缺少 run metadata 的模式不能替代正式核对。failure mode 必须完整第四模式并显式 `--expected-event workflow_dispatch`；只表示失败证据链有效，不代表产品通过。
- 完整包的 manifest/index/stage/run context/JUnit/outcome/required 产物和日志合同保持不变；finalizer 失败由恢复脚本重建一致 fallback 包，恢复失败不上传陈旧目录。真实 job failure 必须保留。
- review evidence 独立命名并绑定 source/review 两套身份，不加入生产 `ci-results/` 或 index；证据上传失败不能接受。原始日志/ZIP 的转义字节只落盘、不清洗、不输出终端；JSON 保留默认终端保护。

正式第四模式仅供 Actions 调用，参数由包外来源门禁提供：

```bash
ruby scripts/validate_ci_artifact.rb "$EXTRACTED_DIR" \
  --commit "$SOURCE_SHA" --run-id "$SOURCE_RUN_ID" --attempt "$SOURCE_ATTEMPT" \
  --archive "$REVIEW_DIR/$ARTIFACT_NAME.zip" \
  --archive-size "$API_SIZE" --archive-digest "$API_DIGEST" \
  --artifact-metadata "$REVIEW_DIR/artifacts-api.json" \
  --run-metadata "$REVIEW_DIR/run-api.json" \
  --branch main --expected-event push
```

三个 archive 参数必须全有或全无；artifact metadata 依赖完整 archive 参数，run metadata 还依赖 artifact metadata。正式流程由 `scripts/review_ci_artifact.py` 编排，不在本机重跑 validator。

## 7. 系统服务与发布边界

- StoreKit 的商品加载、购买、取消、待处理、恢复和撤销需要真实配置/沙盒环境；不能改 Store 或 defaults 伪造 Pro。
- EventKit 的完整访问、拒绝、仅写入升级与撤销后重试，以及通知授权、锁屏/灵动岛和真机后台仍需独立环境。共享策略 fixture 不替代系统行为。
- Release 工程检查读取真实 App/appex、隐私资源、版本/架构和编译图标，不能用源 PNG 或 build 成功替代资源证据。
- 未签名工程验证不代表可发行，`distributionReady=false` 等人工资料/实测缺口按 [发布准备](../release/readiness.md) 说明；普通开发任务不默认运行发布链。
- 只下载本轮必要结果包，不下载历史 artifact、大体积数据、模型、DerivedData 或无关缓存；无证据时如实报告未验证。
