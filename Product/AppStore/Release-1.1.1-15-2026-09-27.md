# SteelFlow 1.1.1（15）设置与评价更新

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- 包含构建 14 的设置页优化：会员置顶、统一图标和对齐、精简文案。
- 「关于」首项增加「评价 App」，打开 `https://apps.apple.com/app/id6806282417?action=write-review`。
- 用户修改输入并完成有效计算后，待键盘和其他弹窗关闭、结果稳定 2 秒，调用系统 StoreKit 评分弹窗。初次打开默认结果不触发，继续编辑或离开页面取消等待。
- 每个营销版本最多请求一次，跨版本至少间隔 90 天；记录的是请求，不代表用户已评分。实际是否展示由系统决定。

## 验证

- 新增 4 项单元测试通过：请求记录持久化、版本限制和 90 天间隔、缺失版本处理、评价链接目标。
- 3 项 UI 测试通过：主导航及默认计算、长度输入、主要页面本地化。合计 7 项通过、0 失败。
- iPhone 16e / iOS 26.3 实测：修改钢板宽度、收起键盘后显示原生五星评分弹窗；点击「以后」关闭，没有提交评价。
- 新评价入口的中文浅色、深色布局检查通过；前一轮设置 UI 的英文、已解锁状态及大字体证据见构建 14 记录。
- 正式 Release 归档和 App Store 导出成功，签名严格校验通过。
- 本轮没有实际购买测试或 iPad 视觉验证。

## 产物

- 归档：`Build/ReviewRelease-20260927/SteelFlow-1.1.1-15.xcarchive`
- IPA：`Build/ReviewRelease-20260927/export/SteelFlow.ipa`
- SHA-256：`9f469566e179f0f69c016dd403a151efcf7e0a8cdc0b38afac4480884a893097`
- 截图：`Build/ReviewRelease-20260927/QA/`（设置评价入口浅色、深色及系统评分弹窗）。
- 测试结果：`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T00-44-26-020Z_pid31583_0c479e16.xcresult`
- 构建日志：同一发布目录内的 `archive.log`、`export.log`。

## 上传

通过 Clash「香港」节点上传，App Store Connect、ContentDelivery 和苹果对象存储三段链路均已核实。第一轮传输遇到存储域名仍走直连，补齐路由并终止失败重试后重新开始。

- 2026-09-27 08:52:59（北京时间）：`UPLOAD SUCCEEDED with no errors`，进程退出码 0。
- Delivery UUID：`aa7b7845-8d82-480a-b3fa-8dc0b2d6365c`。
- 传输 10,573,321 字节，用时 1.386 秒，约 7.6 MB/s。
- 上传回执：`Build/ReviewRelease-20260927/upload-hongkong.log`。
- App Store Connect API 已确认构建 15：`processingState = VALID`，`buildAudienceType = APP_STORE_ELIGIBLE`，`usesNonExemptEncryption = false`。处理结果保存为 `Build/ReviewRelease-20260927/builds-after.json`。
- 上传及苹果后台处理均完成；未提交 App Review。
