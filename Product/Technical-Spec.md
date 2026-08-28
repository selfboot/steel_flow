# SteelFlow 技术实现方案 / Technical Specification

| 字段 | 内容 |
|---|---|
| 版本 | 0.1 |
| 日期 | 2026-08-28 |
| 目标系统 | iOS/iPadOS 17+ |
| UI | SwiftUI |
| 持久化 | SwiftData |
| 商业化 | RevenueCat + StoreKit 2，一次买断 |
| 后端 | v1 无 |

## 1. 技术目标

1. 核心计算完全确定性、可测试、可解释，不依赖网络或生成式 AI。
2. 中文和英文从数据模型、格式化、PDF 到测试均为一等能力。
3. 本地优先，无账号；用户可备份、恢复和导出全部业务数据。
4. 计算引擎、目录数据、金额计算和 UI 解耦，便于独立验证与未来扩展。
5. v1 保持普通工具类 App 边界，不引入实时行情、云协作和高运营成本。

## 2. 技术栈与依赖策略

### Apple 框架

- Swift 6 language mode where practical.
- SwiftUI：界面和跨 iPhone/iPad 布局。
- SwiftData：项目、条目、材料、客户和设置。
- RevenueCat iOS SDK 5.85.0：商品方案、购买恢复和 `pro` entitlement。
- StoreKit 2：RevenueCat 5 默认使用的 Apple 支付底层。
- Core Graphics + PDFKit：PDF 生成和预览。
- UniformTypeIdentifiers：CSV、JSON 备份和文档分享。
- Foundation `Measurement`、`FormatStyle`、`Locale`、`Decimal`。
- OSLog：不含业务内容的本地诊断日志。
- App Intents：延后到 v1.1，仅在核心模型稳定后加入。

### 第三方依赖

v1 仅有 RevenueCat 一个第三方运行时依赖，且只参与购买和权益管理。公式、PDF、CSV、项目数据和客户数据均不经过 RevenueCat。SDK 使用 Swift Package Manager 精确锁定版本，并随 App 的隐私清单和 SBOM 记录。

如确需引入依赖，必须满足：

- 明确许可证和版本锁定。
- 无隐藏网络请求或分析 SDK。
- 可替换、可单元测试、不参与核心数值真值。
- 在隐私清单和 SBOM 中记录。

## 3. 总体架构

采用 feature-oriented modular architecture：

```text
SteelFlowApp
├── AppShell
│   ├── Navigation
│   ├── DependencyContainer
│   └── AppSettings
├── Features
│   ├── Calculator
│   ├── Projects
│   ├── Materials
│   ├── Quotes
│   ├── Export
│   ├── Purchase
│   └── Settings
├── Domain
│   ├── Models
│   ├── Units
│   ├── Money
│   ├── Validation
│   └── CalculationEngine
├── Data
│   ├── SwiftDataStore
│   ├── CatalogRepository
│   ├── BackupCodec
│   └── Migrations
├── Presentation
│   ├── DesignSystem
│   ├── Components
│   └── Formatters
└── Resources
    ├── Localizable.xcstrings
    ├── MaterialCatalog.json
    └── QuoteTemplates
```

### 依赖方向

`Features -> Domain <- Data`

- `Domain` 不依赖 SwiftUI、SwiftData 或 StoreKit。
- 计算引擎接收不可变输入值并返回结果或结构化错误。
- Feature view model 负责编辑状态和调用 use case，不包含公式。
- Data 层通过 protocol 注入，预览和测试使用内存实现。

## 4. 核心领域模型

### 4.1 ProfileKind

```swift
enum ProfileKind: String, Codable, CaseIterable {
    case plate
    case roundBar
    case squareBar
    case hexBar
    case roundTube
    case squareTube
    case rectangularTube
    case angle
    case channel
    case iSection
    case customArea
}
```

名称、图标和字段标签由 `ProfileDescriptor` 提供，不把本地化文本存进 enum。

### 4.2 DimensionInput

```swift
struct DimensionInput: Codable, Hashable {
    let field: DimensionField
    let value: Double
    let unit: LengthUnit
}
```

保存用户原始数值与单位；计算前统一转换为米。禁止只保存格式化字符串。

### 4.3 MaterialDefinition

| 字段 | 类型 | 说明 |
|---|---|---|
| id | UUID/String | 内置使用稳定字符串，自定义使用 UUID |
| nameKey | String? | 内置材料的本地化键 |
| customName | String? | 用户自定义名称 |
| densityKgPerM3 | Double | 标准化密度 |
| source | CatalogSource | 来源、版本、许可和说明 |
| isBuiltIn | Bool | 是否随包提供 |
| updatedAt | Date | 自定义材料修改时间 |

