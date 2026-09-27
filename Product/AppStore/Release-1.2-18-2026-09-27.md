# SteelFlow 1.2（18）材料页与计算记录优化

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- 材料页顶部、搜索区、分类控件周围和材料列表统一背景，移除分组填充及顶部滚动渐变造成的色块分隔。
- 增强底部导航及设置图标的金属高光、反光带和透光边缘。
- 最近计算「查看全部」采用单行记录，右侧独立收藏星标，收藏时不进入计算详情。
- 重新打开记录仍恢复原有输入，移除顶部「已恢复上次输入」提示块。

## 验证

- Debug 构建和 diff 空白检查通过。
- 已检查材料页深浅色及滚动状态、设置图标深浅色、单行历史记录和无恢复提示的详情页。
- 材料搜索与分类切换测试通过。
- 新增回归测试验证收藏操作不打开详情、可取消收藏、重开记录保留尺寸且无恢复提示；深浅色均通过。
- 测试记录：`test_sim_2026-09-27T06-25-21-863Z_pid92380_f578404c.xcresult`（材料搜索通过；新测试首次因 100 与 100.0 字符串比较失败，后改为数值比较）。
- 收藏回归测试通过记录：`test_sim_2026-09-27T06-26-12-585Z_pid92380_b1067f0b.xcresult`、`test_sim_2026-09-27T06-27-27-143Z_pid92380_682db371.xcresult`。
- 截图：`output/ui-polish-20260927/`。

## 发布产物

- 归档：`Build/RefinedRelease-20260927/SteelFlow-1.2-18.xcarchive`。
- IPA：`Build/RefinedRelease-20260927/export/SteelFlow.ipa`。
- Release 归档、App Store IPA 导出及归档 codesign 严格验证通过；包内版本确认是 1.2（18）。
- IPA SHA-256：`4801fa52ee36c1e92a3d3bab4a8197675e8d1c6107ff2b990f9e2f2da56e7301`。
- 上传返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`da713424-26d2-483a-9543-cdd3c5ca539a`。
- 传输 10,710,932 字节，用时 1.767 秒。
- 实际连接确认 contentdelivery、App Store Connect API、object-storage 均经过「香港」，记录：`Build/RefinedRelease-20260927/upload-network.json`。
- App Store Connect 已确认营销版本 `1.2`、构建 `18`，`processingState = VALID`、`buildAudienceType = APP_STORE_ELIGIBLE`。
- 本次上传及 Apple 处理已完成，未提交 App Review。

## TestFlight

- 已将构建 18 加入现有「SteelFlow 当前构建」内部测试组，Apple API 返回 204，读取组内构建确认包含 18。
- 操作前实时核对该组测试者仅为用户此前指定邮箱 `xuezaigds@gmail.com`。
- 内部测试状态：`IN_BETA_TESTING`；自动通知：`autoNotifyEnabled = true`。
- 邮件交由 Apple 自动通知机制处理；无邮件投递回执，不声称实际送达。
