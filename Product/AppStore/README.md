# SteelFlow App Store launch kit

本目录包含 2026-08-28 准备的双语上架素材：

- `ASO-Research-2026-08-28.md`：中国大陆、美国及英语市场交叉验证的关键词与竞品报告。
- `Metadata/metadata.json`：可复制到 App Store Connect 的结构化字段和 IAP 文案。
- `Metadata/en-US.md`、`Metadata/zh-Hans.md`：完整商店描述。
- `RawScreenshots/`：从 iPhone 16 Pro 模拟器截取的真实中英文首页。
- `ScreenshotsEditor/`：可继续编辑并批量导出多尺寸 PNG 的截图工程。
- `Exports/Covers/`：中英文首屏封面的 6.9、6.5、6.3、6.1 英寸 PNG。
- `Exports/SteelFlow-AppStore-Screenshots.zip`：本地导出的 2 语言 × 4 尺寸 × 6 页素材包（体积较大，不纳入 Git）。

提交前待办：

1. 替换隐私政策、支持和营销 URL 占位符。
2. 在 App Store Connect 创建 `com.steelflow.app.pro.lifetime` 非消耗型项目并配置分区价格。
3. 第 2–6 页的文案和版式已完成，但当前仍复用首页画面；补拍对应真实界面后，在编辑器中替换并重新导出。
4. 用 TestFlight 对中英文、购买恢复、PDF/CSV 分享和 iPad 布局做最终 QA。
