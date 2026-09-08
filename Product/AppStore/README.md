# SteelFlow App Store 素材

当前 App 代码为 1.1.0（构建 9），发布与测试记录见 [1.1.0 发布记录](Release-1.1.0-2026-09-08.md)。1.0.1 的原始提交历史和本轮改动统一保存在 `main`。

本目录商店截图与元数据对应 2026-09-05 的 1.0.1（构建 8）ASO 更新，历史发布状态见 [1.0.1 发布记录](Release-1.0.1-2026-09-05.md)。上线后复查资料见 [ASO 搜索基线与优化建议](ASO-Audit-2026-09-05.md)，实时搜索和商店截图证据保存在 `Research/2026-09-05/`。

- `Metadata/metadata.json`：中英文名称、副标题、关键词、更新说明及审核说明。
- `Metadata/en-US.md`、`Metadata/zh-Hans.md`：完整商店描述。
- `RawScreenshots/`、`RawScreenshots/iPad/`：新版本真实 SwiftUI 界面的中英文截图。
- `ScreenshotsEditor/`：截图编辑工程与已保存的六页布局。
- `Screenshot-Design-Notes.md`：本轮截图顺序、版式和真实功能依据。
- `Exports/ASO-2026-09-05/`：两种设备、两种语言的六页预览。
- `Exports/SteelFlow-AppStore-Screenshots.zip`：72 张 PNG，包含中英文 iPhone 四种尺寸、iPad 两种尺寸。

首三张依次展示实时重量、项目成本、PDF 报价，随后为型材选择、材料价格库和离线计算。标题和设备上下交替，PDF 页使用深色背景；所有功能画面来自 App 的真实界面。

2026-08-28 的 ASO 和定价研究保留为历史资料。现有 IAP、价格、RevenueCat 配置与隐私声明沿用线上版本。

## 重新生成

原生截图由 `SteelFlowUITests` 的中英文营销截图测试生成，分别在 iPhone、iPad 模拟器运行。测试使用 Debug 专用确定性演示数据，Release 不进入该路径；采集前检查并排除系统弹窗。

```bash
xcodegen generate
xcodebuild -project SteelFlow.xcodeproj -scheme SteelFlow \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' \
  -only-testing:SteelFlowUITests/SteelFlowUITests/testCaptureEnglishMarketingScreens \
  -only-testing:SteelFlowUITests/SteelFlowUITests/testCaptureChineseMarketingScreens test
```

```bash
cd Product/AppStore/ScreenshotsEditor
npm run dev -- --port 3026
```

在编辑器分别选择 iPhone、iPad，点击 **Export bundle**。正式上传文件只移除全不透明 PNG 的 alpha 通道，不改变任何像素颜色；Apple 接收的最大尺寸为 1320×2868 和 2064×2752，每种设备、语言各 6 张。
