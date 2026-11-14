# 当前任务

## 目标、范围和当前状态

- 2026-11-14：用户重新启动“继续全面重构优化，特别是 UI，云端编译，快速做到发布级”。接续同一目标，上一轮工程验收见 update_log.md；旧产品 SHA 8100b1d 的结果仅作历史。本轮正在实现新的可独立验收的 UI 和交互改进。
- 重点：统一两端 Pro 的购买/恢复/状态反馈；移除 iOS 统计预览遮罩，改为清晰的功能介绍；修复统计/设置/日程相关大字号与窄窗布局；改进统计图的零值和可访问表达；收窄与本轮直接相关的复杂视图结构。
- 非目标：不改变 TimerEngine/FocusStore 所有权、不新增持久化和第三方依赖，不替用户选择正式身份或发行渠道，不启动子智能体，不运行任何本机编译/测试/validator/配置校验。
- 验收：本轮精确源码 SHA 的云端两端 Debug、共享 core、独立正式第四模式 review、两设备原生相关场景、Mac 新旧布局和 Release 工程检查均通过；实际读取受影响原图，不能只凭 build 或元素存在。

## Git 和改动边界

- main，基线 c99d2c0；已 git fetch origin、git pull --ff-only origin main，0/0，授权账号 Altman-sam114，origin https://github.com/Altman-sam114/114.git。
- 用户已有修改 md/prompt/v1（持续优化）/v1.10（待办检索与安全管理）.md；未跟踪 md/1.md、md/通用云端迭代升级提示词.md。全部保留，不编辑、不暂存。
- 本轮编辑记录：work.md、Shared/PremiumPresentation.swift、Shared/FocusHistoryChart.swift、project.pbxproj；已修改 iOS AppTheme/Analytics/Settings/Schedule、对应 Mac Analytics/Settings/Schedule/基础展示组件，以及与新场景直接相关的 UITests、renderer、证据合同和受影响文档。两端 PremiumAccessService 已修复嵌套加载提前释放忙碌状态，注入 productLoader 用于实际两端服务的并发/失败重试回归；scripts/test_mac_core.swift 与 verify_project.sh 加入该回归。
- 产品提交 8bdc05bfe30b7f16ec37a946b442098975734e1c 已发布 origin/main；Git HTTPS fetch/push 发生连接/低速超时，改用授权账号 GitHub Git API 上传同一 tree 和同一 commit（哈希完全相同），force=false 更新 main 后同步本地 origin/main。原始 API 请求/响应在 /var/folders/l1/d94q360s65q4lqwzvk97px9w0000gn/T/chronofocus-git-api-ezrduqa0。不新建分支、PR 或 worktree。

## 分步计划

1. [完成] 核对基线、既有改动、源码和云端入口；识别重复购买入口、iOS 预览遮罩、统计窄列/大字号拥挤和零值柱形问题。
2. [完成] 实现可复用购买反馈与介绍组件，修复对应布局与统计表达，保持业务与快照语义一致。
3. [完成] 补直接 UI 证据和原有场景回归；同步受影响 README/flow/test/readiness，静态检查本轮 diff 与提交范围。
4. [进行中] main 提交推送，跟进同源生产/review/UI/Release；若失败先读真实日志追加修复，不自动重跑掩盖。
5. [待办] 读取原始结果与关键原图，记录实际证据和发行边界，提交文档收口。

## 验证选择

- baseline：静态阅读、路径/架构/diff 审阅、git diff --check（仅空白检查）；云端两端 Debug 与共享 core，保持正式包的独立第四模式安全链。
- direct：两端 Pro 未解锁的功能介绍、购买/恢复文字和状态可读性；iPhone 375/390pt 与 accessibility5 下按钮至少44pt、布局/边界/可达性；Mac 920pt窄窗与亮暗预览/统计；已有计时和任务行为必要回归。
- optional：用户明确要求全面发布导向优化且本轮涉及两端公共面板、统计/设置/日程，因此采用仓库现有固定完整入口，包含 Release。没有臆造 profile/场景参数；不做无关失败注入或本机复跑。
- 入口：main push 触发 ci-results.yml，成功后 ci-artifact-review.yml 和 ui-evidence.yml；云端实际命令/新 SHA/run/attempt/artifact 待执行后记录。

## 风险、未执行与下一步

