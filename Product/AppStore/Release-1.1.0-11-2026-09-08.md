# SteelFlow 1.1.0（11）发布记录

- 日期：2026-09-08
- 分支与目录：main，当前 SteelFlow 工作目录
- Bundle ID：com.steelflow.app
- Apple Team：4Z5Z5TE9EX
- App Store Connect：6806282417
- 内容：[五项截图反馈及同类 UI 修复](../PhotoUI-Fixes-2026-09-08.md)

## 验证

- 7 个不同 UI 场景通过，含深色模式、最大辅助字号、模板创建与空状态；详细结果见修复记录。
- 最终 Release 构建及正式签名归档成功；复核本轮差异，没有发现阻断发布问题。
- IPA 严格签名验证通过；版本、Bundle ID、团队、发布权限符合预期，DEBUG 测试入口未包含在正式二进制中。
- 苹果安装包验证：VERIFY SUCCEEDED with no errors。
- 苹果上传：UPLOAD SUCCEEDED with no errors。
- 后台构建：VALID，APP_STORE_ELIGIBLE，预发布版本 1.1.0。
- 未提交 App Review。

## 产物

- 归档：`Build/PhotoRelease-20260908/SteelFlow-1.1.0-11.xcarchive`
- 安装包：`Build/PhotoRelease-20260908/export/SteelFlow.ipa`
- 大小：8036761 bytes
- SHA-256：`dd2af2db87c9ceb9ded24e33f9105da5569fccba75fe941eb044cad73b2fd8a7`
- Delivery UUID / Build ID：`ca091e67-4b59-4280-8fe2-56c33b81d3d5`
- 本地校验与状态记录：`Build/PhotoRelease-20260908/`
- [App Store Connect / TestFlight](https://appstoreconnect.apple.com/apps/6806282417/testflight)
