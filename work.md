# 当前任务

## 目标与边界

- 2026-10-28：继续重构优化，重点提升 iOS/macOS UI 的完成度、可读性、辅助功能和组件结构；验证只在云端执行。
- 验收：两端计时主路径保持 Engine 单一入口；统一视觉组件；默认小屏主操作可达；长标题/分类、大字体、亮暗主题不丢失上下文；本轮精确 SHA 的生产、独立 review、UI 与未签名 Release 工程证据通过并实际读图。
- 非目标：更换持久化或计时架构、引入依赖、伪造 Pro、擅自配置正式 Team/商品/渠道、不实宣称已可上架。不启动子智能体，不运行本机编译/测试/validator/配置校验。

## 基线与已有改动

- 分支 `main`，基线 `88f2ea7`；`git fetch origin` 和 `git pull --ff-only origin main` 已执行，远端一致；GitHub 账号 `Altman-sam114`，远端 `Altman-sam114/114`。
- 用户已有改动：`md/prompt/v1（持续优化）/v1.10（待办检索与安全管理）.md`；未跟踪 `md/1.md`、`md/通用云端迭代升级提示词.md`。保留，不编辑、不暂存。
- 历史事实：`ad5fdd7` 生产和独立 review 成功；UI run `40639476645` 的 ios-375 原生测试失败，其他三项成功。历史结果不作为本轮通过证据，先读真实日志定位。

## 计划

1. [完成] 静态审阅实际 UI、组件、原生测试、最近云端失败和发行边界，确定可独立验收的范围。
2. [完成] 实现统一视觉/辅助功能组件，重构计时展示与任务行，保持平台和业务边界。
3. [完成] 静态审查 diff、更新必要行为文档，聚焦提交并推送 main。
4. [进行中] 跟进本轮云端生产/review/UI/Release，读取受影响截图与真实失败；必要修复追加提交，不自动重跑掩盖失败。
5. [ ] 收口更新日志、明确未签名/真实服务边界，清空当前工作台并交付。

## 验证选择

- baseline：静态架构/依赖/路径和 diff 审阅、`git diff --check`；云端 iOS/macOS 受影响 target 编译和共享 core 回归。
- direct：计时开始/暂停/继续/停止、默认 375/390pt 可达性、长任务/长分类、亮暗主题、辅助字号、日程和设置的共享面板回归；Mac 小窗/窄窗/详情实际快照。
- optional：用户明确要求发布级，执行现有固定完整链中的 Release 构建/编译资源检查及正式独立第四模式 review；不增加失败注入，不修改安全链或放宽验收。
- 实际入口：`ci-results.yml` 的 main push，成功后自动 `ci-artifact-review.yml` 与 `ui-evidence.yml`（mac、ios-390、ios-375、release）。本轮双平台 UI 与发布目标使完整现有链相关，无需扩建 CI。
- 未执行：本轮产品验证待提交；真实购买/系统授权/真机后台/签名发行缺少真实环境与发行资料。

## 编辑记录与下一步