### 4.4 CalculationItem

| 字段 | 类型 |
|---|---|
| id | UUID |
| profileKind | ProfileKind |
| dimensions | [DimensionInput] |
| materialID | Material ID |
| densityOverride | Double? |
| length | QuantityValue |
| quantity | Int |
| priceBasis | PriceBasis |
| unitPrice | Money? |
| wastePercent | Decimal |
| processingFee | Money? |
| description | String |
| internalNote | String |
| sortIndex | Int |
| calculationVersion | Int |
| createdAt/updatedAt | Date |

不持久化派生总重量和总价作为真值；显示时由当前版本引擎重新计算。导出快照需要把结果与引擎版本一并冻结。

### 4.5 Project

```text
Project
├── identity: id, name, projectNumber, status
├── customer: optional Customer reference
├── locale: quoteLanguage, unitSystem, currencyCode, paperSize
├── pricing: tax label/rate, default waste, margin, validity
├── presentation: company profile, visible columns, terms
├── items: ordered CalculationItem list
└── audit: createdAt, updatedAt, exportedAt
```

### 4.6 Money

```swift
struct Money: Codable, Hashable {
    let amount: Decimal
    let currencyCode: String
}
```

- 禁止用 `Double` 表示金额。
- 不允许不同币种直接相加。
- 小数位和显示由 ISO 4217/Locale formatter 决定。
- 税、利润和舍入顺序在项目中显式保存。

## 5. 计算引擎

### 5.1 统一计算链

```text
Raw user input
  -> field parsing and unit normalization
  -> geometry validation
  -> cross-sectional area (m²)
  -> volume = area × length × quantity (m³)
  -> net mass = volume × density (kg)
  -> waste-adjusted mass
  -> material and processing cost
  -> tax and margin policy
  -> display result and calculation trace
```

### 5.2 公式

所有尺寸先转换为米：

| 型材 | 截面积公式 |
|---|---|
| Plate / flat bar | `width × thickness` |
| Round bar | `π × diameter² / 4` |
| Square bar | `side²` |
| Hex bar, across flats F | `√3 × F² / 2` |
| Round tube | `π × (OD² - ID²) / 4`, `ID = OD - 2t` |
| Square tube | `outer² - inner²`, `inner = outer - 2t` |
| Rectangular tube | `W×H - (W-2t)(H-2t)` |
| Equal/custom angle | two rectangles minus overlap; radii ignored only when clearly disclosed |
| Channel | web rectangle + two flange rectangles; radii ignored in generic mode |
| I/H section | web rectangle + two flange rectangles; radii ignored in generic mode |
| Custom area | user-provided area converted to m² |

对于标准型钢，若未来导入经授权的理论重量表，可提供两种结果：

- `Geometry estimate`：由尺寸计算。
- `Catalog theoretical mass`：来自有来源和版本的表格。

两者不得静默混用。

### 5.3 校验规则

- 所有长度必须大于 0，并设置合理上限防止输入单位错误。
- 管材 `2 × wallThickness < outerDimension`。
- I/H/槽钢翼缘总厚度不得超过高度。
- 数量为 1…1,000,000，超范围需确认而非直接崩溃。
- 密度必须大于 0；偏离常用材料范围时显示警告但允许专家继续。
- 单位转换后出现非有限值、溢出或负面积时返回错误，不显示结果。
- 显示值的舍入不反馈到后续计算。

### 5.4 CalculationTrace

```swift
struct CalculationTrace: Sendable {
    let engineVersion: Int
    let normalizedInputs: [TraceInput]
    let areaSquareMeters: Double
    let volumeCubicMeters: Double
    let densityKgPerM3: Double
    let netMassKg: Double
    let wasteAdjustedMassKg: Double
    let pricingSteps: [PricingStep]
    let warnings: [CalculationWarning]
}
```

UI 的“计算详情”和 PDF 内部审计页来自同一 trace，避免另写解释逻辑。

## 6. 单位与地区格式

### 6.1 存储原则

- 几何真值以 SI 基础单位计算。
- 输入模型保留原始单位，编辑界面不因 locale 改变而擅自重写用户输入。
- 结果可按项目或用户偏好显示 kg/lb、m/ft、mm/in。
- 精度规则按量纲分别设置，不使用全局统一小数位。

### 6.2 输入解析

- 支持 locale 小数分隔符，例如 `12.5` 与 `12,5`。
- 英寸输入 v1 只支持十进制；分数英寸如 `1 1/2` 作为 v1.1 候选，避免首版解析歧义。
- 禁止把逗号既当千分位又当小数点；按当前 locale 解析并在歧义时提示。

