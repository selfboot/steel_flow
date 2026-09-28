# SteelFlow 1.3（24）发布构建

## 本轮更新

- 新增正式商务、现代重点、清晰账式三套报价 PDF，共七套样式；支持默认选择、模板、历史快照和备份。
- 优化抬头、明细表及金额排版，汇总区白底清晰；清晰账式的汇总增加留白，仅用单条细线区分总价。
- 移除 PDF 条款说明和感谢文案，页脚仅保留页码。Pro 去品牌规则继续生效。
- 长公司名称、大金额、多语言和续页长编号保持可读。

## 验证

- 25 项报价样式、备份和本地化单元测试通过，见 `Build/BusinessQuoteStyles-20260928/FinalRegression.xcresult`。
- 新增三套默认样式选择、已有项目预览及重启持久化 UI 回归通过，见 `Build/BusinessQuoteStyles-20260928/Regression.xcresult`。
- 最后一次汇总间距调整后 8 项 QuoteStyleTests 全部通过，覆盖八语言、A4/Letter、大金额、分页及品牌规则，见 `Build/LedgerSummary-20260928/Regression.xcresult`。
- 已检查实际 PDF 样例与 App 预览，`git diff --check` 通过。

## 发布状态

- Release archive 和 App Store Connect IPA 导出成功。编译仅有未使用 App Intents 的元数据提取提示。
- 正式签名校验通过，`get-task-allow=false`，应用标识 `4Z5Z5TE9EX.com.steelflow.app`；八种语言齐全。
- IPA 为 1.3（24），10,979,826 字节，SHA-256：`eb8c068330527de28166e0882d8dcf0334ef318f66837389cd0931addad10db6`。
- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0；Delivery UUID：`c46b1030-9cda-4238-a7ce-6541d27f8ea9`。
- API、ContentDelivery 和 object-storage 三段实际连接均经香港节点，见 `upload-network.json`。
- App Store Connect 确认 1.3（24）处理完成，状态 `VALID`、`APP_STORE_ELIGIBLE`；Build ID 同 Delivery UUID，上传时间为北京时间 2026-09-28 18:15:26，API 证据见 `build-after.json`。

产物及日志位于 `Build/BusinessStylesRelease-20260928/`。本次仅上传构建，不提交 App Review。
