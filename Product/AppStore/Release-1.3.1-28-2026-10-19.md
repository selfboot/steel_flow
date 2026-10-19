# SteelFlow 1.3.1（28）上传记录

2026-10-19 · Asia/Shanghai

## 上传结果

- Apple 已确认 **VALID / APP_STORE_ELIGIBLE**，构建 `75031b6b-f9d3-40d5-baa7-f3cb15a92e03`。
- 已关联 1.3.1 草稿 `2cf0c050-54ae-499b-8496-19a7dc203ff9`，回读为 **PREPARE_FOR_SUBMISSION**，替代 build 27。
- 12 地区文案已同步并回读无待更新差异。
- 144 张新截图全部 **COMPLETE**，逐张与本地源文件比对 MD5、尺寸、文件名及顺序通过；旧截图已备份。
- **未提交 App Review，未改变 App 或 Pro 价格。** 线上仍为 1.3。

## 功能提交

- `dcfc071`：报价入口展示当前报价的品牌 PDF 示例；Pro 权益顺序按入口调整；权益变化时刷新报价；延后评分邀请。
- `81b9e6b`：墨西哥西语界面与 PDF、英国／澳洲／加拿大／墨西哥地区演示数据。
- `8cadad9`：美国截图改用 4 英寸 × 0.375 英寸、20 英尺的演示规格。
- `1982373`：构建版本升至 28。
- `8857996`：12 地区材料、免费额度、品牌报价与 PDF 描述纠错。
- `4be8598`：12 地区真实界面截图、编辑器项目、导出与验证脚本。
- `49c92e6`：测试证据、ASO 观察方法及数据边界。

此前 build 27 的支付加载修复、报价升级入口和设置页清理继续包含在此构建内。

## 验证与边界

120 项单元测试通过；iPhone 与 iPad 各 14 项界面测试通过，覆盖 12 地区截图、报价 Pro 浅色／深色和德语最大辅助字号；美国演示修正后两设备各重采 1 项测试通过。

Xcode IDE 启动的本地 StoreKit 完成购买，Apple 显示测试购买成功，随后 App 的 RevenueCat 权益更新为“已解锁 Pro”。这不是生产扣款或 TestFlight 购买证据。真机当前不可连接，真机购买和恢复仍未闭环。详见 [测试记录](ASO-2026-10-19/qa/test-results.json)。

Apple ONGOING 分析请求已启用。最初回读的下载与发现报告暂无实例，因此尚不能计算各地区曝光到下载的真实转化。新增 PostHog 匿名漏斗等待用户选择；本版没有新增行为采集，隐私声明保持一致。

最终 `asc validate --check-urls`：0 errors、0 warnings、0 blocking。另有 1 条信息提示：公共 API 无法核验 App Privacy 的发布状态，提交审核前需在后台确认；本次没有新增数据采集。

## IPA 与源码

- IPA：`Build/Release-1.3.1-28-20261019/export/SteelFlow.ipa`。
- 大小：11,037,937 字节。
- SHA-256：`6054accf85b7b00d8c2024adca646f4281c71120f416fa440c6b83ce42fbf3af`。
- 构建源码提交：`19823735238495c4f51f61f61d3ec276fa37be3c`。
- 严格签名校验通过，团队 `4Z5Z5TE9EX`，`get-task-allow=false`；正式 RevenueCat 配置与 9 种本地化资源通过校验。
- Archive、Export、altool 上传均成功。私有 `Build/Release-1.3.1-28-20261019/` 保存签名、上传、元数据、截图和 ASC 回读证据。

[完整优化说明](ASO-2026-10-19/README.md) · [12 地区素材预览](ASO-2026-10-19/index.html)
