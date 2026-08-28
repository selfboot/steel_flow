# SteelFlow App Store launch kit

本目录包含 2026-08-28 准备的双语上架素材：

- `ASO-Research-2026-08-28.md`：中国大陆、美国及英语市场交叉验证的关键词与竞品报告。
- `Metadata/metadata.json`：可复制到 App Store Connect 的结构化字段和 IAP 文案。
- `Metadata/en-US.md`、`Metadata/zh-Hans.md`：完整商店描述。
- `RawScreenshots/`：从 iPhone 16 Pro 模拟器截取的 2 语言 × 6 个真实功能界面。
- `ScreenshotsEditor/`：可继续编辑并批量导出多尺寸 PNG 的截图工程。
- `Screenshot-Design-Notes.md`：经典 App 参考、统一版式原则，以及每张文案与真实界面的对应关系。
- `Exports/Covers/`：中英文首屏封面的 6.9、6.5、6.3、6.1 英寸 PNG。
- `Exports/SteelFlow-AppStore-Screenshots.zip`：最终导出的 2 语言 × 4 尺寸 × 6 页素材包（48 张 PNG，体积较大，不纳入 Git）。

当前六页均为“标题在上、设备在下”的统一规则，分别对应首页、计算结果、真实计价、项目汇总、报价预览和材料价格库；不再复用同一张首页截图。

提交前待办：

1. 替换隐私政策、支持和营销 URL 占位符。
2. 在 App Store Connect 创建 `com.steelflow.app.pro.lifetime` 非消耗型项目并配置分区价格。
3. 用 TestFlight 对中英文、购买恢复、PDF/CSV 分享和 iPad 布局做最终 QA。

## 重新生成

原生界面由 `SteelFlowUITests` 中的两条营销截图测试生成，使用 `--marketing-screen` Debug 启动参数加载确定性项目数据；正式 Release 构建不会进入该路径。

```bash
xcodegen generate
xcodebuild -project SteelFlow.xcodeproj -scheme SteelFlow \
  -destination 'platform=iOS Simulator,id=<IPHONE_SIMULATOR_ID>' \
  -only-testing:SteelFlowUITests/SteelFlowUITests/testCaptureEnglishMarketingScreens test
xcodebuild -project SteelFlow.xcodeproj -scheme SteelFlow \
  -destination 'platform=iOS Simulator,id=<IPHONE_SIMULATOR_ID>' \
  -only-testing:SteelFlowUITests/SteelFlowUITests/testCaptureChineseMarketingScreens test
```

继续编辑和导出：

```bash
cd Product/AppStore/ScreenshotsEditor
npm run dev -- --port 3016
```

浏览器打开 `http://localhost:3016/`，点击 **Export bundle** 即可导出所有语言和尺寸。
