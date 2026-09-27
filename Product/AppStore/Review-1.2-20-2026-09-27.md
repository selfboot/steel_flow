# SteelFlow 1.2（20）Review 与审核提交记录

## 范围与修复

审查范围为线上 1.1.0（13）到本次 1.2 的产品代码变化、归档配置、中英文更新说明与 ASO 截图。

- 修复：根视图的自定义 `LabelStyle` 导致原生系统菜单中带图标的操作失去文字与可访问标签，影响保存模板、从模板创建项目和报价历史。移除全局覆盖，保留明确使用的金属图标组件。原先失败的模板与报价历史 UI 流程已验证恢复。
- 修复：设置页的数据收集说明由“不收集 / None”改为“匿名购买信息 / Anonymous purchase info”，与现有 RevenueCat 购买信息处理及隐私披露一致。
- 更新旧 UI 回归测试，展开 3D 预览、价格及费用明细，切换至历史参考价目录后再操作；报价测试检查实际 PDF 预览及原生合并的总价标签。
- 增加实际生成 PDF 的中英文回归验证，检查文字语言、客户报价隐藏内部成本，以及描述、重量、金额列不重叠且位于页面内。
- 购买 UI 测试显式建立 `SKTestSession` 并将现有 StoreKit 配置打包进测试 target，避免测试启动方式未启用本地商店时一直等待价格。此项仅修改测试，不改变上传的发行包。

## 商店资料

- 中英文版本更新说明与审核操作说明已保存到 App Store Connect，并逐项比对本地 metadata.json。
- 12 张新 iPhone ASO 封面已上传，Apple 状态全部 COMPLETE，MD5 与本地导出一致。
- 保留 12 张已发布版本的 iPad 截图，状态全部 COMPLETE。
- 英文与中文支持、宣传、隐私页面共 6 个 URL 均返回 HTTP 200。
- 现有商店描述、关键词、审核联系人、价格和隐私披露沿用；发布方式 AFTER_APPROVAL。
- 文件上传的 App Store Connect API 与 object-storage 链路已确认经过香港代理。

## 产物

- 构建：1.2（20），Bundle ID `com.steelflow.app`。
- 正式归档：`Build/ReviewRelease20-20260927/SteelFlow-1.2-20.xcarchive`。
- IPA：`Build/ReviewRelease20-20260927/export/SteelFlow.ipa`。
- SHA-256：`060519a3074cb2560db355bf9fc71b15270b940c2a083ef4506a9b1a3851dfdc`。
- Release 归档、App Store 导出、严格签名验证通过。包内版本、正式购买 SDK key 类型与出口合规声明已核实。

## 验证状态

- 最终分批回归覆盖 129 个独立测试：91 项单元测试、38 项 UI 测试，全部通过，无剩余失败或跳过。
- 覆盖计算与参考数据、项目与模板、报价历史、真实 PDF 内容与布局、费用与币种、收藏、数据恢复、删除确认、导出失败重试、中英文本地化、横屏、深色和大字号可访问性。
- 购买测试验证商品价格加载、系统 StoreKit 购买弹窗与取消后的恢复；使用本地 StoreKit 测试环境，未进行真实扣款。
- RevenueCat 主域名和官方备用域名均可读取当前 offering，永久版商品标识正确；应用运行日志记录商品请求与 offering 更新成功。
- 新 iPhone ASO、现有浅色/深色界面截图和当前构建的 iPad 深色计算主页已目视检查。
- 实际导出 IPA 的严格签名验证通过，`get-task-allow=false`；版本、Bundle ID、中英文隐私说明均与提交内容相符。
- 测试汇总保存在忽略目录 `Build/SubmissionReview-20260927/final-test-evidence.json`，包含每项测试最终通过的 xcresult 路径。前序旧选择器与 StoreKit 环境失败结果保留作为诊断证据，均有修复后的通过结果。

## 苹果审核提交

- 提交时间：2026-09-27 16:15:54（Asia/Shanghai）。
- App ID：`6806282417`。
- 版本：`1.2`，版本资源 ID：`6d6bb56d-6bcc-47f1-8595-3bd9bd3bf9aa`。
- 构建：`20`，构建资源 ID：`cf980661-4710-4ce1-9fdd-410bc264375b`，处理状态 `VALID`。
- 审核提交 ID：`55aa5553-59a2-43df-9b31-ae4ca72e3d02`。
- 提交后重新读取审核单与版本，两者均为 `WAITING_FOR_REVIEW`，发布方式为 `AFTER_APPROVAL`。
- 回执保存在 `Build/SubmissionReview-20260927/submitted-review-verified.json` 与 `submitted-version-verified.json`。
- [App Store Connect 版本页](https://appstoreconnect.apple.com/apps/6806282417/distribution/ios/version/6d6bb56d-6bcc-47f1-8595-3bd9bd3bf9aa)。
