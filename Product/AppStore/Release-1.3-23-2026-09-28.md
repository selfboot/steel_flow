# SteelFlow 1.3（23）发布构建

## 本轮修复

每次打开新的报价预览都使用设置页当前选定的默认 PDF 样式，已有项目也生效。预览内可手动切换，同一次预览重试或购买 Pro 后重新生成会保留当前样式。历史报价使用原快照，不受默认值变更影响；纸张尺寸仍采用项目设置。八种语言设置说明已同步更新。

## 验证

- 12 项报价样式与本地化单元测试通过，包含样式覆盖不改写项目或已保存快照、多语言、纸张、分页及去品牌验证。
- 预览默认样式和版本保存 UI 回归通过。结果见 `Build/QuoteStyles/PreviewDefaultsRegression.xcresult`。
- 完整默认设置 UI 流程首次因系统纸张选择器自动返回而中止；适配测试操作后重跑通过，见 `Build/QuoteStyles/PreviewDefaultsUI.xcresult`。覆盖设置换样式、已有项目预览、新建项目两个入口及重启后持久化。

## 发布状态

- Release archive 和 App Store Connect IPA 导出成功，编译只有未使用 App Intents 时的元数据提取提示。
- 正式签名校验通过，`get-task-allow=false`，应用标识 `4Z5Z5TE9EX.com.steelflow.app`。
- IPA 为 1.3（23），八种语言齐全，10,961,255 字节。
- SHA-256：`ee13511c2b2be56d44d08d5644df9d08066c1d48e46060bc6bd262fdd5250ff4`。
- 导出时临时加入发布钥匙串，完成后已恢复原搜索列表。
- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`fa01f139-7591-43d6-873c-e35174c1e15c`。
- App Store Connect API、ContentDelivery 和 object-storage 三段实际连接均经香港节点，见 `upload-network.json`。
- App Store Connect 确认 1.3（23）处理完成，状态 `VALID`、`APP_STORE_ELIGIBLE`。Build ID 同 Delivery UUID，上传时间为北京时间 2026-09-28 17:12:09，API 证据见 `build-after.json`。

产物及日志位于 `Build/PreviewDefaultsRelease-20260928/`。本次仅上传构建，未提交 App Review。
