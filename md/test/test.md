# 测试规范

本文指导 Agent B 和 Agent C 为 ChronoFocus 选择测试层级。每次实现前先读本文件，默认从本地轻量检查开始，并通过 `origin/main` 上的 GitHub Actions 做重验证。

## 默认验证策略

- 默认路径：本地轻量检查 -> commit 到 `main` -> `git push origin main` -> GitHub Actions 上传未加密 CI 结果包 -> Agent C 下载并复判。
- 只有人工明确要求“本机测试”“本地 build”“本地 xcodebuild”“本地跑探针”等，才把完整本机 Xcode build 作为默认路径。
- 文档-only 修改可本地跑 `git diff --check` 和必要的 YAML/plist 解析；业务代码、工程文件、脚本或平台能力改动完成后，默认依赖云端重验证给出最终结论。
- 云端失败时，Agent B 根据结果包里的 failure summary、JUnit、日志和 manifest 修复，并在 `main` 上追加修复 commit 后重新 push。
- 云端环境缺依赖时，最终回复必须说明没跑哪个测试、缺什么依赖、是否影响验收、需要人工提供什么。

## Agent X 循环验证规则

Agent X 只负责主控调度，不改变每轮验证责任。每一个由 Agent X 拆出的轮次仍按 Agent A -> Agent B -> Agent C 闭环执行：

- Agent A 提示词必须写清本轮本地验证、GitHub Actions、artifact 和 Agent C 复判要求。
- Agent B 必须按本文件选择本地轻量检查；实现轮次默认至少有本地轻量检查结果、commit 和 `origin/main` push。
- GitHub Actions 必须为最新 `origin/main` commit 生成未加密 artifact。
- Agent C 必须下载并核对最新 run 对应 artifact，检查 manifest、run context、artifact 名称、JUnit 或测试摘要、failure summary、主日志、`.xcresult` 和项目专属产物。
- Agent X 不得跳过 Agent C artifact 验收，不得用本地输出、旧 run 或旧 artifact 代替最新云端结论。
- 如果 Agent C 验收失败，Agent X 只能选择退回 Agent B 修复、暂停等待人工确认或停止；不得继续下一轮并伪装成功。
- Agent X 宣布总目标完成前，最后一轮必须已有 Agent C 对最新 `origin/main` artifact 的通过结论。

## 固定前缀 / 环境要求

当前项目是 Xcode SwiftUI 工程，默认机器可能将 `xcode-select` 指向 Command Line Tools。运行 Xcode 构建时优先使用：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Mac 版构建命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

云端 iOS generic 构建命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$RUNNER_TEMP/ChronoFocusIOSDerivedData" \
  -resultBundlePath "$PWD/ci-results/ChronoFocus-iOS.xcresult" \
  CODE_SIGNING_ALLOWED=NO build
```

本机 iOS simulator destination 解析：

```bash
ruby scripts/resolve_ios_simulator_destination.rb
```

本机 iOS simulator build 命令可由脚本打印：

```bash
ruby scripts/resolve_ios_simulator_destination.rb --print-build-command
```

该脚本会在 `DEVELOPER_DIR` 未设置且 `/Applications/Xcode.app/Contents/Developer` 存在时自动使用完整 Xcode，减少 Command Line Tools 环境下的 `simctl` 解析失败；如果已设置 `DEVELOPER_DIR`，打印的 build 命令会沿用该路径。

主结构验证命令：

```bash
bash scripts/verify_project.sh
```

文档和补丁格式检查：

```bash
git diff --check
```

GitHub Actions workflow 语法轻量检查：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

Agent C 下载结果包前必须完成 GitHub CLI 登录：

```bash
gh auth login
```

Agent C 结果包缓存默认目录：

```bash
/private/tmp/chronofocus-c-review-<run_id>/
```

下载结果包后可用结构化脚本辅助复判：

```bash
ruby scripts/validate_ci_artifact.rb /private/tmp/chronofocus-c-review-<run_id> \
  --commit <origin-main-sha> \
  --run-id <run_id> \
  --attempt <run_attempt>
