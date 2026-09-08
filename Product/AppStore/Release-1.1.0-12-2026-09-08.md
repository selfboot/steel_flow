# SteelFlow 1.1.0（12）发布记录

- 日期：2026-09-08
- 源码：main，Tab 布局改动提交 `5d84def`；本次仅增加构建号至 12。
- Bundle ID：com.steelflow.app；Team：4Z5Z5TE9EX；App：6806282417。
- 内容：四个 Tab 共用紧凑导航标题和顶部 8pt 内容间距；计算页移除重复顶部 padding，材料搜索栏常驻并收紧分类栏间距。

## 验证

- 模拟器构建成功；已有两项 UI 回归通过，覆盖草稿复用、项目搜索和材料分类切换：`Build/TabLayout-20260908/Regression.xcresult`。
- 已检查回归生成的计算页和材料页截图；锁屏期间未完成设置页人工截图检查。
- 正式 Release 归档、导出、严格签名验证通过；版本与发布权限正确，DEBUG 测试入口未包含在正式包中。
- 苹果校验与上传均成功，无错误；后台状态 VALID、APP_STORE_ELIGIBLE，版本 1.1.0（12）。
- 未提交 App Review。

## 产物

- 归档：`Build/TabRelease-20260908/SteelFlow-1.1.0-12.xcarchive`
- IPA：`Build/TabRelease-20260908/export/SteelFlow.ipa`
- 大小：8038146 bytes
- SHA-256：`08252f14bb4f866a583df440a0a051aa3c85262fdd025dfc0127a9b4602e639e`
- Delivery UUID / Build ID：`35caed7f-521b-4e96-884d-fcf220917491`
- 签名、上传日志与后台结果：`Build/TabRelease-20260908/`
- [App Store Connect / TestFlight](https://appstoreconnect.apple.com/apps/6806282417/testflight)
