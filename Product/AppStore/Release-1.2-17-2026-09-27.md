# SteelFlow 1.2（17）首页与图标优化

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- App 图标去掉纸张背景，保留钢材、尺寸标记和 kg，采用纯色背景并放大主体。
- 继续上次草稿去掉右侧重量，使用左侧型材图标与右侧两行摘要。
- 最近计算改为无单条背景填充的紧凑列表，显示标题、尺寸和材料，记录之间使用细分隔线。
- 型材、设置、Pro 权益、操作符号和底部导航统一增加克制的金属反光与高光边缘。
- 原生标签栏明确使用系统标签样式，修复全局图标样式引起的切换异常。

## 验证

- 深浅色首页、最近计算和设置页面已进行模拟器视觉检查。
- Debug 构建及 diff 空白检查通过。
- 现有 UI 测试通过：四个主标签的页面内容、默认计算与保存入口，共 2 项。
- 测试结果：`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T06-03-10-676Z_pid92380_eab03259.xcresult`。
- 截图：`output/home-summary-20260927/`。

## 发布产物

- 归档：`Build/PolishedRelease-20260927/SteelFlow-1.2-17.xcarchive`。
- IPA：`Build/PolishedRelease-20260927/export/SteelFlow.ipa`。
- Release 归档、App Store IPA 导出及归档 codesign 严格校验通过；包内版本为 1.2（17）。
- IPA SHA-256：`e8a5df5afe77362170a4b060de2a148155b77846c568926de74169f907efbc65`。
- 上传网络：Clash 规则指向 SelfBoot，当前选择「香港」。
- 上传返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`2ce957df-8059-4202-902e-46e518b17b0e`。
- 传输 10,693,809 字节，用时 0.980 秒。
- Clash 实际连接确认 contentdelivery、App Store Connect API、object-storage 三类域名均经过「香港」，证据：`Build/PolishedRelease-20260927/upload-network.json`。
- App Store Connect 已确认营销版本 `1.2`、构建 `17`，`processingState = VALID`、`buildAudienceType = APP_STORE_ELIGIBLE`，结果保存于 `Build/PolishedRelease-20260927/builds-after.json`。
- 本次上传完成，未提交 App Review。

## TestFlight

- 已加入现有「SteelFlow 当前构建」内部测试组，Apple API 返回 204，随后读取组内构建确认包含 17。
- 已核对该组测试者仅为此前用户指定邮箱 `xuezaigds@gmail.com`。
- 内部测试状态为 `IN_BETA_TESTING`，`autoNotifyEnabled = true`。
- 邮件由 Apple 自动通知机制处理；API 未提供邮件投递回执，不声称实际送达。
