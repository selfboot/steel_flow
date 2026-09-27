# 首页型材素材与紧凑草稿

2026-09-27，使用内置 imagegen 为全部 13 类型材单独生成写实钢材图片。原图与完整提示词保存在本目录，提示词见 [prompts.md](prompts.md)。

## 正式资源

`App/Resources/Assets.xcassets/ProfileMaterial-<profile>.imageset/`，profile 对应 `ProfileKind.rawValue`：plate、roundBar、squareBar、hexBar、octagonalBar、roundTube、squareTube、rectangularTube、angle、channel、iSection、tSection、customArea。

每组包含 64/128/192px 的 1x/2x/3x PNG，经 sips 等比例缩小，保留原始透明通道。39 个文件共 652,150 字节（约 637 KiB），无需运行时加载网络图片。自定义截面使用带缺口的非标准截面作为示意，不代表固定计算形状。

## 页面改动

- 草稿普通字号使用两行：名称与总重量同排，尺寸、长度、数量和材料合并为副标题。移除草稿前的重复图标，收紧内边距。
- 辅助字体自动将重量独立成行，避免挤压名称；型材卡片沿用单列适配。
- 新建计算保留文字及可访问性标识，使用 52×56pt 图片区域，同排卡片对齐。

## 验证

- iPhone 16e / iOS 26.3：中文浅色、中文深色、英文标准字号、英文最大辅助字体均实际截图并检查。大字体的名称挤压问题已修复。
- 13 个 ProfileKind 的图片映射齐全，39 个 PNG 均校验分辨率与 RGBA 通道。
- 模拟器构建成功，无警告或错误；主导航/默认计算、主要页面本地化 2 项 UI 回归通过。随后字体适配和卡片对齐调整再次构建、视觉复查通过。
- 截图：`Build/HomeUI-20260927/QA/`。
- UI 测试结果：`~/Library/Developer/XcodeBuildMCP/workspaces/SteelFlow-1dd3ec10f123/result-bundles/test_sim_2026-09-27T04-51-24-544Z_pid31583_e7c7fc95.xcresult`。
- 本轮未验证 iPad 实际显示，未重新归档或上传苹果；上次上传构建 15 不含本轮首页及 kg 图标更新。
