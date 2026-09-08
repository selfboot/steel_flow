# SteelFlow 1.1.0（构建 9）发布记录

日期：2026-09-08。应用：com.steelflow.app；App Store Connect：6806282417；开发团队：4Z5Z5TE9EX。

## 范围

以已上传的 1.0.1（构建 8，提交 3b27f8e）为基线，保留该版的 13 种截面、数量键入、顶部重量预览、3D 截面、币种选择和购买页，完成功能评估第 6 节的第一、第二、第三批。第四批探索能力不属于本次发布。

### 第一批：报价正确性

- 跨币种保存明确确认：保留数字、按手工汇率转换或清空；单价保持精度，固定费用按目标币种舍入。
- 公英制质量、尺寸和长度贯穿项目与报价交付。
- PDF 完整显示截面、材料/牌号、每件长度和数量；按内容换行和分页，长条款继续到下一页。
- kg/lb、m/ft 计价单位等价转换；跨量纲要求核对。
- 历史价格遇到材料、截面或按件价格的长度变动时要求核对；价格簿支持限定截面和按件长度。

### 第二批：录入和复用

- 快速重量与完整报价模式，保留前置结果和直接数量输入。
- 独立计算历史、收藏规格、点击复算、草稿自动恢复、简明文本分享与连续添加。
- 条目复制，项目搜索/排序/置顶，材料复制和置顶，价格搜索与过期提示。
- 统一 Pro 页面；保存、复制、模板、备份等操作解锁后接续。

### 第三批：项目交付

- 明确保存报价版本；历史版本固定价格、日期、条款、公司信息，支持重导出、比较和复制成新项目。
- 客户簿、客户选择、项目模板；使用模板默认清空旧价格。
- 公司 Logo 和默认条款；重量与客户销售单价列可配置。
- 客户报价、采购、下料、内部成本四种 CSV；客户输出隔离内部成本，汇总金额只输出一次。
- 选中行批量计价、材料/说明筛选、变动预览和撤销；删除条目可撤销。
- 备份版本升级为 v4，兼容旧备份，包含新字段与计算历史/草稿；显示备份时间、内容与提醒。

## Review

- 检查金额转换、价格来源与规格失配、快照冻结、模板复制、客户/内部输出隔离、备份兼容和免费/Pro 接续。
- 修正跨币种转换提前舍入、CSV 重复项目汇总、按件价格长度失配、历史版本复制解锁后不接续等问题。
- 测试数据与模拟 Pro 权限仅在 DEBUG 中启用；Release 使用真实购买配置验证。
- 原工作区的配置、图标及文档修改保留，未覆盖或回退。

## 验证

- 83 项业务测试全部通过（LengthGate.xcresult）；6 项 iPhone 工作流全部通过（ReleaseGate.xcresult），覆盖中文报价、跨币种、收藏、报价版本、客户模板、选择性批量修改及撤销。
- iPad 中文报价与跨币种通过（FinalValidation.xcresult）；报价版本流程通过（iPadFinal.xcresult）。初次 iPad 版本测试因脚本假定底部标签栏而失败，修正为兼容顶部标签栏后通过。
- 长度与数量界面回归通过（LengthUIFinal.xcresult、LengthGate.xcresult）。长度脚本原来双击宽输入框中间，可能落在空白区域；改用明确删除后输入，验证 7.25 精确值及键盘行为。共 8 项 iPhone 界面场景通过。
- 真实数据库升级：先安装旧版模拟器 App，建立 1 个项目和 3 个条目，再覆盖安装新版正常启动；对比项目名称/编号/币种、条目类型/长度/数量/价格，全部一致，新模型字段正常迁移。
- 视觉检查：英文英制 A4 报价、中英文复杂描述与长条款 Letter 报价首末页，以及 iPhone/iPad 报价版本页面均正常。
- git diff --check 通过。
- 购买流程使用 DEBUG 权限夹具验证 UI；本轮未执行新的真实 App Store 沙盒交易。Release 购买 SDK 版本仍为 RevenueCat 5.85.0。
- 供应商含税标记继续明确为“仅记录”；未引入未经验证的税务成本规则。

## 构建与上传

- Release 归档成功：`Build/Functional-20260908/SteelFlow-1.1.0-9.xcarchive`。
- App Store 分发包：`Build/Functional-20260908/export/SteelFlow.ipa`（7662152 字节）。
- 签名严格校验通过；团队与 bundle 匹配；get-task-allow 为 false；Release 不含工作流测试夹具。
- IPA SHA-256：`b7ba096ccedd874f6df7c5488d47c3a755a1fab65caa4290f1a5d86f5acfac5f`。
- Apple 服务端校验通过：VERIFY SUCCEEDED with no errors。
- 上传成功：2026-09-08 08:18（Asia/Shanghai），UPLOAD SUCCEEDED with no errors。
- Delivery UUID：`40040ef3-ad1b-47a0-af75-175c1d0433a0`。
- Apple 后台处理完成：`VALID`；`APP_STORE_ELIGIBLE`；关联版本 `1.1.0`；构建 `9`；无出口合规信息缺失。
- API 与 altool 双重确认已出现在 App Store Connect。未提交 App Review。
- [App Store Connect / TestFlight](https://appstoreconnect.apple.com/apps/6806282417/testflight)。

## 更新说明草稿

中文：新增计算历史与收藏、草稿恢复、客户和项目模板、报价历史版本、公司 Logo、自定义报价列及多用途导出。支持选中条目批量改价与撤销，改进币种和计价单位切换、价格规格匹配、公英制显示及长报价单排版。

English: Reuse calculations with history, favorites and draft recovery. Add customers, project templates, saved quote versions, company logos and configurable quote columns. Export customer, purchasing, cutting and internal cost files. Update selected items with previews and undo, with improved currency handling, price specification matching, imperial units and long quote layouts.