```

该脚本会核对 manifest branch/commit/run/attempt、manifest artifactName、overallOutcome、short SHA、固定 CI process version、workflow/project/scheme/destination 元数据、createdAt、project reports allowlist 和关键路径字段、`ci-run-context.txt` 精确字段集合、无重复/无额外字段、身份字段与 artifact 名称、artifact index 身份字段、artifactName、version、createdAt、必需路径与 kind、entry 路径集合精确清单、下载后本地文件/目录非空状态、required entry 的本地 byteCount/fileCount/recursiveByteCount 复算、index totals 与 entries 聚合一致性、artifact 根目录/报告目录/快照目录不存在未声明额外文件、JUnit suite/classname 元数据、四个 testcase、JUnit failures/errors 计数、JUnit outcome 与 manifest outcome、testcase 不含 failure/error 元素、failure summary 身份字段/总结果/阶段 outcome/日志入口、`static-checks.log` 静态检查 marker、`xcode-version.log` 版本内容、`verify_project.log` 分类摘要动作 contract marker、分类 chip 可访问 contract marker、日程任务操作 contract marker、计时主控 contract marker、计划开始 contract marker、计划分类 badge marker、Mac 计划分类上下文 marker、计划面板操作 marker、日程 toolbar 新增 marker、Mac 快速新增 marker、分类输入上下文 marker、待办保存按钮 marker、待办取消按钮 marker、Mac 小窗快捷面板 marker、统计分类占比 marker、统计分类投入次数 marker、统计分类投入排行 marker、统计最近记录分类 marker 和统计计划回顾分类 marker、Mac/iOS build 成功标记、Mac 快照 manifest generatedAt 和快照 manifest 中 PNG byteCount 与下载文件大小一致性。`verify_project.sh` 用小型成功 fixture、旧 process version 负向 fixture、run context 额外字段负向 fixture、分类摘要 marker 缺失负向 fixture、日程任务操作 marker 缺失负向 fixture、计时主控 marker 缺失负向 fixture、计划开始 marker 缺失负向 fixture、计划分类 badge marker 缺失负向 fixture、Mac 计划分类 marker 缺失负向 fixture、计划面板操作 marker 缺失负向 fixture、日程 toolbar 新增 marker 缺失负向 fixture、Mac 快速新增 marker 缺失负向 fixture、分类输入上下文 marker 缺失负向 fixture、待办保存按钮 marker 缺失负向 fixture、待办取消按钮 marker 缺失负向 fixture、Mac 小窗快捷面板 marker 缺失负向 fixture、统计分类占比 marker 缺失负向 fixture、统计分类投入次数 marker 缺失负向 fixture、统计分类投入排行 marker 缺失负向 fixture、统计最近记录分类 marker 缺失负向 fixture、统计计划回顾分类 marker 缺失负向 fixture、错误 JUnit 元数据负向 fixture、错误 JUnit errors 计数负向 fixture、错误 JUnit outcome 负向 fixture、JUnit failure/error 元素负向 fixture、错误 artifactName 负向 fixture、错误 manifest artifactName 负向 fixture、错误 manifest overallOutcome 负向 fixture、错误 index artifactName 负向 fixture、错误 manifest 元数据负向 fixture、artifact index 身份错包负向 fixture、artifact index totals 篡改负向 fixture、artifact index 未预期 entry 负向 fixture、额外 artifact 文件负向 fixture、本地文件大小篡改负向 fixture、本地缺失产物负向 fixture、快照 manifest generatedAt 无效负向 fixture 和快照 manifest 大小篡改负向 fixture 覆盖 validator 的放行/拒绝路径。脚本只能辅助复判，不能替代 Agent C 对最新 `origin/main` run 和 artifact 来源的一致性核对。

## StoreKit / EventKit 本地人工验证

StoreKit 和 EventKit 依赖真实系统服务、App Store Connect / StoreKit 配置、sandbox 账号、系统日历数据和权限弹窗，默认 GitHub Actions 不访问真实 App Store 或系统日历数据。CI 只检查代码标记、plist / project 配置、项目专属脚本、Mac build 和 iOS generic build，不能替代人工环境验证。

当前真实实现边界：

- iOS Pro：`ChronoFocus/Services/PremiumAccessService.swift`，商品 ID 为 `com.example.ChronoFocus.pro.analytics`。
- macOS Pro：`ChronoFocusMac/Services/MacPremiumAccessService.swift`，商品 ID 同上。
- iOS 日历同步：`ChronoFocus/Services/CalendarSyncService.swift`，首次授权在 iOS 17+ 使用 EventKit 请求完整日历访问，当前实现也接受已有 `writeOnly` / `authorized` 状态。
- macOS 日历同步：`ChronoFocusMac/Services/MacCalendarSyncService.swift`，首次授权在 macOS 14+ 使用 EventKit 请求完整日历访问，当前实现也接受已有 `writeOnly` / `authorized` 状态。
- 外部日历事件必须通过 `FocusStore.upsertExternalTask(...)` 合并，不能绕过 `FocusStore` 直接写持久化。

涉及 StoreKit / EventKit 代码、权限描述、商品 ID、同步规则或 Pro gating 的改动，本地至少运行：

```bash
git diff --check
bash scripts/verify_project.sh
```

人工验证 StoreKit 时，使用 Xcode scheme 绑定包含 `com.example.ChronoFocus.pro.analytics` 的 StoreKit 配置，或使用 App Store Connect sandbox 中已配置的同名商品。检查商品加载、购买、恢复、取消、无商品配置和 entitlement 刷新后的状态文案；不要通过直接改 `UserDefaults`、`FocusStore` 或新增调试开关伪造 Pro 权益。

人工验证 EventKit 时，先通过 StoreKit 本地配置或 sandbox 解锁 Pro，再在系统日历中创建从今天零点起 45 天范围内的非全天事件，执行同步，确认待办列表出现同标题任务、分类为来源日历名称、开始时间进入待办时间，并且重复同步不会复制同一外部事件。还要检查拒绝日历权限、无近期非全天事件和权限重新授权后的状态文案。

如后续需要自动化覆盖 StoreKit / EventKit，优先在平台服务边界注入测试替身，不要复制 `TimerEngine`、`FocusStore`、日历导入或 Pro 权益规则。

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、artifact index、JUnit 或测试摘要、关键日志、失败摘要、必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/chronofocus-c-review-<run_id>/`。
- 下载后应检查目录大小：