### 6.3 型材术语

建立别名表但不让别名决定公式：

```text
rectangularTube: 矩形管, rectangular tube, RHS, box section
squareTube: 方管, square tube, SHS, box section
iSection: 工字钢, H型钢, I-beam, H-beam, universal beam
```

## 7. 本地化实现

- 使用 Xcode String Catalog：`Localizable.xcstrings`。
- Key 使用语义命名，如 `calculator.result.total_mass`，不使用英文文案作为 key。
- 所有带数量文本使用 plural variation。
- 错误模型返回 error code + arguments，Presentation 层本地化。
- PDF 模板只保存布局和语义字段，本地化标题从同一 catalog 获取。
- App 内语言覆盖保存为 BCP 47 code；`.system` 表示跟随系统。
- Quote language 独立于 UI language，项目可指定 `zh-Hans` 或 `en`。
- 自动化测试扫描 Swift 源码中疑似硬编码用户可见字符串。

## 8. 持久化与迁移

### SwiftData entities

- `ProjectEntity`
- `CalculationItemEntity`
- `MaterialEntity`
- `CustomerEntity`
- `CompanyProfileEntity`
- `QuoteSnapshotEntity`
- `AppPreferenceEntity`

### 迁移原则

- 使用显式 `SchemaV1`, `SchemaV2`。
- 每次改变公式语义时增加 `calculationVersion`，而非只改 UI。
- 旧项目重新打开时可使用新引擎重算，但已导出的 QuoteSnapshot 保持冻结值。
- 迁移先复制/验证再提交；失败时保留原 store 并提供导出诊断。

## 9. 备份文件格式

扩展名：`.steelflowbackup`

v1 使用 ZIP 容器：

```text
manifest.json
projects.json
materials.json
customers.json
company-profile.json
quote-snapshots/
assets/logo.png
```

`manifest.json` 包含：

- schemaVersion
- appVersion
- createdAt
- locale
- objectCounts
- SHA-256 checksums

导入流程：选择文件 -> 校验 manifest/checksum -> 预览对象数 -> 选择复制导入或取消 -> 单事务写入。禁止静默覆盖同 ID 数据。

## 10. PDF 与 CSV

### PDF pipeline

1. Domain 生成不可变 `QuoteDocumentModel`。
2. `QuotePaginator` 根据纸张和可见列计算行高及分页。
3. Core Graphics 绘制文本、表格和矢量截面图。
4. PDFKit 用于预览和系统分享。

要求：

- A4 与 Letter 独立 golden files。
- 中文使用系统可嵌入字体策略；导出前验证字形覆盖。
- 表头跨页重复，金额列不换行，说明列可自然换行。
- 默认不把内部成本、利润和备注输出给客户。
- 文件名安全化并保留项目号，如 `Q-2026-018_Acme.pdf`。

### CSV schema

首行固定机器字段，不随 UI 语言变化；另提供本地化显示名称映射：

```csv
item_id,profile_kind,description,material,density_kg_m3,length_value,length_unit,quantity,unit_mass_kg,total_mass_kg,unit_price,currency,total_price
```

- UTF-8 with BOM 作为 Excel 兼容选项。
- 数字使用 `.` 作为机器小数点，不写本地千分位。
- 单位和币种单独列，不混进数字字符串。

## 11. RevenueCat + StoreKit 2

产品：`com.steelflow.app.pro.lifetime`；RevenueCat entitlement：`pro`；offering：`default`。

- 非消耗型购买。
- `CustomerInfo.entitlements["pro"].isActive` 作为 App 内权益真值；RevenueCat 从 Apple 收据同步底层交易。
- 本地缓存最近已验证 entitlement，使离线用户持续使用。
- 启动、前台恢复、购买完成、CustomerInfo 更新和手动恢复时更新状态。
- 使用 RevenueCat 匿名 App User ID，不建立 SteelFlow 账号，也不上传项目/报价内容。
- 中国大陆用户占比较高，SDK 在 configure 前使用 RevenueCat 官方备用 API 域名 `https://api.rc-backup.com/`。
- Debug 可使用 `test_` Test Store key；Release 只接受 `appl_` Apple public SDK key，避免测试密钥进入正式包。
- Free 限制只影响保存/导出，不阻止用户完成基础计算。

## 12. 隐私与安全

