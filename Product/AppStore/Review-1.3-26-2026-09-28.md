# SteelFlow 1.3（26）苹果审核提交记录

- 提交时间：2026-09-28 21:48:13（Asia/Shanghai）。
- App ID：6806282417；版本 ID：`1e9f6396-d7e9-40bb-8fb3-a2d9512416c4`。
- 构建：26；构建 ID：`2a2ef811-37be-4704-9483-1ca08d29faee`，处理状态 VALID，出口合规声明沿用构建中的 false。
- 审核单 ID：`b92a7ecc-b484-4dbf-b38c-64fd001bdb9d`。
- 提交后重新读取审核单和版本，均确认 `WAITING_FOR_REVIEW`。
- 发布方式沿用 `AFTER_APPROVAL`，审核通过后自动发布。

## 本次商店资料

- 8 种语言的名称、副标题、关键词、描述、推广文字、更新说明、支持/宣传/隐私链接均与本地 Metadata 逐项比对一致。
- 新增六语言各 6 张 iPhone、6 张 iPad 截图，共 72 张；英文和简体中文原有 24 张截图保留。
- 共 96 张截图均为 COMPLETE；新增图片的 Apple 源文件 MD5 与本地一致，所有图片顺序已核对。
- 支持、宣传、隐私页面共 6 个 URL 均返回 HTTP 200。
- 审核联系人沿用已审核版本，更新审核备注，不需要演示账号。
- 构建验证和 115 项单元测试、5 项 UI 回归记录见 Release-1.3-26-2026-09-28.md。

## 回执

保存于 `Build/SubmissionReview26-20260928/`，包括 submitted-review-verified.json、submitted-version-verified.json、verified-screenshots.json、preflight-localizations.json、preflight-app-info.json、preflight-review-detail.json 和 support-links.json。

准备过程中遇到苹果 API 临时错误和一次图片传输超时，均已恢复；最终全部校验通过后提交。

[打开 App Store Connect 审核版本](https://appstoreconnect.apple.com/apps/6806282417/distribution/ios/version/1e9f6396-d7e9-40bb-8fb3-a2d9512416c4)
