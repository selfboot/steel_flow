# SteelFlow / 钢流

> Working title only; trademark and App Store name availability have not been cleared.

SteelFlow 是一款面向金属加工、钢材贸易、采购报价和专业 DIY 用户的原生 iPhone / iPad 工具。它把型材尺寸转换成可核对的重量、成本和项目报价，核心功能完全离线。

## 运行 App

环境要求：Xcode 16+、iOS 17+、XcodeGen。

```bash
cd SteelFlow
xcodegen generate
open SteelFlow.xcodeproj
```

命令行测试：

```bash
xcodebuild -project SteelFlow.xcodeproj -scheme SteelFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath Build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

RevenueCat 使用 StoreKit 2 管理一次性 Pro。商品 ID 为 `com.steelflow.app.pro.lifetime`，entitlement 为 `pro`。运行购买流程前需按 [RevenueCat 配置指南](./Product/RevenueCat-Setup.md)提供本 App 专属的公开 SDK key；仓库不保存真实密钥。

## 工程目录

- `App/`：SwiftUI、SwiftData、计算引擎、PDF/CSV、备份、RevenueCat/StoreKit 与双语资源。
- `Tests/`：公式、单位、金额、项目、PDF/CSV 和备份测试。
- `UITests/`：核心计算与四个主导航的 UI 验收。
- `project.yml`：XcodeGen 工程定义；`SteelFlow.xcodeproj` 可随时重新生成。
- `Product/PRD.md`：需求、用户、范围、验收标准、国际化和商业模式。
- `Product/Technical-Spec.md`：架构、数据模型、公式、持久化、导出、购买、测试和合规边界。
- `Product/Design-Spec.md`：信息架构、视觉语言、交互规范、响应式与中英文文案。
- `Product/Implementation-Status.md`：逐项功能映射、测试证据与上架前外部配置。
- `Product/Design/SteelFlow-Prototype.html`：可交互高保真设计稿。

## 已实现

- 11 类型材、7 种内置材料、自定义密度与可追溯计算详情。
- 公制/美制切换，内部统一使用 SI 真值；金额使用 `Decimal`。
- SwiftData 项目持久化、复制、归档、排序、逐项及批量计价。
- 中英文 App 与独立报价语言，A4/Letter PDF、UTF-8 BOM CSV。
- 用户录入供应商价、离线历史参考价格库、价格来源/地区/牌号/日期追溯；不把期货行情当作采购价，也不会自动联网改价。
- 改币种时显式选择保留数字、按手工汇率换算或清空金额；每次导出保存不可变报价快照。
- 带 schema 版本和 SHA-256 校验的完整备份，导入前预览并复制导入。
- RevenueCat + StoreKit 2 一次性 Pro、购买恢复、权益撤销监听和离线权益缓存。
- 无广告、无账号、无自有业务后端；项目和报价内容保持本地。购买历史由 RevenueCat 以匿名 App User ID 处理，隐私清单已按“未关联用户、不用于跟踪”披露。

## 产品文档

- [Product requirements](./Product/PRD.md)
- [Technical specification](./Product/Technical-Spec.md)
- [Design specification](./Product/Design-Spec.md)
- [Implementation status](./Product/Implementation-Status.md)
- [RevenueCat setup](./Product/RevenueCat-Setup.md)
- [Competitor pricing research](./Product/AppStore/Pricing-Research-2026-08-28.md)
- [Interactive design prototype](./Product/Design/SteelFlow-Prototype.html)

产品承诺：从尺寸到重量、成本和报价单，一次完成，结果可核对。
