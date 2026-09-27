# SteelFlow 1.2（19）中心高光与收藏交互

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- 设置、Pro、底部导航、型材及操作图标改为中心向四周衰减的高光，去掉左上定向反光带。
- 最近计算完整列表中，收藏按钮调整至右箭头左侧，收藏操作与进入详情相互独立。
- 首页常用规格右侧提供取消收藏按钮，移除收藏后仍保留计算记录。

## 验证

- Debug 构建及 diff 空白检查通过。
- 深浅色图标与最近计算、浅色首页收藏布局已进行截图检查。
- 首页取消收藏且保留记录、完整列表收藏不误入详情，两项回归测试通过。
- 测试记录：`test_sim_2026-09-27T06-43-32-373Z_pid92380_d7c5b377.xcresult`；深色复查：`test_sim_2026-09-27T06-44-58-039Z_pid92380_44c8383d.xcresult`。
- 截图：`output/center-light-20260927/`。

## 发布产物

- 归档：`Build/CenterLightRelease-20260927/SteelFlow-1.2-19.xcarchive`。
- IPA：`Build/CenterLightRelease-20260927/export/SteelFlow.ipa`。
- Release 归档、App Store IPA 导出及归档 codesign 严格验证通过；包内版本确认为 1.2（19）。
- IPA SHA-256：`3578c3bdb5fb47ddac33ba154f23ed6702be5f174e841684dc936e15313b3831`。
- 上传返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`8a80e438-c582-445f-830d-8d03aa6c9486`。
- 传输 10,732,155 字节，用时 0.889 秒。
- 实际连接确认 contentdelivery、App Store Connect API、object-storage 均经过「香港」，记录：`Build/CenterLightRelease-20260927/upload-network.json`。
- App Store Connect 已确认营销版本 `1.2`、构建 `19`，`processingState = VALID`、`buildAudienceType = APP_STORE_ELIGIBLE`。
- 本次上传及 Apple 处理已完成，未提交 App Review。

## TestFlight

- 构建 19 已加入现有「SteelFlow 当前构建」内部测试组，Apple API 返回 204，读取组内构建确认包含 19。
- 操作前实时核对该组测试者仅为此前指定邮箱 `xuezaigds@gmail.com`。
- 内部测试状态：`IN_BETA_TESTING`；自动通知：`autoNotifyEnabled = true`。
- 邮件交由 Apple 自动通知机制处理，无实际投递回执。
