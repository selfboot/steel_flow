# SteelFlow 1.1.0（构建 10）发布记录

应用：`com.steelflow.app`；App Store Connect：`6806282417`；团队：`4Z5Z5TE9EX`。

## 改动

- 纳入 [U01–U14 体验修复](../UI-Experience-Fixes-2026-09-08.md)：错误定位、模板预览、筛选空态、批量修改与撤销、收藏复用、保存反馈、PDF 预览与版本分享、版本比较、材料导航及 iPad 分栏。
- 移除计算页顶部“展开完整报价设置”开关，将计价改为默认收起的分组；点击展开，收起显示金额摘要。
- 展开状态只属于当前页面；再次进入默认收起。金额、费用、来源和备注保留，错误定位可展开对应计价字段。
- 版本保持 1.1.0，构建号从 9 增加到 10。

## 验证

- 前一轮：86 项业务测试、13 个手机 UI 场景及 3 个 iPad 场景经回归与针对性复测通过，详见修复记录中的结果包说明。
- 本轮 iPhone SE：`Build/UIRelease-20260908/PricingGate.xcresult` 通过，覆盖移除顶部开关、展开计价、修改单价、收起后重新展开保留金额、重新进入默认收起。
- 本轮 iPad：`Build/UIRelease-20260908/iPadCleanRunner.xcresult` 通过，覆盖展开/收起保留金额，以及结束 App 进程后重新启动、恢复草稿默认收起、再次展开金额仍为 12.5。
- iPad 初次测试因旧测试运行器继续执行旧导航动作而失败；移除本应用测试运行器并重新安装后，日志确认执行了最新的终止/启动步骤，最终用例通过。早期失败或中断的结果包未计为通过。
- 已目视检查计价展开和折叠截图；收起时显示总金额，保存入口保持可用。
- `git diff --check`、项目配置和中英文本地化语法校验通过。
- Review：折叠仅改变展示，不清空报价字段；未改变金额计算、持久数据结构或 Pro 权限规则。移除了会覆盖子输入框辅助标识的外层标识。

## 发布产物

- 源码提交：`175afad`，已推送到 `origin/main`。
- 签名归档成功：`Build/UIRelease-20260908/SteelFlow-1.1.0-10.xcarchive`；日志 `archive-signed.log`。
- App Store 导出成功：`Build/UIRelease-20260908/export/SteelFlow.ipa`，8,011,378 字节。
- IPA SHA-256：`521ff8fd8fccb1711db66c720bad5c12ac7b1af1815bffa066637d915ba720e3`。
- 严格签名校验通过，团队为 `4Z5Z5TE9EX`，应用为 `com.steelflow.app`，版本 `1.1.0` / `10`，`get-task-allow=false`；Release 不含工作流测试或模拟导出失败开关。
- 初次归档签名因钥匙串选择失败；解锁现有组织钥匙串并临时加入搜索路径后，自动签名与分发导出成功，随后恢复搜索路径。
- 苹果服务端校验通过：`VERIFY SUCCEEDED with no errors`。
- 2026-09-08 19:34（Asia/Shanghai）上传成功：`UPLOAD SUCCEEDED with no errors`。
- Delivery UUID：`76bc0311-a6f1-4d88-affe-45929075b749`。
- 苹果后台处理完成：`VALID` / `APP_STORE_ELIGIBLE`，关联版本 `1.1.0`、构建 `10`，无需补充出口合规信息。未提交 App Review。
- [App Store Connect / TestFlight](https://appstoreconnect.apple.com/apps/6806282417/testflight)。

## 界面截图

- [iPhone 计价收起](../UI-Verification-2026-09-08/pricing-collapsed.png)
- [iPad 计价收起](../UI-Verification-2026-09-08/ipad-pricing-collapsed.png)
- [iPad 计价展开](../UI-Verification-2026-09-08/ipad-chinese-pricing.png)
