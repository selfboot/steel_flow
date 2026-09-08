# SteelFlow 1.0.1 ASO 更新与审核记录

已于 **2026-09-05 13:16:38 UTC+8** 提交 App Store 审核。API 回读确认版本与审核提交均为 **WAITING_FOR_REVIEW（等待审核）**；审核通过后自动发布（AFTER_APPROVAL）。此记录表示已送审，尚未获得审核通过结果。

| 项目 | 值 |
| --- | --- |
| App | SteelFlow，6806282417 |
| Bundle ID | com.steelflow.app |
| 版本 / 构建 | 1.0.1 / 8 |
| 版本 ID | c42ac0e8-63bf-4105-b9c3-f3a592254086 |
| 构建 ID | b69a2d85-1bf5-4c62-88fb-320b67170c2a |
| 审核提交 ID | 18ae6526-a9fe-471a-957d-78fdd5419e83 |
| 源码分支 | codex/steelflow-aso-20260905 |
| 发布基线 | f636422，线上 1.0（构建 7）对应源码 |

[打开 App Store Connect](https://appstoreconnect.apple.com/apps/6806282417/distribution/ios/version/inflight)

## 已完成修改

1. 中文副标题改为“钢管钢板算重，材料成本与PDF报价单”，突出钢管、钢板算重和报价场景；保留现有中英文 App 名称。
2. 调整中英文隐藏关键词，补充材质和型材词，移除重复词与匹配较弱的词。英文 100 bytes，中文 97 bytes，均在 Apple 限制内。
3. 描述首段直接说明从尺寸算重、核算成本到生成 PDF 报价的用途；更新说明对应真实功能变化。
4. 中英文、iPhone/iPad 各 6 张新截图，共 24 张；顺序为实时算重、项目成本、PDF 报价、型材选择、材料价格、离线计算。全部上传完成，顺序及文件 MD5 与 Apple 回读结果一致。
5. 计算页顶部增加单件重量与总重量预览，随尺寸、数量和材料更新，明确为不含损耗的理论净重；复用原有计算引擎与单位换算。

英文关键词：

`steel,pipe,tube,plate,bar,beam,angle,aluminum,stainless,copper,brass,material,mass,estimate,imperial`

中文关键词：

`金属,圆管,方管,角钢,槽钢,工字钢,H型钢,不锈钢,铝材,铜材,圆钢,扁钢,算料`

## 验证

- 68 项单元测试通过，覆盖计算、单位换算、材料密度、计价、PDF、备份和本地化。
- 中英文 iPhone 截图测试、重新采集后的中英文 iPad 截图测试通过，逐张检查无系统弹窗和文案遮挡。
- 核心计算导航与保存入口验证通过；数量输入 12,500 后，重量预览正确显示 588,750 kg。补充测试首次遇到双击手势受模拟器键盘状态影响，改用明确删除、键入后复测通过。
- 截图编辑器 TypeScript 检查和 Git 空白检查通过。
- Xcode 26.6 Release Archive / Export 成功，签名包的 Bundle ID、版本、构建号、出口合规值已核对；Apple 处理状态 VALID。
- 送审前核验构建关联、两种语言元数据、24 张截图、审核联系信息及说明；随后提交并回读 WAITING_FOR_REVIEW。

现有 IAP、价格、隐私披露及 RevenueCat 配置沿用线上版本。

## 文件与复盘

发布时使用 `/Users/daemonzhao/Documents/SteelFlow/Build/ASORelease-20260905` 独立工作区，主工作区原有未提交修改未混入发布。2026-09-08 已将发布提交 `3b27f8e` 的完整历史和素材合并至 `main`；当前主工作区代码为 1.1.0。

- [可编辑商店字段](Metadata/metadata.json)
- [截图设计记录](Screenshot-Design-Notes.md)
- [72 张完整尺寸截图包](Exports/SteelFlow-AppStore-Screenshots.zip)
- [中文 iPhone 预览](Exports/ASO-2026-09-05/iphone-zh-Hans.jpg)
- [英文 iPhone 预览](Exports/ASO-2026-09-05/iphone-en-US.jpg)
- [中文 iPad 预览](Exports/ASO-2026-09-05/ipad-zh-Hans.jpg)
- [英文 iPad 预览](Exports/ASO-2026-09-05/ipad-en-US.jpg)

上传 IPA 的 SHA-256：`79aaea2f2558734505fd2f152073d6afb69f314d1c848a8d21dd0e3baa3613c1`。本机 API 回执、构建与测试日志位于 `Build/ASO-20260905/`，未纳入源码提交。

本轮将关键词、截图和轻量功能改进一起发布。上线后按国家和来源比较前后 7/14 天的搜索曝光、产品页访问、首次下载及转化率，并记录广告影响；当前尚不能据此断言排名或转化已提升。最初搜索排名采样仍是历史基线，不能当作实时排名。
