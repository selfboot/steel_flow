# SteelFlow 1.3.1（27）上传记录

日期：2026-10-19，Asia/Shanghai。

## 结果

- App Store Connect：`6806282417`，Bundle ID：`com.steelflow.app`。
- 版本：**1.3.1（27）**；Apple 已确认 **VALID / APP_STORE_ELIGIBLE**。
- Delivery / Build ID：`7c812b1c-b03c-4b45-9842-0a11bdca95f4`。
- 构建已关联版本草稿 `2cf0c050-54ae-499b-8496-19a7dc203ff9`，状态 `PREPARE_FOR_SUBMISSION`。
- 已同步并回读核对 12 套地区 ASO 文案；en-AU、en-CA、en-GB、es-MX 各补充 6 张 iPhone 和 6 张 iPad 截图，复用原英文／西语素材。
- **未提交 App Review；线上仍为 1.3。App 和 Pro 内购价格不变。**

## 本次改动与提交

- `f894777`：商品加载与权益刷新分离，保留可用商品缓存，处理取消与重复请求，补充回归测试。
- `16ddbcc`：报价预览 Pro 入口、8 种语言的价值说明、付费页曝光记录、大字体与深色适配。
- `ceec218`：设置页移除计算说明、数据收集两项，清理不再使用的说明视图。
- `fb5340b`：国际关键词研究、12 套地区资料和验证证据。
- `8a924b4`：版本号更新为 1.3.1（27）。
- 完整构建源提交：`8a924b40162a0b4e009d7d628f15885d3b0c3b06`。

## 验证

- 最终发布源的 118 项单元测试全部通过，0 失败、0 跳过。
- 之前已通过支付加载／取消、Pro 入口和本地化的 iPhone 20 项聚焦回归，以及 iPad 报价 UI 验证；详见 [测试记录](ASO-2026-10-18/qa/test-results.json)。
- Release Archive、Export 成功。导出 IPA 严格签名校验通过，`get-task-allow=false`，签名团队 `4Z5Z5TE9EX`。
- 8 种 App 语言、正式 RevenueCat 公钥类型和 `pro` 权益配置校验通过。
- 12 套商店资料校验通过；上传后比对无待同步差异。全部 144 张截图均为 `COMPLETE`。
- 补全 Apple 新增的 `socialMedia=false`、`socialMediaAgeRestricted=false`；其余年龄分级声明保留。
- `asc validate` 最终结果：0 errors、0 warnings、0 blocking。另有 1 条信息提示：App Privacy 发布状态不能通过公共 API 验证，审核提交前仍需在后台确认。
- 当前支付验证涵盖本地 StoreKit 商品加载、调起系统购买确认和取消；未进行生产扣款或真机购买／恢复完整闭环。

## 安装包及证据

- IPA：`Build/Release-1.3.1-27-20261019/export/SteelFlow.ipa`。
- 大小：10,974,082 字节。
- SHA-256：`c896fbfac9eca50403fb9007e75410f7e105e432f397df4ac775308ba5839d47`。
- `altool` 返回 `UPLOAD SUCCEEDED with no errors`，退出码 0。
- 忽略目录 `Build/Release-1.3.1-27-20261019/` 保存 Archive、Export、上传日志、Apple 构建状态、商店资料备份及回读结果、截图复用清单、签名验证和源码哈希清单。
- ASO 方案与观察方法见 [支付和海外 ASO 报告](ASO-2026-10-18/README.md)。关键词实际排名影响须在审核发布后观察。
