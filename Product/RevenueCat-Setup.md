# SteelFlow RevenueCat 配置清单

日期：2026-08-28

代码接入已完成，但仓库不会保存真实 RevenueCat key。以下外部配置完成前，设置页会安全显示“当前构建尚未配置购买服务”，购买按钮不可用。

## 固定标识

| 项目 | 值 |
|---|---|
| Bundle ID | `com.steelflow.app` |
| App Store product | `com.steelflow.app.pro.lifetime` |
| Product type | Non-Consumable |
| RevenueCat entitlement | `pro` |
| RevenueCat offering | `default` |
| Package | Lifetime（RevenueCat 标准 `$rc_lifetime` 或自定义 `lifetime` 均可） |

## Dashboard 与 App Store Connect

1. 在 App Store Connect 创建非消耗型商品，并完成中英文名称、描述和价格。
2. 在 Xcode target 的 Signing & Capabilities 中确认 In-App Purchase capability 可见；XcodeGen 重建工程后也要复核。
3. 在 RevenueCat 创建独立 SteelFlow project，不复用其他 App 的 project 或 public SDK key。
4. 添加 Apple App，填写 Bundle ID；导入上面的商品。
5. 创建 `pro` entitlement 并关联商品。
6. 创建 `default` offering，把商品放入 lifetime package，并设为 Current Offering。
7. 在 RevenueCat Apple 配置中上传 App Store Connect In-App Purchase Key。RevenueCat 5 使用 StoreKit 2，缺少该 key 时真实购买会失败。
8. 确认 App Store Connect 的 Paid Applications agreement、税务和银行信息有效。

## 给构建注入公开 SDK key

不要把真实 key 写入 `project.yml` 或提交 Git。Apple 正式 key 必须是 `appl_` 开头；`test_` key 仅可用于 Debug。

命令行示例：

```bash
xcodegen generate
xcodebuild -project SteelFlow.xcodeproj -scheme SteelFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  REVENUECAT_API_KEY=appl_your_steelflow_public_sdk_key build
```

也可在本机 Xcode 的 target Build Settings 中为 `REVENUECAT_API_KEY` 提供 user-defined value，但不要把含密钥的工程变更提交。public SDK key 可以存在客户端构建中，RevenueCat secret key 不得进入 App 或仓库。

## 实现约束

- SDK 版本精确锁定为 5.85.0。
- 使用 RevenueCat 匿名 App User ID；当前没有登录/退出映射。
- configure 前设置官方中国大陆备用域名 `https://api.rc-backup.com/`。
- Release 构建拒绝 `test_` key。
- 商品价格始终使用 App Store 返回的本地化价格，UI 不硬编码金额。
- 购买取消不报错；Ask to Buy/付款待处理显示等待提示。
- 恢复购买有成功和“未找到有效购买”反馈。
- CustomerInfo 流实时处理退款和撤销；短时离线保留最近一次已验证权益。

## 上线前验收

- 新用户购买并立即解锁。
- 用户取消购买，不弹失败错误。
- Ask to Buy / pending 不误判已购买，批准后自动解锁。
- 删除重装后，用同一 Apple Account 恢复成功。
- 退款或撤销后 Pro 收回。
- 飞行模式重启时，已验证用户仍可使用 Pro。
- 中国大陆网络与海外网络均能加载 offering、购买和恢复。
- Debug Test Store、Apple Sandbox 和 TestFlight 分别走通。
- App Store Connect App Privacy 与双语隐私政策已按 Purchase History 更新。