```bash
du -sh /private/tmp/chronofocus-c-review-<run_id>/
```

- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。
- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。

## 测试分层

### 1. Probe / Fast

最快发现文档、补丁、workflow、核心脚本或局部 Swift 逻辑断点。

触发条件：

- 文档-only 修改。
- GitHub Actions workflow 修改。
- 小范围脚本修改。
- 修改共享模型、`FocusStore` 或计划/统计逻辑，需要先跑核心 Swift 脚本。

命令：

```bash
git diff --check
```

修改 `.github/workflows/ci-results.yml` 时再运行：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

共享模型或核心数据逻辑改动时再运行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun --sdk macosx swiftc \
  -module-cache-path /tmp/chrono_focus_mac_core_module_cache \
  ChronoFocus/Models/AppModels.swift \
  ChronoFocus/Services/FocusStore.swift \
  Shared/SharedExtensions.swift \
  scripts/test_mac_core.swift \
  -o /tmp/chrono_focus_mac_core_tests
/tmp/chrono_focus_mac_core_tests
```

当前基线：

- `scripts/test_mac_core.swift` 应输出 `Mac core tests passed.`，并覆盖分类清洗、默认分类顺序、筛选排序和 fallback 元数据。
- `git diff --check` 不应输出错误。
- workflow YAML 解析应输出 `yaml ok`。

### 2. Smoke

验证主要集成路径，适合大多数 Swift、脚本和 Mac UI 改动。默认由云端 `ci-results.yml` 执行；本机只在人工要求或定位问题时运行。

触发条件：

- 修改 `ChronoFocus.xcodeproj`、plist、entitlements、assets。
- 修改 `TimerEngine`、`TimerPlatformServices`、通知、StoreKit、EventKit。
- 修改 Mac 小窗、详细窗口、快照安全控件。
- 修改验证脚本或快照脚本。

命令：

```bash
bash scripts/verify_project.sh
```

当前基线：

- 检查项目和 plist 语法。
- 检查必需文件、工程引用、三个 shared schemes 语法。
- 检查 Live Activity、本地通知、铃声/音色、Pro、日历同步、自动计划、Mac 状态栏等实现标记。
- v0.78 起，统计最近记录必须显示分类 badge，整行可访问标签需包含任务、分类、模式、开始时间、时长和完成状态；`verify_project.log` 必须包含 `Analytics recent session category contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project analytics recent session category contracts`，并由 marker 缺失负向 fixture 覆盖拒绝路径。
- v0.79 起，当前任务选择行分类语义必须独立输出 `Current task selection accessibility contracts verified.`；Agent C artifact validator 必须输出 `PASS verify_project current task selection accessibility contracts`，并由 `negative_current_task_selection_marker_fixture` 覆盖拒绝路径。
- v0.80 起，分类筛选 chip 再次点击已选分类清除筛选必须独立输出 `Category filter toggle contracts verified.`；Agent C artifact validator 必须输出 `PASS verify_project category filter toggle contracts`，并由 `negative_category_filter_toggle_marker_fixture` 覆盖拒绝路径。
- v0.81 起，iOS 统计页日程计划回顾计划项必须显示分类 badge，整行可访问标签需包含任务、分类、计划开始时间和轮次；`verify_project.log` 必须包含 `Analytics plan review category accessibility contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project analytics plan review category accessibility contracts`，并由 `negative_analytics_plan_review_marker_fixture` 覆盖拒绝路径。
- v0.82 起，iOS 待办新增/编辑保存按钮必须读出待办、分类、预计轮次或只设开始模式；`verify_project.log` 必须包含 `Task editor save category accessibility contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project task editor save category accessibility contracts`，并由 `negative_task_editor_save_marker_fixture` 覆盖拒绝路径。
- v0.83 起，iOS 待办新增/编辑取消按钮必须读出取消新增/取消编辑动作、待办和分类；`verify_project.log` 必须包含 `Task editor cancel category accessibility contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project task editor cancel category accessibility contracts`，并由 `negative_task_editor_cancel_marker_fixture` 覆盖拒绝路径。
- v0.84 起，iOS/macOS 统计页分类投入必须显示并读出每个分类的专注次数；`verify_project.log` 必须包含 `Analytics category share session count contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project analytics category share session count contracts`，并由 `negative_analytics_category_share_session_count_marker_fixture` 覆盖拒绝路径。
- v0.85 起，iOS/macOS 统计页分类投入必须显示并读出每个分类的排行位置；`verify_project.log` 必须包含 `Analytics category share ranking contracts verified.`，Agent C artifact validator 必须输出 `PASS verify_project analytics category share ranking contracts`，并由 `negative_analytics_category_share_ranking_marker_fixture` 覆盖拒绝路径。
- 检查分类预设、日程页和计时页分类筛选、统计分类投入占比/次数/排行、统计计划回顾分类语义、分类 chip 点击切换、分类输入上下文、待办保存/取消按钮分类语义、分类预设按钮可访问语义、可访问提示、selected trait 和 Voice Control input labels、新建预填、筛选摘要、筛选摘要动作可访问提示、iOS/Mac 日程日期格可访问语义、iOS/Mac 日程摘要按钮分类语义、Mac 日程摘要按钮点击区、iOS 日程筛选计数、iOS 日程 toolbar 新增入口分类语义、iOS 日程任务行分类 badge 与 Voice Control 输入标签、iOS/Mac 日程任务行操作按钮任务名和分类语义、iOS/Mac 计时主控按钮任务名和分类语义、iOS/Mac 计划项开始按钮任务名/时间段/轮次语义、iOS/Mac 计划项分类 badge、iOS/Mac 计划面板生成/清空操作当前轮数语义、Mac 快速新增提交按钮分类/轮次语义、Mac 小窗快捷面板按钮语义、Mac 计划项分类上下文、计时页分类筛选摘要、计时页分类摘要清除入口、计时页分类空态清除入口、计时页分类 badge 可访问标签、iOS/Mac 当前任务选择 selected trait、提示、运行中不可切换提示与 Voice Control 输入标签、Mac 任务行和小窗分类 badge 预设色兜底与 Voice Control 输入标签、分类摘要插入点和新增/清除动作接线、iOS 摘要快捷新增分类待办、Mac 待办筛选计数、Mac 分类摘要快捷新增、Mac 快速新增分类预填提示和连续新增分类保留、筛选优先级、44pt iOS 分类点击区域、iOS 设置页音色选择/试听、根视图非 Pro 音色清洗、Mac 小窗任务分类上下文、Mac 小窗直达详情入口、Mac 各详情页快照安全静态控件、CI iOS/错误摘录/artifact index 精确清单/run context/manifest 元数据和 manifest/index artifactName/manifest overallOutcome 结果包实现标记、结果包校验脚本语法、validator 小型成功、固定 CI process version 复判、manifest artifactName 复判、manifest overallOutcome 复判、index artifactName 复判、旧 process version 负向 fixture、分类摘要 marker 缺失负向 fixture、日程任务操作 marker 缺失负向 fixture、计时主控 marker 缺失负向 fixture、计划开始 marker 缺失负向 fixture、计划分类 badge marker 缺失负向 fixture、Mac 计划分类 marker 缺失负向 fixture、计划面板操作 marker 缺失负向 fixture、日程 toolbar 新增 marker 缺失负向 fixture、Mac 快速新增 marker 缺失负向 fixture、分类输入上下文 marker 缺失负向 fixture、待办保存 marker 缺失负向 fixture、待办取消 marker 缺失负向 fixture、Mac 小窗快捷面板 marker 缺失负向 fixture、统计分类占比 marker 缺失负向 fixture、统计分类投入次数 marker 缺失负向 fixture、统计分类投入排行 marker 缺失负向 fixture、统计最近记录分类 marker 缺失负向 fixture、统计计划回顾分类 marker 缺失负向 fixture、JUnit 元数据负向 fixture、JUnit errors 负向 fixture、JUnit outcome 负向 fixture、JUnit failure/error 元素负向 fixture、artifactName mismatch 负向、manifest artifactName 负向、manifest overallOutcome 负向、index artifactName 负向、manifest 元数据负向、artifact index 身份错包负向、artifact index totals 篡改负向、artifact index 未预期 entry 负向 fixture、额外 artifact 文件负向 fixture、本地缺失产物负向 fixture、快照 manifest generatedAt 无效负向 fixture、快照 manifest 大小篡改负向 fixture、static-checks 日志 marker、分类可访问 contract 日志复判、日程任务操作 contract 日志复判、计时主控 contract 日志复判、计划开始 contract 日志复判、计划分类 badge contract 日志复判、Mac 计划分类 contract 日志复判、计划面板操作 contract 日志复判、日程 toolbar 新增 contract 日志复判、Mac 快速新增 contract 日志复判、分类输入上下文 contract 日志复判、待办保存/取消按钮 contract 日志复判、Mac 小窗快捷面板 contract 日志复判、统计分类占比/投入次数/排行 contract 日志复判、统计最近记录分类 contract 日志复判和统计计划回顾分类 contract 日志复判、iOS simulator destination 解析 fixture。
- 编译并运行 Mac core tests。
- 渲染 Mac 快照到 `/tmp/chronofocus-mac-snapshots/`，并生成 `manifest.json` 记录 5 张快照的文件名、尺寸和字节数。
- 最终输出 `Project structure verified.`。

### 3. Stage Regression

覆盖当前阶段核心模块，适合 macOS 目标、跨平台共享逻辑或平台服务改动。默认由云端 `ci-results.yml` 执行 Mac build 并上传 `.xcresult`；本机只在人工要求或定位问题时运行。

触发条件：

- 修改 `ChronoFocusMac/App/*`、`ChronoFocusMac/Services/*`、`ChronoFocusMac/Views/*`。
- 修改共享模型导致 iOS/macOS 都受影响。
- 修改状态栏、popover、详细窗口、通知、Pro、日历同步。
- Smoke 通过但仍需要确认 target 可构建。

命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

当前基线：

- 目标结果是 `BUILD SUCCEEDED`。
- 当前环境可能出现 CoreSimulator、FSEvents、缓存权限相关警告；只要没有 Swift 编译、链接、签名或脚本错误，且最终 `BUILD SUCCEEDED`，Mac target 视为通过。

## 云端重验证

默认 workflow：

```bash
.github/workflows/ci-results.yml
```

触发条件：

- push 到 `main`。
- 手动 `workflow_dispatch`。

云端固定执行：

- `git diff --check` 对当前提交 diff 做空白检查。
- `plutil -lint ChronoFocus.xcodeproj/project.pbxproj`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`。
- `bash scripts/verify_project.sh`，生成 Mac core tests 与 Mac UI snapshots。
- `xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug -destination 'generic/platform=macOS' ... build`，生成 `xcodebuild.log` 和 `.xcresult`。
- `xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug -destination 'generic/platform=iOS' ... build`，生成 `ios-xcodebuild.log` 和 `ChronoFocus-iOS.xcresult`。

结果包最低内容：

- `ci-artifact-manifest.json`：记录版本、branch、commitSha、run id、run attempt、workflow、Mac/iOS scheme、Mac/iOS destination、日志路径、结果路径、artifact index 路径、`overallOutcome` 和各阶段 outcome。
- `ci-artifact-index.json`：记录 artifact 名称、关键 artifact 文件/目录是否存在、类型、文件字节数、目录递归字节数和文件数量。
- `ci-run-context.txt`：记录 artifact 名称、branch、commitSha、run id 和 run attempt；validator 还会核对字段集合精确、无重复、无额外字段，供 Agent C 交叉核对。
- `ci-failure-summary.md`：记录通过/失败摘要和日志入口；存在失败阶段时追加有限 `Failure Excerpts` 错误摘录。
- `junit.xml`：Agent C 可读的阶段摘要。
- `xcodebuild.log`：Mac build 主日志。
- `ios-xcodebuild.log`：iOS `ChronoFocus` scheme generic build 主日志。
- `verify_project.log`：项目专属验证日志。
- `ChronoFocusMac.xcresult`：Mac build 原生结果包。
- `ChronoFocus-iOS.xcresult`：iOS build 原生结果包。
- `project-reports/mac-snapshots/`：Mac 快照脚本产物副本。
- `project-reports/mac-snapshots/manifest.json`：Mac 快照清单，记录 5 张快照的文件名、像素尺寸、字节数和生成时间。

Agent C 验收时必须核对：

- artifact 来自 `origin/main` 最新 commit。
- manifest 中 `branch` 为 `main`。
- manifest 中 `commitSha` 与 `origin/main` 最新 SHA 完全一致。
- manifest 中 `runId` 和 `runAttempt` 与下载的 GitHub Actions run 一致。
- `ci-run-context.txt` 中字段集合必须精确，`branch`、`commitSha`、`runId`、`runAttempt` 和 artifact 名称必须与本轮 run 一致。
- `scripts/validate_ci_artifact.rb` 对下载目录输出全 PASS，且包含 `PASS ci process version`、`PASS manifest artifact name`、`PASS manifest overall outcome`、`PASS index artifact name`、`PASS run context exact keys`、`PASS run context artifact name`、`PASS index unexpected entries`、`PASS snapshot manifest generated at`、`PASS junit metadata`、`PASS junit errors`、`PASS junit testcase outcomes`、`PASS junit failure elements`、`PASS failure summary identity`、`PASS failure summary outcomes`、`PASS static checks log markers`、`PASS xcode version log`、`PASS unexpected local artifacts`、`PASS verify_project category summary action contracts`、`PASS verify_project category accessibility contracts`、`PASS verify_project schedule task action accessibility contracts`、`PASS verify_project timer action accessibility contracts`、`PASS verify_project plan start action accessibility contracts`、`PASS verify_project plan category badge contracts`、`PASS verify_project mac plan category context contracts`、`PASS verify_project plan panel action accessibility contracts`、`PASS verify_project schedule toolbar add category context contracts`、`PASS verify_project mac quick add action accessibility contracts`、`PASS verify_project category input context contracts`、`PASS verify_project task editor save category accessibility contracts`、`PASS verify_project task editor cancel category accessibility contracts`、`PASS verify_project mac mini quick panel accessibility contracts`、`PASS verify_project analytics category share accessibility contracts`、`PASS verify_project analytics category share session count contracts`、`PASS verify_project analytics category share ranking contracts`、`PASS verify_project analytics recent session category contracts`、`PASS verify_project analytics plan review category accessibility contracts`、`PASS verify_project category filter toggle contracts` 和 `PASS verify_project current task selection accessibility contracts`，作为结构化辅助证据；若脚本失败，必须人工核对失败项并退回 Agent B 或说明原因。
- `staticChecksOutcome`、`projectVerificationOutcome`、`buildOutcome`、`macBuildOutcome`、`iosBuildOutcome` 均为 `success`。
- artifact index、failure summary、JUnit、主日志和项目专属产物存在且不是旧 checkout 里的遗留文件。
- `ci-artifact-index.json` 必须覆盖 manifest、summary、JUnit、主日志、Mac/iOS `.xcresult`、Mac 快照目录、快照 manifest 和 5 张快照；required 条目必须存在，文件字节数或目录递归字节数必须为正，且下载目录中 required entry 的实际 byteCount/fileCount/recursiveByteCount 必须与 index 记录一致；artifact 根目录、`project-reports` 和 Mac 快照目录不得包含未声明额外文件。
- `junit.xml` 必须包含 `testsuite name="ChronoFocus CI Results"`、`tests="4"`、`failures="0"`、`errors="0"`，包含 `staticChecks`、`projectVerification`、`macBuild`、`iosBuild` 四个 `classname="ChronoFocusCI"` testcase，且每个 `system-out` 的 `outcome=` 必须与 manifest 对应阶段 outcome 一致，testcase 内不得包含 `failure` 或 `error` 元素。
- `ci-failure-summary.md` 和 GitHub Step Summary 必须列出 iOS build 状态、`ios-xcodebuild.log` 和 `ChronoFocus-iOS.xcresult`；若任一阶段失败，必须包含 `Failure Excerpts` 并按阶段摘录关键错误行。
- Mac 快照 manifest 必须包含 `mini-timer.png`、`detail-timer.png`、`detail-schedule.png`、`detail-analytics.png`、`detail-settings.png` 五个条目，且每项 `width`、`height`、`byteCount` 均大于 0。
- workflow 的 Final CI status 必须把 iOS build outcome 纳入失败判定。

### 4. Full

全量验证 iOS 主 App、Live Activity 扩展和 Mac App。

触发条件：

- 修改 iOS App 入口、iOS Views、Live Activity、ActivityKit 数据结构、iOS 通知或权限。
- 修改工程结构、target、scheme、签名、entitlements。
- 发布前、重要里程碑或 Agent C 验收要求。

命令：

```bash
bash scripts/verify_project.sh
```

Mac 构建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Debug \
  -derivedDataPath /tmp/ChronoFocusMacDerivedData build
```

iOS simulator 构建需按当前机器可用模拟器选择目的地。优先使用脚本解析：

```bash
ruby scripts/resolve_ios_simulator_destination.rb --print-build-command
```

也可手工查看：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -showdestinations
```

然后使用可用 destination 构建 `ChronoFocus` scheme。若当前环境没有可用模拟器或 Xcode 服务异常，最终回复必须说明未跑 iOS 构建的原因。

当前基线：

- Mac 侧已有明确脚本和构建基线。
- 云端固定使用 `generic/platform=iOS` 构建 `ChronoFocus` scheme，并上传 `ios-xcodebuild.log` 与 `ChronoFocus-iOS.xcresult`。
- 本机 iOS simulator destination 可用 `scripts/resolve_ios_simulator_destination.rb` 解析；若当前环境没有可用模拟器或 Xcode 服务异常，最终回复必须说明未跑 iOS 构建的原因。

## 静态检查

固定可用：

```bash
git diff --check
```

工程结构和实现标记：

```bash
bash scripts/verify_project.sh
```

plist / JSON / scheme 检查已包含在 `scripts/verify_project.sh` 中：

- `plutil -lint`
- `python3 -m json.tool`
- XML parse 检查 shared schemes。

## 快照测试要求

`scripts/render_mac_snapshots.swift` 当前生成：

- `/tmp/chronofocus-mac-snapshots/mini-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-timer.png`
- `/tmp/chronofocus-mac-snapshots/detail-schedule.png`
- `/tmp/chronofocus-mac-snapshots/detail-analytics.png`
- `/tmp/chronofocus-mac-snapshots/detail-settings.png`

快照测试必须继续覆盖：

- 图片非空。
- 详情页右侧内容区有前景内容。
- 不出现黄色缺失控件占位。

新增 Mac 页面、重要状态或快照安全控件时，必须同步扩展 `scripts/render_mac_snapshots.swift` 和 `scripts/verify_project.sh`。

## 规则

- 每次实现前先读本文件。
- 默认从最小本地轻量检查开始，根据改动范围交给云端重验证扩大覆盖。
- 不得伪造测试结果，不得把“已验证”当作命令结果。
- 文档-only 修改可只跑 `git diff --check`，但必须说明未跑完整业务测试的原因。
- 修改共享模型、计时状态机、计划生成、统计、通知、Pro 或日历同步时，不得只跑文档检查。
- 测试脚本失败时，先判断是项目问题还是环境问题；Swift 编译、链接、签名、脚本断言失败不得忽略。
- 不得把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
