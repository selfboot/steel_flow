# SteelFlow 1.1.1（14）设置页优化

本构建已被包含评价功能的 [1.1.1（15）](Release-1.1.1-15-2026-09-27.md) 替代；后续以构建 15 为准，不再上传此包。

- 日期：2026-09-27。
- Bundle ID：`com.steelflow.app`；Team：`4Z5Z5TE9EX`；App ID：`6806282417`。
- 会员卡片置顶，免费版和已解锁状态使用同一布局。
- 统一设置行图标底板、文字起点、分隔线和箭头；Pro 权限改为右侧标识，不再替换功能图标。
- 语言、单位、纸张使用原生选择页面；货币复用现有搜索选择页。
- 精简备份文案和重复说明，将反馈入口合并到关于分组；保留导入/删除确认及历史备份时间。

## 验证

- iPhone 16e / iOS 26.3：中文浅色、中文深色、英文已解锁状态及最大辅助字体均已实际查看。
- 顶部会员入口可打开购买页面。
- 现有 UI 回归 3/3 通过：主导航、货币搜索选择后返回、反馈入口及邮件不可用回退。
- 最终 Release 归档和 App Store 导出成功；codesign 严格验证通过。
- 正式包版本 1.1.1，构建 14；`ITSAppUsesNonExemptEncryption = false`。
- 本次没有实际购买测试；iPad 未进行本轮视觉验证。

## 产物

- 归档：`Build/SettingsRelease-20260927/SteelFlow-1.1.1-14.xcarchive`
- IPA：`Build/SettingsRelease-20260927/export/SteelFlow.ipa`
- SHA-256：`b8d1fd626ff53360057c76610eae0bf46e409c911a10a2432aae0197bc6f1c13`
- 截图：`Build/SettingsRelease-20260927/QA/`
- 构建记录：`archive-final.log`、`export.log`，位于同一发布目录。
- UI 测试结果：`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T00-15-04-812Z_pid31583_dd87d5a8.xcresult`

## 上传状态

上传未完成。App Store Connect API 多次返回连接重置，直连超时，本机代理控制接口需要鉴权，先前关于未加载节点的判断不成立。Xcode 内置 ContentDelivery altool 读取 IPA 后等待网络数分钟，无上传接收回执；已停止挂起进程，未留下后台上传。网络恢复后可直接重试现有 IPA，先核对后台最新构建号。未提交 App Review。
