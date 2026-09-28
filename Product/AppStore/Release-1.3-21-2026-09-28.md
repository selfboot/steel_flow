# SteelFlow 1.3（21）发布构建

本次版本包含繁体中文、日语、韩语、德语、西班牙语和法语；连同英文、简体中文共支持八种语言。此前本地实现和回归记录见 [1.3 初始记录](Release-1.3-21-2026-09-27.md) 与 [欧洲语言审查](../Localization-Review-2026-09-28.md)。

## 本轮修复

项目已有明细通过导航栈进入编辑页，原先同时显示系统返回和“取消”，挤压德语、西班牙语型材标题。移除重复的“取消”，保留系统返回、“完成”和底部保存。返回仍放弃未保存的表单草稿。

UI 回归增加导航断言，要求没有重复“取消”，同时保留返回和“完成”。等待编辑页出现并滚动到单价后检查，避免在导航过渡动画中读取上一页按钮。

## 构建与验证

- 102 项单元测试通过，结果：`Build/LocalizationRelease-20260928/ReleaseRegression.xcresult`。
- 德语、西班牙语、法语 3 项编辑与导航 UI 回归全部通过，结果：`Build/LocalizationRelease-20260928/NavigationRegression.xcresult`。每种语言验证三轮保存及历史价格选择。
- 已人工检查三种语言的实际导航截图，型材标题完整，无重复取消按钮，返回和完成均保留。截图位于 `Build/LocalizationRelease-20260928/NavigationQA/`。
- Release archive 与 App Store Connect IPA 导出成功。
- 发布包版本为 1.3（21），八种语言资源齐全。
- 正式分发签名通过系统校验，`get-task-allow=false`，应用标识为 `4Z5Z5TE9EX.com.steelflow.app`。
- IPA：`Build/LocalizationRelease-20260928/export/SteelFlow.ipa`，10,863,718 字节。
- SHA-256：`8779b517ddf20d97444545d683bf6821048c354506d99a4dcc88e77d43546e9d`。

发布构建产物与日志保存在 `Build/LocalizationRelease-20260928/`。导出时临时加入独立签名钥匙串，完成后已恢复原钥匙串搜索列表。编译仅出现未使用 App Intents 时的元数据提取提示。

## 苹果上传

- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`bb1abed8-b975-4154-9a58-f26d7ea3b0d1`。
- App Store Connect 已确认 iOS 1.3（21）处理完成，状态 `VALID`、`APP_STORE_ELIGIBLE`；Build ID 为 `bb1abed8-b975-4154-9a58-f26d7ea3b0d1`，上传时间为北京时间 2026-09-28 15:54:26。API 证据：`build-after.json`。
- 已核实 App Store Connect API、ContentDelivery 和 object-storage 三段连接均经过 Clash 香港节点；证据：`upload-network.json`。
- 本次仅上传构建，未修改商店资料、未提交 App Review。
