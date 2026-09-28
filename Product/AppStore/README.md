# SteelFlow App Store 素材

当前 App 代码为 1.3（构建 25），包含八种语言、七套报价 PDF 样式和默认报价设置；已清理无效的项目样式入口、条款编辑及付费提示，预览切换样式仅作用于本次报价。已上传 App Store Connect 并处理成功，尚未提交审核，见 [1.3 构建与上传记录](Release-1.3-25-2026-09-28.md)。此前 1.2（构建 20）的审查与送审结果见 [1.2 提交前 Review 与审核记录](Review-1.2-20-2026-09-27.md)。历史构建记录保留在本目录。

## 苹果上传网络

按用户 2026-09-27 的要求，后续苹果上传使用本机 Clash 的「香港」节点。当前代理端口为 `127.0.0.1:7890`，配置为 `~/.config/clash/Mine.yaml`。上传前检查以下域名规则仍指向「香港」，并在 Clash 连接记录中核实实际链路；其余网站沿用原有路由。

- `appstoreconnect.apple.com`（域名后缀）
- `contentdelivery.itunes.apple.com`、`itunesconnect.apple.com`（精确域名）
- `upload.itunes.apple.com`、`blobstore.apple.com`、`object-storage.apple.com`（域名后缀）

Apple 的文件上传会使用 `northamerica-1.object-storage.apple.com` 等存储地址，仅配置 App Store Connect API 不足以覆盖传输。控制器使用现有鉴权，凭据不写入本仓库。发布日志中的临时签名上传链接不要公开。

当前中英文更新说明与 iPhone ASO 封面对应 2026-09-27 的 1.2（构建 20），iPad 截图沿用已发布素材。2026-09-05 的 1.0.1（构建 8）截图和历史发布状态见 [1.0.1 发布记录](Release-1.0.1-2026-09-05.md)。上线后复查资料见 [ASO 搜索基线与优化建议](ASO-Audit-2026-09-05.md)，实时搜索和商店截图证据保存在 `Research/2026-09-05/`。

- `ASO-2026-09-27/`：本轮中英文各 6 张 iPhone 封面、真实采集截图、提示词与打包文件。
- `Metadata/metadata.json`：中英文名称、副标题、关键词、更新说明及审核说明。
- `Metadata/en-US.md`、`Metadata/zh-Hans.md`：完整商店描述。
- `RawScreenshots/`、`RawScreenshots/iPad/`：新版本真实 SwiftUI 界面的中英文截图。
- `ScreenshotsEditor/`：截图编辑工程与已保存的六页布局。
- `Screenshot-Design-Notes.md`：本轮截图顺序、版式和真实功能依据。
- `Exports/ASO-2026-09-05/`：两种设备、两种语言的六页预览。
- `Exports/SteelFlow-AppStore-Screenshots.zip`：72 张 PNG，包含中英文 iPhone 四种尺寸、iPad 两种尺寸。

本轮 iPhone 封面依次展示重量计算、项目成本、PDF 报价、型材选择、材料密度和损耗计价，采用小标题与大设备画面。封面依据真实 App 截图生成，原始截图单独保存；详细制作与验证说明见 `ASO-2026-09-27/README.md`。

2026-08-28 的 ASO 和定价研究保留为历史资料。现有 IAP、价格、RevenueCat 配置与隐私声明沿用线上版本。

## 历史编辑器导出流程

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
