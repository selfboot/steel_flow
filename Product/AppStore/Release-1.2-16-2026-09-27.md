# SteelFlow 1.2（16）设置与付费页优化

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- 在构建 15 基础上，设置图标改为深钢蓝灰底与白色符号，呼应 App 图标金属色系。
- Pro 入口与付费页统一深蓝灰主题，权益拆分为四组标题和说明。
- 明确展示永久使用权、一次性购买、无订阅与商店返回的本地化价格。
- 常规字号下购买区固定在底部；大辅助字体和低高度窗口下整体滚动。
- 增加价格获取失败的重试入口，保留恢复购买及原有解锁流程。

## 验证

- Debug 构建通过；中英文字符串格式及 diff 空白检查通过。
- 现有两项 UI 测试通过：受限功能打开购买页并加载商品、发起 StoreKit 支付后取消并正常返回。
- iPhone 16e / iOS 26.3 实际检查：中文设置与付费页浅色/深色、英文付费页、最大辅助字体的入口和可滚动购买区。
- 截图：`output/ui-review-20260927/`。
- 测试结果：`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T05-25-20-971Z_pid92380_b82ee5b3.xcresult`。
- 本轮没有 iPad 视觉验证；加载/错误状态仅代码检查；未进行实际扣款。

## 发布产物

- 归档：`Build/PaywallRelease-20260927/SteelFlow-1.2-16.xcarchive`。
- IPA：`Build/PaywallRelease-20260927/export/SteelFlow.ipa`。
- 构建、导出和上传记录位于 `Build/PaywallRelease-20260927/`。
- Release 归档、App Store IPA 导出及归档 codesign 严格验证通过；IPA 内核对版本为 1.2（16）。
- IPA SHA-256：`3280f6a25287d86aec7343af7852d2d9f44fa229635ebfb3d7e39fc2d9ec7c30`。
- 上传返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`545465b8-f37d-476b-a424-9bd95fce455e`。
- 传输 10,541,038 字节，用时 1.503 秒，约 7.0 MB/s。
- 上传回执：`Build/PaywallRelease-20260927/upload.log`。
- App Store Connect API 已确认：营销版本 `1.2`、构建 `16`，`processingState = VALID`、`buildAudienceType = APP_STORE_ELIGIBLE`、`usesNonExemptEncryption = false`。结果保存在 `Build/PaywallRelease-20260927/builds-after.json`。
- 本次仅上传构建，未提交 App Review。

## TestFlight

- 用户要求发送邮件后，将构建 16 加入现有「SteelFlow 当前构建」内部测试组，API 返回 204。
- 已核对 App 全部测试者仅为用户指定邮箱，无其他收件人；后台显示该测试者已安装 1.2（16）。
- 内部测试状态为 `IN_BETA_TESTING`，自动通知已开启。
- 单独补发邀请被 Apple 拒绝：`STATE_ERROR.TESTER_INVITE.ALREADY_ACCEPTED`。
- 手动新构建通知被 Apple 拒绝：`Build is not in externally testable state.`；已恢复原来的 `autoNotifyEnabled = true`。
- 未声称邮件实际送达；未为了发邮件创建外部测试组或提交 Beta App Review。
- 此后用户要求的去纸张纯色图标已更新在工作区；不包含在已上传的构建 16 中。
