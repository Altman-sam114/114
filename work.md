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
- 未提交、未推送本轮改动；不新建分支、PR 或 worktree。

## 分步计划

1. [完成] 核对基线、既有改动、源码和云端入口；识别重复购买入口、iOS 预览遮罩、统计窄列/大字号拥挤和零值柱形问题。
2. [完成] 实现可复用购买反馈与介绍组件，修复对应布局与统计表达，保持业务与快照语义一致。
3. [进行中] 补直接 UI 证据和原有场景回归；同步受影响 README/flow/test/readiness，静态检查本轮 diff 与提交范围。
4. [待办] main 提交推送，跟进同源生产/review/UI/Release；若失败先读真实日志追加修复，不自动重跑掩盖。
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
- 尚未运行产品验证；下一步静态审查剩余 diff、git diff --check、核对用户变更边界，main提交推送后跟进完整链。
