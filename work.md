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

- 追加产品提交4ce58b427cd7867a948eebe33d24e471fdd4530c已原样发布origin/main（Git API tree/commit均与本地相同，force=false，原始请求响应/var/folders/l1/d94q360s65q4lqwzvk97px9w0000gn/T/chronofocus-git-api-2vhrvhe1）。新生产43559368529/1运行中；新证据目录/tmp/chronofocus-4ce58b4-evidence-3w0c3hd7。最终结论仅接受新SHA，旧8bdc05b的UI失败已保留。

## 新 SHA 验证进展

- 4ce58b4：生产43559368529/1 success（总8m52s，Project verification5m04s、Mac Debug2m07s、iOS Debug1m09s）；生产artifact14099389601，16325932 bytes，sha256:4392ac862ee493f64e958f7b5539cb62f159fb9d4b82ccc0621388cd1d774ea1。
- 独立review43560130081/1 success，artifact14100255141；已读review-result、完整第四模式命令、JUnit及core原文：148/0、exit0、product acceptance passed、JUnit4/0/0，实际两端商品加载/购买准备互斥和失败重试回归与core通过。
- UI/Release43560129932/1：Mac21图和Release成功；Mac artifact14100058552（79885305 bytes），Release14099714529。已读新的Release报告与同源manifest：精确4ce58b4/43559368529/1，actualCheckout相同；engineeringChecksPassed=true、signed=false、distributionReady=false，三个产品架构/隐私/资源/Debug入口检查通过。
- 两台iPhone已进入原生测试（375于05:16:34Z，390于05:17:45Z）；等待完整11/0/0、45场景及关键原PNG，不提前接受或收口。新Mac关键PNG正在按原始ZIP条目读取。

- 新Mac同源manifest/fixtures已读取，21图/6亮色，actualCheckout=4ce58b4；已实际查看新Pro亮/暗、920pt统计全页和空统计四张原PNG，图标/按钮/数值/空态可读，窄窗面板纵排，无本轮新增的覆盖问题。仍待两台iPhone完整原生证据。

## 2026-11-17 接续与失败定位

- 已核对main与origin/main均为4ce58b4，fetch/pull成功，授权账号Altman-sam114；用户原有3处文档改动继续保留。接续工作区已有的本任务UI测试拆分和合同修改，不纳入用户历史prompt。
- 真实UI43560129932/1最终failure：375的Pro综合用例触及120秒，随后App启动失败，整体14分钟被截断且xcresult未封口；390前10条passed，最终主题用例被14分钟截断。原始日志保留/tmp/chronofocus-resume-20261117/ui-failed.log；未重跑旧run。
- 修复：同一Pro日历场景独立启动，12条测试仍绑定全部45场景与原断言；单条120/180秒保持，总步骤14改20分钟（11条实际串行加启动已超14分钟），总job35分钟保持。同步fixture与flow/readiness，未删场景或放宽视觉/身份验收。
- 本轮新增编辑范围：UITests、ui-evidence workflow、verify_ios_ui_evidence和两fixture、flow/flowchart/readiness/update_log/work。下一步静态审阅、提交推送并等待精确SHA全链。

- 已提交并推送ff574846d9c08f65d7a304ff5ebb1dda27ad9763，生产44074461660/1正在Project verification；git diff --check与暂存差异审阅通过（仅静态）。工作区仅剩用户原有3处文档改动。本机不运行任何产品测试或配置校验。

## ff57484 云端验证

- 生产44074461660/1 success，原始日志已读：静态fixture21/8/11/8全通过、两端Premium互斥/失败重试和Mac core passed、两端Debug BUILD SUCCEEDED。
- 独立review44076184813/1 success；已读取review-result、validator-command与JUnit，正式完整第四模式148/0、exit0、product acceptance passed、JUnit4/0/0。生产artifact14325585783，16285736bytes，sha256:9f279573a4f6ef5ee40bb6e130f0f4cb1b11cdf6dd292e1f6127c137b3ae39ff。
- review artifact14324014972（32616429bytes，sha256:b8fc34d8c9f0e2a373fc06e4e33bb882048db6e8dfc6eaea9debbc43254f88cc）已按原始API下载并核对size/digest/CRC/路径，证据/tmp/chronofocus-resume-20261117/44076184813-chronofocus-review-qro30avw；未在本机运行validator。
- UI/Release44076184820/1进行中，仍待两机12/0/0、45场景、Mac21图、Release工程报告与本轮原图。正式发行资料已异步询问，不阻碍工程验收。

- 用户确认先完成工程验收，正式发行资料稍后提供；本轮以工程级验收收口，仍保留distributionReady=false边界。
- UI44076184820/1：Mac与Release已success，两iPhone进入原生测试。Mac artifact14325466878（79815076bytes，sha256:606f0f24d4c0a41d76dc9f2f81d1ebd42d85eeed8f1097faba83d87e3ca49e90），Release14325876106（273094bytes，sha256:eacd5baf4463722eaff9699bda4ba5c91ecfc3fac5730f9755d413098973d74d），均已核对API/ZIP完整性。
- 已读同源Mac manifest21图与原始Pro亮暗、920pt统计全页、空态、设置五图；图标/按钮/数值/换行正常，未发现新增遮挡。
- 已读Release原始manifest和真实命令：同源ff57484，Mac arm64+x86_64、iOS及扩展arm64，engineeringChecksPassed=true、signed=false、distributionReady=false；资源/隐私/Debug入口检查通过。原始证据在/tmp/chronofocus-resume-20261117对应run平台独立目录。

## ff57484 手机验收退回与修复

- UI44076184820/1最终failure：375为12/0/0、45场景通过；390为11/1/0，testScheduleAccessibilityAndActions在点击编辑后分类输入框不存在，非超时。失败录屏与AX层级确认仍停留日程，无TaskEditor，不将其归因为已证实系统/布局根因。
- 390失败artifact14326446793（317329675bytes，sha256:1fbc7696111093aebedc99e4e2688288244b6d2d661e7434f56014b8a75f977a）已核对API摘要/大小/CRC，证据44076184820-ios-390-50lxw6ay；录屏65–72秒和原AX已读取。375 artifact14327175012（72984728bytes，sha256:e57996b78ead1fa463bebc998ecf4f618852a49ab025b369593d05c4ec0a3463）同样已核对。
- 修复日程新增/编辑的双sheet状态，使用EditorDestination携带任务与根NavigationStack单一sheet；辅助字号大面板、普通字号保留中/大。不改变任务保存/取消/计时保护。原用例增加点击后编辑器取消按钮断言，保留分类值、截图和后续接力全部断言，12条/45场景和所有时限不变。同步verify_project原动作接线合同及README/flow。
- 新增本轮文件：ScheduleView、scripts/verify_project.sh、README；下一步静态diff审核、追加提交main并跟进全链，不自动重跑旧run。
