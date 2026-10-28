# ChronoFocus 发布准备

本页区分工程验证与正式发行。当前公开产品版本设置为1.0/build1；历史v1.x提示词版本是工程迭代号，不是发布版本。发行任务的Release检查须由同源main的Actions实际执行，普通文档或局部功能任务不默认运行发行链；未签名构建不能用于宣称已上架或已完成发行验收。

## 工程验证范围

- 生产：静态检查、共享core执行回归、Mac/iOS Debug generic build、五张正式Mac图、JUnit阶段摘要、独立只读第四模式复判与原始ZIP/API证据。
- UI：当前完整证据合同要求Mac17张布局图含亮暗主题、窄窗、1100pt双列长标题/长分类、分类展开、暂停/空态/只设开始与已完成任务检索；两种iPhone各10条原生测试、40个具名场景，覆盖通知动作、主题、大字体日历/长任务/长分类、编辑取消和只选择接力、任务搜索/完成找回/恢复、筛选后新增可见、删除确认/取消/活动保护，以及保存被计时保护拒绝时的草稿保留。真实测试树、summary、场景归属、UDID与完整尺寸均绑定，不能以总数或其他图片补足。工程结论只接受对应源码SHA同源的完整证据与实际读图，不引用历史通过替代本轮验证。
- Mac视觉收口：分类选择标签最多两行，完整名称由悬停、辅助功能和搜索提供；任务标题/分类正文保持完整换行。长分类控件此前曾在自动化通过后被实际读图发现过高，后续相关UI验收仍须同时确认紧凑筛选与完整正文，历史证据见更新日志。
- Release：云端执行Mac通用二进制（arm64+x86_64）与iOS arm64构建，读取三个真实bundle的身份/版本/最低系统/架构/二进制摘要；核对Mac真实ICNS系统解码和Assets.car中同名1024×1024图标、嵌入Live Activity版本和隐私资源，并拒绝主App中出现Debug UI测试入口。保存ICNS原文/解码图/逐entry与assetutil原文，源PNG不能替代编译资源证明。
- 系统边界：共享core验证日历完整读取权限的申请/拒绝/只写升级/await后复查/错误，以及Live Activity的未来、恰好到点、过期区间。系统真实授权和真机行为仍需独立实测。

编译、运行与测试默认仅由GitHub Actions执行，用户明确要求本机时才按授权范围处理；本机iOS仅允许现有FAC4325D前缀的唯一模拟器。生产入口为`bash scripts/verify_project.sh`，Release入口为`bash scripts/run_release_readiness.sh`，完整xcodebuild参数保存在对应artifact的`release-command.txt`。Release证据与UI在独立矩阵中上传，绑定源SHA/run/attempt和证据run/attempt，上传前后复查main；不加入生产结果包，也不上传DerivedData或完整未签名App。当前矩阵仍固定全量，没有按任务裁剪入口，测试选择与缺口处理见[测试规范](../test/test.md)。

## 当前身份资料

| 项目 | 当前值 | 发行前所需 |
| --- | --- | --- |
| iOS Bundle ID | com.example.ChronoFocus | 发行账号下的正式标识 |
| Live Activity Bundle ID | com.example.ChronoFocus.LiveActivity | 同父App前缀的正式扩展标识 |
| Mac Bundle ID | com.example.ChronoFocusMac | 正式Mac标识 |
| Pro商品 | com.example.ChronoFocus.pro.analytics | App Store Connect实际非消耗型商品与可用状态 |
| Apple Team | 空 | 已授权的Team及签名配置 |
| iOS渠道 | 未指定 | TestFlight或App Store流程 |
| Mac渠道 | 未指定 | Mac App Store，或Developer ID签名与公证直发 |
| 公共隐私政策/支持地址 | 未提供 | 可公开访问的URL与真实联系资料 |

Mac当前为非sandbox状态栏App并启用hardened runtime构建设置。若选择Mac App Store，需按该渠道配置sandbox与日历等必要entitlement后重新验证；不提前替用户选择渠道或签名账号。

## 数据与权限依据

任务、设置、会话、计划和活跃快照由FocusStore保存为本App的UserDefaults JSON；App没有账户系统、开发者服务器上传、第三方追踪或自有云同步。Debug隔离测试suite仅在显式测试参数下启用，Release产品检查会拒绝其入口。系统备份是否保存App数据由操作系统和用户设置决定。

日历同步仅在Pro入口由用户触发，读取未来45天的非全天事件，将标题、来源日历分类、开始时间和估算轮数存入本机Store；不把日历内容发给开发者服务器。购买由StoreKit/Apple处理，通知和Live Activity会把任务名称交给系统显示，用户可管理系统显示范围。设置中的数据说明不能替代公开隐私政策和App Store隐私表单。

Shared/PrivacyInfo.xcprivacy仅声明App自身UserDefaults用途CA92.1，tracking=false、domains和collectedData为空；两个主App共享该资源。Live Activity没有直接访问UserDefaults，使用独立空API清单。新数据收集、SDK或API使用变化必须重新审阅声明，不能沿用当前结论。

Apple依据（2026-10-23核对）：[EventKit访问](https://developer.apple.com/documentation/eventkit/accessing-the-event-store)、[请求完整日历访问](https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoevents(completion:))、[TN3183隐私API声明](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)。

## 仍需真实环境验证

- 使用正式商品/沙盒验证购买、取消、待处理、恢复、退款/撤销和离线启动；当前fixture不提供真实Pro购买证据。
- 日历完整访问、拒绝、仅写入升级、系统撤销后重试；通知授权/拒绝、到点与到期提醒、铃声和系统设置返回。
- 真实iPhone的锁屏/灵动岛、到点后停留、暂停/继续、切后台、系统时间变化、App被结束后恢复；两个模拟器的App内点击不替代该层。
- 在选定分发渠道完成签名归档、安装/升级/卸载与数据保留，以及App Store审核或Mac公证/Gatekeeper；工程build成功不能替代这些结果。

发行验收由当前会话核对对应main源码的生产/review/UI/Release同源证据，不需要角色交接。交付时列出剩余资料和实测项，不把占位身份、静态快照或未签名build写成可正式发行；普通开发按本轮相关范围验证，不把整套发行检查变成日常前置条件。
