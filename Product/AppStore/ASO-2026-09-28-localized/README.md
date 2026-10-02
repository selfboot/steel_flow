# SteelFlow 1.3 · 六语言 ASO 素材（2026-09-28）

已随 1.3（26）于 2026-09-28 提交 App Store Connect 审核，当前等待审核。包含繁体中文（zh-Hant）、日语（ja）、韩语（ko）、德语（de-DE）、西班牙语（es-ES）和法语（fr-FR）。英文和简体中文现有截图不在本次替换范围内。

## 使用

打开 `index.html` 可逐语言检查截图和复制文案，点击截图查看原尺寸。

- `metadata/<locale>/`：标题、副标题、关键词、推广文字、描述和版本更新，均为可粘贴的纯文本。
- `localizations.json`：上述文案和 6 张截图标题的结构化原稿。
- `exports/ios/iphone/1320x2868/<locale>/`：首选 iPhone 图，每语言 6 张。
- `exports/ios/ipad/2064x2752/<locale>/`：首选 iPad 图，每语言 6 张，来自真实 iPad 布局。
- 另提供 iPhone 1284×2778、1206×2622、1125×2436 与 iPad 2048×2732。共 72 个独立画面、216 个尺寸版本。
- `covers-overview.png`：6 种语言首图总览。
- `search-thumbnail-review.png`：每种语言前 3 张的 160 px 宽缩略图。
- `metadata-validation.json`、`asset-manifest.json`：长度校验及文件尺寸、色彩模式、SHA-256。

导入时按文件名前缀 01–06 排序：重量计算 → 项目成本 → PDF 报价 → 型材选择 → 材料密度 → 单价与耗损。每个设备/尺寸目录都有独立语言目录，不要混用。

## 本地化与设计

参考 `../ASO-2026-09-27/exports/iphone/1320x2868/en-US/` 的英文布局：深钢蓝背景、上方简洁标题、正面设备和大幅真实 UI。通过现有 ScreenshotsEditor 模板渲染，没有重绘或翻译覆盖 App 界面。所有画面使用真实 SwiftUI 截图；示例项目、客户、材料说明、报价内容和币种随语言切换。品牌 SteelFlow、PDF/CSV、单位及材料牌号保留标准写法。

繁体中文示例采用台湾用词与 TWD；日语为 JPY，韩语为 KRW，德/西/法语为 EUR。价格为演示数据，不是实时行情或汇率。西语、法语元数据本次对应西班牙和法国本地化，未单独制作墨西哥或加拿大变体。

iPad 截图专用 DEBUG 入口隐藏系统状态栏，避免 SpringBoard 中文日期混入外语截图。正式 App 不受影响。部分截图展示 Pro 权限下的内容；免费额度和一次购买 Pro 范围已在各语言描述中明确写出。

## 搜索策略

| 语言 | 核心意图 | 延伸意图 |
|---|---|---|
| 繁体中文 | 金屬重量計算器、鋼管鋼板算重 | 不鏽鋼、鋁材、圓棒、報價 |
| 日语 | 金属重量計算、鋼材 | パイプ、材料費、PDF見積書 |
| 韩语 | 금속 중량 계산기 | 강재、파이프、재료비、견적 |
| 德语 | Metallrechner、Stahlgewicht、Metallgewicht | Rohr、Blech、Aluminium、Angebot |
| 西班牙语 | Peso de metales、calcula acero | tubos、chapa、presupuesto |
| 法语 | Poids des métaux、calcul acier | tubes、tôle、devis |

标题和副标题覆盖主要意图，关键词补充相关型材与材质，避免品牌堆砌和不相关热门词。描述侧重自然表达和功能转化，不将描述重复关键词或截图文字视为排名保证。排名还受相关性、竞争、下载与转化等因素影响；本批素材没有编造搜索量或排名预测。

用词参考本项目 `../Localization-Demand-2026-09-27.md` 的第三方代理数据及各地真实商店用语。第三方数值不是 Apple 搜索量，不能当成下载量或排名承诺。实际效果需上线后通过各地区产品页转化、自然下载趋势与持续关键词排名观察验证。

参考页面（查询 2026-09-28）：

- [Apple 产品页优化与关键词说明](https://developer.apple.com/app-store/product-page/)
- [Apple 名称与副标题限制](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Apple 描述、推广文字与关键词限制](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [Apple 截图尺寸要求](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [德国金属计算器用词](https://apps.apple.com/de/app/metallgewicht-kostenrechner/id6802344974)
- [西班牙金属重量计算器用词](https://apps.apple.com/es/app/calculadora-de-peso-met%C3%A1lico/id1381240441)
- [法国金属重量计算器用词](https://apps.apple.com/fr/app/calculateur-poids-m%C3%A9tal/id6759548297)
- [日本金属重量计算器用词](https://apps.apple.com/jp/app/id6759548297)
- [韩国金属中量计算器用词](https://apps.apple.com/kr/app/id6802344974)

标题/副标题各 ≤30 字符，推广文字 ≤170 字符，描述 ≤4000 字符；关键词采用更保守的 UTF-8 ≤100 字节校验。Apple 两份说明分别使用 characters 与 bytes，本批同时满足两者。文案已按功能和长度检查，尚未经独立母语审校。

## 可复现来源

编辑器：`../ScreenshotsEditor/`。新的 `editor-project.json` 是可恢复项目状态；`previous-editor-project.json` 保存更改前的英文/简体项目配置，旧素材未删除。当前编辑器已加载这批六语言画面。

原始截图：`../ScreenshotsEditor/public/screenshots/localized-20260928/{iphone,ipad}/{locale}/`。

采集测试：`UITests/SteelFlowUITests.swift` 中的 6 个 `testCapture*MarketingScreens`。DEBUG 演示数据位于 `App/Marketing/MarketingCapture.swift`。测试使用内存数据和确定的语言、币种、计量制与报价样式，避免污染用户项目。

编辑器运行：

```sh
cd Product/AppStore/ScreenshotsEditor
npm install
npm run dev -- --hostname 127.0.0.1 --port 3026
```

选择 iPhone 或 iPad，点击 Export bundle，解压到本目录的 `exports/`。导出后运行：

```sh
python3 Product/AppStore/ASO-2026-09-28-localized/scripts/validate_assets.py --normalize-rgb
```

该脚本仅移除完全不透明的 alpha 通道，保留 RGB 像素，任何实际透明像素都会触发失败；不会重画截图。

## 最终验证

- 最终素材来源：iPhone 6 个语言采集测试；iPad 法语 1 个、其余语言 5 个采集测试，全部通过。每个测试覆盖 6 个功能画面。
- 对应结果包：`Build/ASOLocalized-20260928/iPhone.xcresult`、`iPad-FrenchFinal.xcresult`、`iPad-Final.xcresult`。原始 iPad 批次也通过，但因系统中文日期被弃用并重拍。
- 截图编辑器 TypeScript 检查通过，`git diff --check` 通过。
- 6 份元数据长度验证通过；216 张图片全部为 RGB PNG，尺寸、序号、四角背景和不透明性验证通过。
- 逐语言查看整套缩略图，检查核心画面的原尺寸导出；无营销标题溢出或英文占位文字。App 中标准品牌、单位与材料牌号不翻译。
- 2026-09-28：首选尺寸的 72 张截图及六语言文案已随 1.3（26）提交审核；英文和简体中文原有 24 张截图保留，其他尺寸留作本地备用。
