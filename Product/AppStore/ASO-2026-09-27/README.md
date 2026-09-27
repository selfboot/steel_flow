# SteelFlow 1.2（19）ASO — 2026-09-27

本轮重新采集中文、英文 iPhone 核心操作页面，使用内置 imagegen 生成每语言 6 张封面。用户明确要求缩小标题、以截图为画面主体；正式成稿使用小标题单行文案与占主体的正面设备，统一深钢蓝、冰蓝、金属银和中心光照。

## 内容顺序

1. 输入尺寸，即刻算重 / Metal weight. Calculated. — calculation
2. 项目成本，一目了然 / Every cost. One clear total. — project
3. 专业报价，随时分享 / Quotes, ready to share. — quote
4. 常用型材，快速开算 / Pick a shape. Start calculating. — home
5. 材料密度，随用随查 / Material densities, at hand. — materials
6. 损耗计价，清晰掌握 / Price with waste in mind. — pricing

## 文件

- `raw/iphone/`：12 张原始模拟器截图，1170×2532。
- `generated/`：12 张 imagegen 最终源图，851×1848。
- `exports/iphone/1320x2868/`：12 张 RGB、无透明通道的标准尺寸 PNG。通过 sips 将生成源图重采样至 1320×2868；不是原生 1320px 生成。
- `prompts/`：逐张完整提示词、缩小字体的修订指令及项目数量修正指令。
- `drafts/`：已弃用的大字版和修正前图片，不包含在最终导出目录。
- `index.html`：中英文整套预览，支持 160px 缩略图检查与单图打开。
- `SteelFlow-ASO-1.2-20260927.zip`：正式封面、原始截图、提示词及说明打包，不含弃用草稿。

封面是根据真实截图生成的宣传图，非原始屏幕像素的直接拼贴。已核对主要标题、重量、密度、项目总价与 PDF 金额；原始截图单独保留便于后续逐像素合成与比对。演示材料价格属于确定性示例，不是实时行情。

## 采集验证

设备：iPhone 16e / iOS 26.3，浅色，9:41 状态栏。基于 Git `9689aa1` 的 1.2（19）代码。
仅调整 `UITests/SteelFlowUITests.swift` 的采集流程：先展开计价并滚动至单价；材料页采集内置目录；报价页保留顶部真实 PDF 预览与固定分享按钮。
中文与英文采集测试 2/2 通过，最终结果：
`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T07-08-10-227Z_pid92380_f8dd14a2.xcresult`。
未更改产品功能、未上传 App Store Connect。本轮交付 iPhone 封面，历史 iPad 素材未覆盖。

## 设计参考与规格

- [Things](https://culturedcode.com/things/)：参考工具类产品的简洁文案和清晰真实界面展示。
- [Linear Mobile](https://linear.app/mobile)：参考克制的设备呈现和工业产品摄影气质。
- [Apple 截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)：导出 1320×2868 竖版。
参考只用于布局方向，成稿未使用上述品牌标识、界面或宣传声明。