- 不收集项目、客户、报价、材料和计算内容。
- 无广告、行为分析或远程配置 SDK；RevenueCat 仅处理购买和匿名权益分析。
- OSLog 禁止记录客户名、金额、尺寸和文件路径。
- 备份由用户主动导出；分享后由目标应用负责存储。
- 公司 Logo 使用 app sandbox，删除公司资料时一并清除未引用资源。
- 提供全部数据删除，并在删除前显示对象数量。
- 隐私政策与 App Privacy 明确披露 Apple 和 RevenueCat 处理购买历史；该数据不关联用户身份、不用于跨 App 跟踪。

## 13. UI 状态与并发

- 编辑器使用局部 draft，点击完成或离开时原子提交。
- 计算引擎为纯同步函数；复杂项目汇总可在后台 task 执行，并使用 stable snapshot。
- PDF 生成使用可取消 task；取消后删除临时文件。
- SwiftData 访问集中在 `@MainActor` repository；导出先复制为 Sendable DTO。
- 不在 SwiftUI `body` 内执行格式化以外的计算。

## 14. 测试方案

### 14.1 CalculationEngineTests

- 每种型材正常、边界、无效几何和单位转换。
- 公制/英制等价输入产生相同内部结果。
- 属性测试：尺寸同比例放大 k，面积按 k²、质量按对应比例变化。
- 管壁趋近 0、内径趋近 0、超大数量和非有限输入。
- 显示舍入不影响后续金额。

### 14.2 Reference corpus

建立版本化 JSON：

```text
case ID
source or reviewer
input dimensions and units
material density
expected area/volume/mass
tolerance
notes
```

至少 100 个参考案例，其中 30 个由目标行业用户独立复核。任何公式修订必须跑完整语料。

### 14.3 MoneyTests

- 不同货币小数位。
- 税前/税后、margin/markup 的明确定义。
- 逐行舍入与总计舍入策略。
- 负折扣、零价格和极大金额。

### 14.4 LocalizationTests

- `zh-Hans` 与 `en` 无缺 key。
- 德语伪本地化用于发现长度问题，即使未首发。
- 小数逗号 locale、阿拉伯数字、本地日期和币种。
- 中文/英文 PDF golden image diff。

### 14.5 UI/AccessibilityTests

- 新用户完成快速计算和保存项目。
- Dynamic Type 最大辅助字号。
- VoiceOver 顺序、单位读法和错误播报。
- iPhone SE 宽度、主流 iPhone、iPad split view。
- 深色模式和提高对比度。

## 15. 性能预算

| 操作 | 目标 |
|---|---:|
| 单条计算 | < 50 ms |
| 200 条项目重算 | < 150 ms 后台完成 |
| 100 条 PDF | 2 秒级，主线程不卡顿 |
| 冷启动 | 现代设备约 1 秒内可操作 |
| 备份 500 项目 | 峰值内存 < 150 MB |

这些是工程目标，需在真机上测量并调整。

## 16. 国内与全球发布边界

v1 核心功能完全离线：不提供行情、账号、云端模板、AI、广告或自有内容接口。付费下载本身不改变计算架构。是否需要中国大陆 APP 备案应以实际功能、App Store Connect 提示和接入商/通信管理部门确认结果为准，不能只按“工具类”判断。

未来加入以下能力前，应先重新评估备案、隐私和后端：

- 实时钢价或供应商价目表同步。
- CloudKit/自有账号和跨设备同步。
- 社区模板、远程型材目录和在线 AI。
- 团队协作、客户门户或 Web 管理台。

## 17. 实施阶段

### Phase 0：真值验证

- 独立 Swift package `SteelFlowCore`。
- 5 种型材、单位和金额计算。
- 100 个参考案例框架。

### Phase 1：本地 MVP

- SwiftUI shell、计算器、材料、项目。
- zh-Hans/en String Catalog。
- SwiftData schema v1。

### Phase 2：交付闭环

- 报价模型、PDF/CSV、公司资料、A4/Letter。
- 备份/恢复和数据迁移测试。

### Phase 3：商业化与 QA

- RevenueCat/StoreKit 2、免费限制、恢复购买。
- iPad、无障碍、性能、本地化和真机验证。
- App Store 隐私、截图、审核说明和中国区合规确认。

## 18. 开发完成定义 / Definition of done

- 所有 P0/P1 功能验收通过。
- 参考语料零已知错误，无效几何全部被阻止。
- 中英文无缺失、截断或 PDF 字形问题。
- 无网络时核心计算、项目和导出完整可用。
- 购买可在测试环境恢复，卸载重装后 entitlement 正确。
- 备份在干净安装上恢复并通过对象数量/checksum 验证。
- App Privacy、隐私政策、许可证、数据来源和免责声明完成审核。
