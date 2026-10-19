# SteelFlow 1.4（29）上传与复核记录

2026-10-19 · Asia/Shanghai

## Apple 状态

- 正式 IPA 上传成功，Apple 处理为 **VALID**；构建 ID `83587827-070f-40ae-a267-0bbef3fb1445`。
- 已关联 **1.4（29）** 到现有草稿 `2cf0c050-54ae-499b-8496-19a7dc203ff9`，提交后回读 **WAITING_FOR_REVIEW**。
- 用户临时将版本号改为 1.4；此前本地生成的 1.3.1（29）归档没有上传，实际上传的是重新归档的 1.4（29）。
- 12 地区更新说明和核心关键词回读与源文件一致。144 张默认截图沿用上一轮已验证的基线，英文对照图仅在本地准备，未启动线上实验。
- Pro 新文案版本 2 `c58c4cf8-f4e5-4004-aa2c-99e3488bc747` 补齐 12 地区，已一并提交，状态 **WAITING_FOR_REVIEW**。已批准的版本 1 保留；新文案尚未上线。
- App 和 Pro 价格未改；不新增统计 SDK。按用户选择仅使用 Apple 与 RevenueCat。
- **已按用户要求于北京时间 2026-10-19 09:18 提交 App Review。** 审核编号 `bc5cfe6a-fee6-47d6-9b68-b9f5d3741290`，App 1.4（29）与 Pro 文案版本 2 均回读 WAITING_FOR_REVIEW。沿用审核通过后自动发布（AFTER_APPROVAL）的配置。

## 按功能拆分提交

| 提交 | 内容 |
| --- | --- |
| `19a7a52` | 计算结果到免费客户报价入口、9 地区翻译与取消／保存／分享测试 |
| `8b043e3` | 构建号 29 |
| `2741bcc` | 设置图标去除背景、阴影与渐变，统一图标栏 |
| `a6c804e` | 版本号改为 1.4 |
| `bcf4b50` | 12 地区 Pro 商品文案、更新说明及审核说明 |
| `e04d050` | 中英文官网下载页源文件与配套截图 |
| `f67c6e9` | 英文截图对照素材、关键词观察与复核记录 |

上述提交已推送 `origin/main`。官网仓库 `puzzles_docs` 的 `0fb6ac2` 也已推送，Cloudflare 生产部署 `a2545604-7ede-4fae-844f-b569952ea580` 生效。[中文官网](https://docs.puzzles-game.com/zh/steelflow)与[英文官网](https://docs.puzzles-game.com/en/steelflow)均回读 HTTP 200，下载按钮存在。

## 二次 review 与验证

- 120 项单元测试通过。
- iPhone 4 项相关 UI 测试、iPad 2 项相关 UI 测试通过：新免费报价流程、Pro 入口浅深色／购买状态、德语最大辅助字号、设置默认值跨两条项目创建流程。
- 新入口测试发现父视图覆盖辅助功能标识，已修复并通过重跑。
- 已查看设置页浅色／深色截图：直接显示图标、没有图标底板与阴影，图标列和文字对齐。
- 官网在手机与桌面布局下检查图片和链接通过；英文截图 6 种导出尺寸及 RGB 检查通过，完整图与搜索缩略图均已查看。
- `asc validate --check-urls`：**0 errors / 0 warnings / 0 blocking**。1 条信息提示：公共 API 无法核验 App Privacy 的发布状态，正式提交前仍需确认。
- 未发现新增阻塞性代码或元数据问题。

边界：Apple 持续报告暂时没有下载／发现实例；已配对 iPhone 当前不可连接，TestFlight 真机购买与恢复尚未验证。不能将上一轮本地 StoreKit 购买成功视为生产支付成功，也不能将公开搜索 API 顺序视为自然排名。当前尚无 1.4 上线后的排名、下载或付费提升证据。

## 安装包

- IPA：`Build/Release-1.4-29-20261019/export/SteelFlow.ipa`
- 大小：11,056,628 字节。
- SHA-256：`506e97681eec5e899426c6dbe154024917ea695bc30a248e5828387c8c9179fe`
- 构建源码：`a6c804edd96df9689d6fd7716fbf60461a80dbcf`
- 严格签名通过，团队 `4Z5Z5TE9EX`，`get-task-allow=false`；正式 RevenueCat 配置，9 个 App 语言资源。

[完整 review 与后续观察方法](ASO-2026-10-19-followup/README.md) · [英文报价对照图](ASO-2026-10-19-followup/index.html) · [结构化测试记录](ASO-2026-10-19-followup/qa/review-results.json) · [发布状态](ASO-2026-10-19-followup/release-status.json)
