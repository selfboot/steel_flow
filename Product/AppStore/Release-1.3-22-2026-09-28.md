# SteelFlow 1.3（22）发布构建

## 本轮功能

- 报价 PDF 支持经典、清爽蓝、商务墨绿、极简黑白四种样式；项目、模板、备份和历史快照保留各自样式。
- 设置 → 报价设置增加默认报价样式，并集中放置 A4 / Letter 纸张尺寸。项目列表和计算器两个新建入口继承默认值；已有项目及模板保留原设置。
- 八种语言文案齐全，Pro 去除 SteelFlow 品牌标识规则适用于全部样式。

功能和视觉验证详见 [报价样式记录](../Quote-Styles-2026-09-28.md)。

## 验证和构建

- 样式完整回归：107 项单元测试 + 3 项 UI 测试通过，`Build/QuoteStyles/FinalRegression.xcresult`。
- 默认设置：17 项备份与本地化单元测试通过；初次 UI 测试因系统选择器返回控件定位失败，修正测试定位后，完整创建与重启流程在 `DefaultSettingsComplete.xcresult` 通过。
- 已检查浅色、深色、大字号、多语言和分页 PDF。
- 本轮 Release archive 与 App Store Connect IPA 导出成功。编译只有未使用 App Intents 时的元数据提取提示。
- 正式分发签名系统校验通过，`get-task-allow=false`，应用标识 `4Z5Z5TE9EX.com.steelflow.app`。
- IPA 版本：1.3（22），八种语言齐全，10,960,662 字节。
- SHA-256：`8e8201e483d2ba5e59d0012ff4d528fb168d0e1b1587f01fda83d0035f313f28`。
- 导出时临时加入现有发布钥匙串，完成后已恢复原搜索列表。

本轮发布产物与日志：`Build/QuoteStylesRelease-20260928/`。

## 上传状态

- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`7ea75d16-13b8-4693-b7bd-b76a0426ef81`。
- App Store Connect API、ContentDelivery 和 object-storage 三段实际连接均经香港节点，见 `upload-network.json`。
- App Store Connect 已确认 1.3（22）处理完成：`VALID`、`APP_STORE_ELIGIBLE`。Build ID 同 Delivery UUID，上传时间为北京时间 2026-09-28 16:50:25，证据见 `build-after.json`。

本次只上传构建，未提交 App Review。
