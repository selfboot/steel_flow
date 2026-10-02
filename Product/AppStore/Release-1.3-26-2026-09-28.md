# SteelFlow 1.3（26）语言一致性修复

## 修改

- App 语言设置成为界面和报价导出的统一语言来源。旧项目创建时保存的报价语言不再覆盖当前设置。
- 新建项目、项目设置移除独立报价语言选择器；保留历史字段和备份兼容性。
- 新报价、历史版本重新导出、内置材料名称、报价汇总及样式缩略图跟随当前语言。
- 历史报价仅对展示副本本地化；原始快照、价格、日期、币种、样式和客户填写内容均不改写。
- 语言变化时重新生成预览；从全屏 PDF 返回保留已保存版本状态。
- 八种语言的历史报价说明及本地 ASO 描述同步修正。

## 验证

- 全部 115 项单元测试通过；新增覆盖 8 种语言 × 7 套 PDF 样式、旧中文项目、历史版本、CSV 材料名称、系统语言及自定义文本保留。
- 连续切换 8 种语言的新报价与历史报价 UI 测试通过，计算草稿保持测试通过。首次日语专项因旧页面标题断言失败，已修正测试并复测。
- 最终回归 118/118 通过（115 项单元测试 + 日语系统语言、样式/全屏 PDF 返回、英文界面人民币报价 3 项 UI 测试）。加上此前通过的连续 8 语言切换和草稿保持测试，相关 UI 共 5 项通过。结果见 `Build/LanguageFixRelease-20260928/FinalRegression.xcresult`。
- 语言切换测试及截图：`LanguageUI.xcresult`、`UIAttachments/`。已目视核对日语和德语预览。
- Release 归档、IPA 导出及严格签名验证通过。八种语言资源齐全，`get-task-allow=false`。
- IPA：1.3（26），10,964,214 字节。
- SHA-256：`007fff1283ce811140eeb21ec96f0d8e5e2852b4da6310b1f4c8dd66d118e763`。
- 归档内八种语言的历史报价说明与当前源码逐项一致。源码清单位于 `source-manifest.json`。

## 上传

- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`2a2ef811-37be-4704-9483-1ca08d29faee`。
- App Store Connect 已确认版本 1.3、构建 26，状态 `VALID`、`APP_STORE_ELIGIBLE`；上传时间为北京时间 2026-09-28 21:11:57。
- API、ContentDelivery 和 object-storage 上传连接均经香港节点，见 `upload-network.json`。
- 已于北京时间 2026-09-28 21:48:13 提交 App Review，审核单和版本均为 `WAITING_FOR_REVIEW`，审核通过后自动发布。详见 Review-1.3-26-2026-09-28.md。

所有构建、签名和上传证据保存在 `Build/LanguageFixRelease-20260928/`。
