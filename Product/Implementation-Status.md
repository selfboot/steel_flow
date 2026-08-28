# SteelFlow v1 实现与验收状态

日期：2026-08-28
目标：iOS / iPadOS 17+ 原生 App

## 功能需求映射

| PRD | 状态 | 实现证据 |
|---|---|---|
| FR-001 型材选择 | 完成 | `CalculatorHomeView` 展示 11 类型材、自适应网格、图形和无障碍名称。 |
| FR-002 单位输入 | 完成 | `Units.swift` 与 `CalculatorDraft` 保持 SI 真值并执行无损切换；公英制等价测试通过。 |
| FR-003 确定性计算 | 完成 | `CalculationEngine` 覆盖 11 种截面及无效几何；100 条版本化参考语料全量回归。 |
| FR-004 计算依据 | 完成 | 结果详情展示公式、SI 输入、密度、面积、长度、数量与引擎版本。 |
| FR-005 价格与利润 | 完成 | 按币种舍入的 `Decimal` 金额、kg/lb/m/ft/piece 一致损耗、行固定费用、Markup/Margin、税、手工价与可追溯历史参考价。 |
| FR-006 项目管理 | 完成 | SwiftData 持久化，创建、复制、排序、归档、恢复和删除条目。归档代替不可恢复删除；条目、材料和价格删除均需二次确认。 |
| FR-007 PDF 报价 | 完成 | 中英文、A4/Letter、多页重复表头、末页总计安全区、公司/客户/有效期/条款、不可变报价快照和系统分享。 |
| FR-008 CSV | 完成 | 固定机器字段、UTF-8 BOM、面积/体积/损耗/价格来源/费用及项目汇总、独立数字/单位/币种列和系统分享。 |
| FR-009 本地化 | 完成 | 简体中文/English，界面语言和报价语言分离；关键动态键自动化测试。 |
| FR-010 数据可移植性 | 完成 | schema v1、SHA-256 校验、导入前数量预览、复制导入、不覆盖现有项目和公司资料；语义校验全部通过后才执行原子提交。 |
| FR-011 购买 | 代码完成，待外部配置 | RevenueCat + StoreKit 2 非消耗型购买、恢复、匿名权益验证、CustomerInfo 更新监听和离线缓存；退款或撤销会收回 Pro，免费限制不阻断基础计算。待填入本 App 的公开 SDK key 并完成 Dashboard/App Store Connect 联调。 |

## 质量门槛

- Debug：51 项测试通过，覆盖领域计算、100 条参考语料、所有计价单位损耗、币种舍入与迁移、Markup/Margin、非法价格、价格历史、备份原子性、数据库启动恢复、RevenueCat key 发布保护、Pro 权益撤销、PDF 分页、CSV 汇总、报价快照、本地化，以及核心导航、最大辅助字号、中文小屏报价和安全删除 UI 流程。
- Release：RevenueCat 5.85.0 集成后的 iOS Simulator arm64/x86_64 无签名构建通过；正式购买仍需 App 专属 key 与 Sandbox/TestFlight 联调。
- 运行时：iPhone 16 Pro / iOS 18.2 中文界面启动通过；iPad Pro 11-inch / iOS 18.2 英文界面启动通过。
- 视觉：iPhone SE 标准字号/AX5 最大辅助字号、深色模式、横屏、中文报价及 iPad 四列自适应布局均完成截图检查。
- 隐私：无广告、账号或自有业务后端；项目、客户和报价内容不上传。`PrivacyInfo.xcprivacy` 披露 RevenueCat 处理购买历史用于 App 功能和分析，未关联身份且不用于跟踪。

## 上架前外部配置

以下项目依赖开发者账号、法务或真实行业人员，不属于代码缺失：

1. 确定正式名称并完成商标/App Store 名称检索。
2. 在 App Store Connect 创建 `com.steelflow.app.pro.lifetime` 非消耗型商品并配置地区价格。
3. 按 `Product/RevenueCat-Setup.md` 创建 RevenueCat 项目、`pro` entitlement 和 `default` offering，上传 Apple In-App Purchase Key，并把本 App 专属公开 SDK key 注入构建。
4. 用 Sandbox/TestFlight 验证首购、取消、Ask to Buy、恢复、退款/撤销、离线启动和中国大陆网络。
5. 用至少 30 条真实行业案例复核当前标注为 `pending-industry-review` 的参考语料。
6. 确认 `docs.puzzles-game.com` 上的双语隐私政策、支持和产品页面完成部署。
7. 按最终联网功能和 App Store Connect 提示确认中国大陆 APP 备案适用性。