- 本轮已编辑：iOS `AppTheme.swift`（新增）、`TimerPresentation.swift`（新增）、`DashboardView.swift`、`TimerView.swift`、`ScheduleView.swift`、`AnalyticsView.swift`、`SettingsView.swift`；Mac `MacTheme.swift`、`MacGlassPanel.swift`、`MacMiniTimerView.swift`、`MacTimerDetailView.swift`；`project.pbxproj`、`ChronoFocusUITests.swift`、`scripts/verify_project.sh`（只补新增文件接线）、README、flow、work。
- 已实现：独立纯展示组件；面板/控件圆角token；去除重复面板blur和计时光晕；完整换行队列与轮次；辅助字号统计单列；系统减少透明度/增强对比度/减少动态效果；停用按钮反馈；通知按钮对比色；编辑器键盘焦点/提交收起。未改模型、Store、Engine或持久化。
- 原生长任务测试追加真实队列完整标签、高度与可达边界断言，保留原9测试/38场景和全部接受条件。
- 历史失败日志已读取并保存在 `/tmp/chronofocus-ui-baseline-Uifec3Dw/ios-375-failure.log`：375pt在保存受保护草稿、分类输入和任务搜索的AX snapshot查询超时，最终xcresult不完整；不是已证明的布局失败。键盘焦点改进尚不能宣称已解决该故障，须本轮原生复验。
- `git diff --check` 第一遍发现Dashboard抽取后的EOF空行，已修复；第二遍通过。这仅是补丁格式检查，不是产品验证。
- 已提交 `6a4181c`（18个本轮文件）；首次 `git push origin main` 因 `Error in the HTTP2 framing layer` 失败，GitHub main仍为基线，尚未触发本轮云端验证。追加静态检查发现：180分钟等更宽倒计时在小表盘需明确单行缩放，已补上，未运行本机测试。
- 数字布局补丁已提交 `3f3bc56`；第二次命令级HTTP/1.1推送仍因45秒低速超时失败，没有修改全局配置。本轮产品验证仍未执行，不记通过。
- 两次只读 `ls-remote` 成功后，第三次有界HTTP/1.1推送成功，`main`已到 `3f3bc5647dfc395b4fa757380ea05b205d02cac1`（两条本轮提交，无用户文件）。连接诊断保存在 `/tmp/chronofocus-git-connect-S4AhKuQ8`、`/tmp/chronofocus-git-push-gpNl88rO`，未改全局Git配置。
- 云端生产 run `40694264906` / attempt 1 / SHA `3f3bc56` 已success（10m21s）：静态/项目验证、Mac与iOS Debug构建及结果包均成功。包 `12819396676`，16293486 bytes，`sha256:6dc795081ed1f0cdf75c4906b97874b2e0860862b236157927233f6f990b5970`；来源API已核对push/main/授权账号/固定workflow。
- 独立review `40695848730` / attempt 1 已success，待下载正式第四模式结论；UI/Release `40695848801` 已queued，尚不能宣称原生UI或Release通过。
- UI `40695848801` 的Mac与Release jobs已success（Mac 3m21s），两台iPhone已完成测试构建/启动并进入原生测试；仍等待完整UI结果及实际读图。
- 首次 `gh run download` 超过6分钟没有落盘，已终止本会话的下载进程，保留空证据目录 `/tmp/chronofocus-release-ui-3f3bc56-HJPlpgbB`；改用Go HTTP/1传输在全新 `/tmp/chronofocus-evidence-http1-ZRtoVmZr` 下载独立review（其包已包含原生产ZIP，避免重复下载）。这不改变远端测试结果，也不在本机执行验证器。
- 已读取独立review实际日志：正式第四模式 `validator_exit=0`、148 pass / 0 fail、source `40694264906/1/3f3bc56`、`product acceptance passed`。review artifact `12819666296`，32611611 bytes。
- `gh run download` 两次无文件落盘，已终止自己的进程并保留目录；改成精确artifact ID的 `gh api .../zip` 可持续下载，无需改产品/CI或运行本机validator。新目录：review `/tmp/chronofocus-review-api-YofNGOVo`（下载中）、Mac `/tmp/chronofocus-mac-ui-api-c6VnCcNA`（下载中）；Release `/tmp/chronofocus-release-download-6Ktuygcx/release.zip` 已下载并仅读取报告。
- Release实际报告同源，`engineeringChecksPassed=true`、`signed=false`、`distributionReady=false`；Mac arm64+x86_64、iOS/Live Activity arm64，隐私/版本/图标/Debug入口缺失检查均通过。正式身份、签名、支持/隐私URL和真实服务/真机仍待。
- 最新状态：390pt原生测试步骤failure，收集也failure，正在上传失败现场；375pt仍在原生测试。不能以其他job成功宣称本轮UI通过，不自动重跑。
- UI `40695848801` 最终failure：两设备均8 pass / 1 fail；真实job日志证明仅本轮新增的AX5队列“整张卡片须完整装入视口”断言失败（390pt底边855.83>755，375pt底边946>578），其余原8条全部通过，历史AX查询超时未复现。该断言不适用于可滚动完整长卡片，旧有主操作/通知/日程边界断言均保留。
- 最小修正：新增队列检查改为真实可达+完整标签+展开高度+横向边界，并保留具名原图；补齐本轮统计单列的实际原生几何断言和截图。仍为9测试，场景从38增至40，严格场景归属及缺失拒绝fixture同步；分摊到原两条大字体测试，不增加超时、不重跑旧失败run。
- 失败原生日志 `/tmp/chronofocus-ios390-failure-WxL5v22k`；390 artifact `12821145692`（352061946 bytes，sha256:3a9398bc8493b5eb0a5e27bfee3b8234b2473e3f5d603737c01bde825d991233），375 artifact `12821540053`（220023356 bytes，sha256:e9009d2efaf3f47ca610f46911670be2a9c3d961b823750e72d1bdc78e35b77b）。
- 大ZIP传输确实极慢，保留32/62MB下载残留后改用精确artifact的HTTP Range仅读原始条目，保留原始206响应、central directory、选定summary/manifest/原PNG，不执行任何包内代码；这是静态取证，不在本机重跑产品或validator，也不声称部分下载通过完整ZIP验收。临时读取器在 `/tmp/chronofocus_read_artifact_entry.py`，不加入项目。正式完整包第四模式仍以Actions结论为准。
- 最小修正已提交/推送 `80fac050d6e431ef500aabca6e9f542fd67fede0`，生产 `40700336601/1` 已success（9m14s），双端Debug构建/项目验证成功；包 `12822221214`，16293498 bytes，`sha256:f16ea75bf560d57998c1f39a9f384b572da3abccb1d4d9e277fa9ce0cc6b3fc7`。来源push/main/授权actor/固定workflow已复查。独立review `40701821636/1` 已success，UI/Release `40701821565/1` queued。静态 `git diff --check` 通过，本轮其他用户文件仍未提交。新SHA UI结果未完成，不使用旧3f3bc56证据替代。
- 已实际读图：390pt原失败PNG `/tmp/chronofocus-ios390-image-40695848801/3DB13F11-8179-4F2A-84ED-854DE61C2932.png`，确认完整大字号标题自然占满多行、可滚动卡片高于视口，而不是主按钮遮挡；Mac原图 `/tmp/chronofocus-mac-dark-40695848801/timer-1100.png` 确认双列、主操作、薄环、面板与换行队列清晰。这些是首轮视觉诊断，新SHA仍须验收。
- 新review实际日志已读取：`40701821636/1` 正式第四模式148 pass / 0 fail、exit0、product acceptance passed，source为 `40700336601/1/80fac05`。新证据根目录 `/tmp/chronofocus-final-80fac05-ZajiWC7G` 保存source/review原始API与日志。
- 新UI `40701821565` 的Mac job已success，artifact `12822212400`（62589056 bytes，sha256:f3d43d3848491ab05dc22cf2c074256a281fbb8f4ee462b274273b36d973aa26）；新原图/manifest仅读下载中。两设备处于原生测试，Release仍构建检查中。
- 新SHA实际Mac亮色双列和920pt暗色紧凑原图已读取：`.../mac-selected/timer-light.png`、`timer-920.png`；主操作清晰可见，亮暗文字/圆角/表盘与单列回退正常。manifest绑定source `40700336601/1/80fac05` 和UI `40701821565/1`。
- 新Release已success并读取真实报告：artifact `12822991054`，278795 bytes，sha256:69988f40d35bcdbf01d857f1afdee98d2b109b873ee403219d4e120654e9ec51；目录 `/tmp/chronofocus-final-release-80fac05-jMjk0XvO`。报告同源、工程true，Mac双架构/iOS与appex arm64、Debug入口缺失；仍signed=false/distributionReady=false。
- 新375pt已上传成功证据 `12824240106`（63578906 bytes，sha256:e70ab59d327da259b14cd88d5cb3ebc671763d09e01944b7c36df8b0526e8402），summary/场景仅读下载中；390pt仍在原生测试。
- 375pt已读取真实summary与证据：9/0/0、40场景；大字号队列/统计测试均通过，单条76.97s/82.69s。关键原PNG仅读下载中。
- 新UI总结果仍failure：390pt仅大字号测试超过120秒，其余8条通过。真实日志显示新队列检查已完成、已切到设置；失败发生于寻找通知授权按钮时反复滚动直到单测时限，不是统计单列或原卡片整屏断言。终止诊断随后也失败，需读取原生失败附件核对滚动/命中现场；不增加时限、不自动重跑。390 artifact `12822394203`，231765685 bytes，sha256:8c5e2d140e6ec1b3f19454aa3f6aaf9c0de560dbc22ca27c444c362dca862634。
- 已读取390pt原生AX快照与7.7MB诊断spindump（仅读原始运行证据，不在本机运行产品/校验配置），目录 `.../ios390-ax-diagnostics`。长任务/队列已耗时约90秒，再进入设置后因重复查找/拖动到达120秒；采样在XCTest查询与日志写出路径，不足以宣称App自身死锁或给出CPU/FPS改进数值。
- 最小后续方案：把原长字号测试拆为长任务/队列和“同一长任务运行中的通知设置”两个独立用例，各自从真实fixture启动；保留原所有40场景、全部按钮边界/可达断言及120/180秒限制。实际执行集合从9增至10，verifier/fixture/workflow门禁同步要求10个Passed，不通过减少检查或增加等待绕过。
- 同时静态发现Dashboard根导航与Debug编辑保护容器只发Engine生命周期命令却通过EnvironmentObject订阅每秒发布，改为由App传入同一Engine引用；计时页面仍观察原EnvironmentObject，核心状态机和持久化不变。这是减少无用根失效传播的结构优化，尚待新SHA验证，不声称已测得性能指标或已消除全部AX问题。
- 通知权限状态/授权入口拆成纯展示组件并前置到“后台与提醒”节标题之后、四个开关之前；保留原NotificationService动作和44pt/全宽按钮，减少大字号用户寻找授权入口的滚动成本，也收窄Settings的ViewBuilder复杂度。
- 新增编辑：`ChronoFocusApp.swift`、`DashboardView.swift`、`SettingsView.swift`、UITests、两个原生证据脚本、UI workflow（仅10测试门禁）、README/flow/readiness/work/update_log。其余用户文件保留。
- 新SHA前静态diff发现workflow嵌入Python的一行缩进错误，立即修复，未执行本机YAML/配置校验；云端继续承担真正解析/fixture验证。
- 上述优化已提交/推送 `bc3a0d3a39d16f6fd6cd8c11ac6e1b01e08e5d47`，生产 `40709909360/1` 已success（6m8s）：静态/项目验证（含10测试/40场景fixture）、双端Debug与完整结果包成功；artifact `12826855381`，16292506 bytes，sha256:080ce317f912a7ac3e91d65140c35554bd445dcb7482f55cc9a59e0f95d8b5d7。独立review `40710942732/1` success，UI/Release `40710942641/1` queued。静态 `git diff --check`通过。账号/分支/remote及仅本轮12文件范围已核对。没有本机编译、项目测试或配置校验。
- 2026-10-29接续：重新读取工作台/规则并核对Git，`git fetch origin`、`git pull --ff-only origin main`成功，仍为`bc3a0d3`且远端一致，授权账号仍为`Altman-sam114`；仅有已登记用户文件与本轮work改动。
- 最新云端API确认：生产`40709909360/1`、独立review`40710942732/1`、UI/Release`40710942641/1`全部success；UI四个job均实际完成，375/390原生测试与结果收集均success。尚须读取精确新SHA原始summary、review结论、Release报告和受影响原PNG，不能只凭绿色状态收口。
- 新证据目录`/tmp/chronofocus-final-bc3a0d3-DVqkAfaG`保存原始source/review/UI/artifacts/main/workflow API；已读取正式review原文`review-result.json`（148/0、exit0、product acceptance passed）、JUnit4/0/0、Mac同源manifest/17图清单及新Release原报告（工程true、signed=false、distributionReady=false，Mac双架构与iOS/appex arm64，Debug入口缺失）。review artifact`12825044379`、Mac`12826387515`、Release`12826128185`；手机375/390为`12828360199`/`12826914966`。
- 原始artifact Range仅读首轮手机取证发生网络连接超时，review/Mac/Release读取成功；保留残留和错误，在全新目录缩减请求次数并有界重试必要metadata/原图。这不是重跑产品测试，也不把部分Range下载声称为本机完整ZIP验收；完整包第四模式仍使用Actions真实结论。本机未编译、运行、执行测试/validator或配置校验，`git diff --check`再次通过。
- 已读取两设备真实summary/tests：各10/0/0、40具名场景；375总695.037s、390总617.778s。长任务与运行中通知分段均在原120秒内完成；共享core真实日志包含开始/暂停/恢复/完成、查询/循环身份/提醒/持久化/权限/倒计时回归通过。
- 实际读新SHA原图：375默认首屏主操作完整、亮暗通知授权文字和44pt按钮清楚、AX5统计单列；390亮色和运行/通知待补读；Mac亮色双列、暗色920单列、长文本与小窗快捷面板清楚。
- 视觉退回：375的`large-text-queue`原PNG（`ios375-images/selected/attachments/5C3F27CF-021E-414D-92A5-D7E611551BBE.png`）证明“当前日程”标题被数量HStack挤成四行逐字竖排，当前自动化虽全绿但不能放行。新增最小步骤：抽取纯展示队列标题，大字号纵排标题/数量，正常字号保持横排；在原长字号用例增加标题高度与数量纵向几何断言，保留10测试/40场景与所有旧断言/时限。不更改Engine/Store或安全链。
- 该最小补丁已实现：`TimerPresentation.swift`/`TimerView.swift`/UITests与README/flow/update_log/work共7文件；静态检查未发现合同中对旧标题源码位置的依赖，`git diff --check`通过。本轮发布导向双平台重构仍按已登记完整入口验证，新补丁直接关注iOS375/390的队列标题/数量几何和原图，不新增测试超时或CI开关。提交前再次核对账号/分支/remote与文件范围，用户3个文件未动。
- 下一步：实现标题最小补丁、静态审查并追加main提交；跟进新SHA必要云端链与原PNG，不重跑旧run或以bc3a0d3绿色结果替代新修改。
