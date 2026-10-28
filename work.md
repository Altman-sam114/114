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
3. [进行中] 静态审查 diff、更新必要行为文档，聚焦提交并推送 main。
4. [ ] 跟进本轮云端生产/review/UI/Release，读取受影响截图与真实失败；必要修复追加提交，不自动重跑掩盖失败。
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
- 下一步：完成本轮提交/推送，跟进精确SHA的完整云端链并读图。本轮尚未 commit/push。
