# SteelFlow 1.3（25）发布构建

## 本轮更新

- 移除项目设置中不会应用到预览的独立样式入口。新预览继续使用设置中的默认样式，预览内切换只影响本次报价，不再改写项目样式或修改时间。
- 移除项目条款、公司默认条款及相关 Pro 解锁入口。八种语言的 Pro 权益、模板及样式说明同步更新。
- 保留历史条款、公司默认条款和项目样式字段，以及快照、模板、备份兼容逻辑；编辑其他信息不会覆盖隐藏旧数据。
- 包含构建 24 的七套报价样式、汇总留白和 PDF 排版优化。

## 验证

- 112 项单元测试与 3 项 UI 测试全部通过，无编译警告，见 `Build/ReviewFix24-20260928/Regression.xcresult`。
- UI 覆盖免费/Pro 条款入口清理、公司 Logo 入口、默认设置与两个创建流程、重启持久化、预览切换及保存版本重置；已检查项目、公司和深色设置截图。
- Release archive 与 IPA 导出成功；仅有未使用 App Intents 的元数据提取提示。
- 正式签名验证通过，`get-task-allow=false`，应用标识 `4Z5Z5TE9EX.com.steelflow.app`。
- IPA：1.3（25），10,963,834 字节，八种语言齐全。
- SHA-256：`4e3290ed6acdfed07dc8e0a67ce87f425e23c70cd072f890af45617740e0a8f7`。
- 导出时临时加入发布钥匙串，完成后恢复原搜索列表。

## 上传状态

- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- Delivery UUID：`2f0623f6-f10f-4efa-8530-335c5d20cb0a`。
- API、ContentDelivery 和 object-storage 三段实际连接均经香港节点，见 `upload-network.json`。
- App Store Connect 确认 1.3（25）处理完成，状态 `VALID`、`APP_STORE_ELIGIBLE`。Build ID 同 Delivery UUID，上传时间为北京时间 2026-09-28 18:45:27，API 证据见 `build-after.json`。

产物、验证结果和源码清单位于 `Build/ReviewFixRelease-20260928/`。本次仅上传构建，未提交 App Review。

## 子功能提交

- `d4b7118`：七套 PDF 样式、样式快照与备份、设计示例及渲染回归。
- `0211cc7`：清理条款编辑入口和 Pro 权益承诺，保留历史数据。
- `fdf2edc`：默认报价设置、本次预览样式与相关 UI 流程。
- `b7a8299`：移除项目明细编辑页重复取消按钮。
- 发布配置与本记录另作独立提交。

分组提交后，130 个源码与工程文件的 SHA-256 与本次构建清单一致。本轮没有推送远程；已有 ASO 调研及推广素材保留在工作区。