- 正式发行仍需 Apple Team、正式 Bundle/商品身份、渠道、公开隐私/支持 URL，以及真实购买/系统权限/真机与签名安装实测；本轮可继续完成工程优化，不能宣称正式上架通过。
- 新布局须保留快照与真实控件同一内容/状态，不能只修截图路径。原生截图集合若扩展，需同时更新真实测试和证据绑定合同。
- 下一步：实现上述组件与适配，再进行静态 diff 审阅并推送云端。

## 实现进度

- 两端统计/设置/日历共用 Pro 操作组件，静态快照与真实按钮共用同一 surface；恢复为文字按钮，activityText 唯一忙碌状态，不修改真实 StoreKit 权益来源。
- 两端报表与周图共用展示组件，去掉零值假柱形/柱内微小文字，辅助字号逐行显示；iOS统计/设置/日程适配、Mac统计自适应列；设置补主题入口。
- 新增一个实际原生测试并扩展两个既有测试，合计11条/45个具名场景；Mac增加4张为21张，6张亮色。证据集合和对应缺图负例已同步；未增加时限或放宽原断言。
- git diff --check 与暂存补丁审阅通过（仅静态/空白）；用户3处改动未纳入。生产 run 43556484943/1 对应精确 SHA 8bdc05b，push main，静态检查已成功、项目验证运行中；后续尚未接受产品或 UI 结论。下一步跟进实际日志、独立 review 和新截图。

## 云端阶段进展

- 生产 43556484943/1 success（2026-11-14T04:24:17Z 至 04:29:48Z，5m31s）；共享core包含两端 Premium operations serialized 实际成功日志，Mac core passed，两个 Debug 构建和必要上传成功。
- 独立review 43556929489/1 success；已读取 review-result.json、validator-command.json、JUnit 与 core 原文：正式第四模式148/0、exit0、product acceptance passed；JUnit4/0/0，参数绑定精确 SHA/run/attempt/API digest 和完整ZIP。
- 生产 artifact 14097849082，16326372 bytes，sha256:46e8bbadafbdf8d2f7eaf5e81ad5b8dd60d2277566da0680bbbb983630e5aa77；review artifact 14097859057。
- UI/Release 43556929569/1 的 Mac、Release、ios-375 jobs 已 success，ios-390 尚在执行。Mac artifact 14098253431；Release 14098862574；375为14098819505。
- 已读 Release 原始报告：engineeringChecksPassed=true、signed=false、distributionReady=false；Mac双架构/iOS和扩展arm64、隐私/资源/Debug入口检查通过。实际Release命令已取回，正式身份及真实服务仍未覆盖。
- 原始 API 与必要 ZIP 条目取证目录 /tmp/chronofocus-8bdc05b-evidence-iyr_zt34；使用 HTTP 206 选择必要原始报告/PNG并保留目录与响应，不在本机运行产品validator，也不将部分读取冒充完整包第四模式（后者由Actions完成）。
- 2026-11-14T04:47:37.499807+00:00：等待390完成并读取新增原图；尚未接受最终视觉结论，未清空工作台。

## 首轮失败与追加修复

- 8bdc05b 的 UI 43556929569/1 最终 failure：Mac/Release/375 success，390测试步骤14分钟超时，collection因未封口xcresult缺Info.plist失败，上传失败现场成功；未接受完整UI结果。
- 原始390 job 132331807605日志已保存 ios-390-job-132331807605-attempt2.log；10条用例逐项passed，最后testThemeSwitchAcrossTabs在48.10s时被总步骤时限截断。首用例94.984s，其余功能用例均passed；没有把部分日志当11/0/0。失败artifact14099960769，79057523 bytes。未重跑旧run。
- 实读375的新功能/操作/日历原图，按钮完整但装饰功能图标随辅助字号长出固定28pt栏，发生边缘相接；追加修复固定装饰图标20pt，正文仍随系统字号完整缩放。
- 实读Mac Pro暗色、920pt统计全页；新布局和零值基线、可读数值正常。已取回Pro浅色/空态/设置图及375五张新图，但新修复后需新SHA复验，旧图不替代最终证据。
- 追加改进：时长设置默认摘要，点开真实Stepper，给提醒与授权入口留出空间；主题用例新增真实展开/数值断言后收起，原测试集合/45场景与14分钟/120/180秒时限不变。滚动助手减少重复导航/TabBar查询，最终仍读取真实坐标做原有边界断言。
- 本轮追加编辑：Shared/PremiumPresentation.swift、SettingsView.swift、UITests、README、flow、update_log、work；仅静态审阅后追加提交，不运行本机验证。下一步新SHA重新执行完整相关云端链。
