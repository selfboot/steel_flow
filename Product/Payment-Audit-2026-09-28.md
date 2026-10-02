# SteelFlow 支付与免费权限核查

日期：2026-09-28。核查当前源码、已上传的 1.3 (26) 签名包以及 Apple / RevenueCat 线上配置。本次不修改生产配置或 App 实现，也不撤回已提交的审核。

## 结论

商品和权益配置一致，加载商品、发起系统购买和取消购买可用。但尚未完成 Apple 交易及成功恢复购买，不能据此承诺正式支付全链路已经通过。

- Apple 商品 `com.steelflow.app.pro.lifetime`，ID `6806295366`，类型 `NON_CONSUMABLE`，状态 `APPROVED`，一次性永久解锁；未开放家庭共享。
- 开售地区 175 个，包含中国大陆、香港、台湾、日本、韩国、德国、西班牙、法国、美国；新地区自动开放。
- 当前手动售价：中国大陆 CNY 58，美国 USD 14.99。App 展示 StoreKit 返回的当地价格，不随 App 语言或报价货币设置改价。
- RevenueCat 项目 `proj067b46b3` / 正式 App `appb973e264d7`，Bundle ID 匹配 `com.steelflow.app`。
- 当前 Offering `default` → `$rc_lifetime` → 正式 Apple 商品，且该商品绑定 `pro` 权益。Test Store 的同名商品是另一 App 下的独立记录，没有混用。
- 1.3 (26) 签名包使用与正式 RevenueCat App 一致的 Apple SDK 公钥，权益名为 `pro`。仅比较结果，不输出或保存密钥。
- RevenueCat 显示 subscription key 已配置，App Store Connect API key 未配置；后者不等同于商品不可购买，本次已直接通过 Apple API 核查商品状态。

## 测试及明确的未验证项

`Build/PaymentAudit-20260928/Baseline.xcresult`：9 项通过，包括 7 项 ReliabilityTests 和 2 项支付 UI 测试。后两项验证商品价格加载、购买按钮可用、系统弹窗和取消流程；不是完成交易的证据。

`Build/PaymentAudit-20260928/PDFPermissions.xcresult`：另 2 项 PDF 测试通过，验证免费/Pro 标识差异、内部成本隐藏，以及各语言下有无公司资料时 Pro PDF 都不显示 SteelFlow 标识。合计 11 项已有测试通过；不包括下面未完成的完整购买诊断。

另外尝试了不使用 `--workflow-tests` 模拟 Pro 的完整购买诊断：`CompletedPurchase.xcresult`。45 秒内未解锁，录像证实停在系统“登录 Apple 账户”弹窗，没有完成交易或扣款。虽然测试创建了 SKTestSession，日志出现 `Error deleting all transactions: SKInternalErrorDomain Code=3`，本次环境没有成功进入无需账户的本地 StoreKit 成交路径。

诊断测试摘录保存在 `Build/PaymentAudit-20260928/CompletedPurchaseDiagnostic.swift.txt`，未把依赖 Apple 登录的失败诊断加入常规测试套件。截图 `purchase-screen.png` 和录像均在同目录。

尚需真机 TestFlight / Apple Sandbox 验证：完成购买 → RevenueCat `pro` 激活 → 自动打开受限功能；同一 Apple 账户重新安装/换设备后的恢复购买；待批准交易和退款后权限更新。TestFlight 购买属于沙盒，不应以正式 App Store 扣款替代测试。

参考：[RevenueCat Apple 沙盒测试说明](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store)。

## 免费版实际边界

| 功能 | 非 Pro | Pro |
| --- | --- | --- |
| 基础计算、内置材料、单位/货币/语言、3D 预览 | 可用 | 可用 |
| 未归档项目 | 最多 2 个；归档释放名额，恢复归档也检查额度 | 无此数量限制 |
| 每项目明细 | 最多 10 条；新增和复制单条均检查 | 无此数量限制 |
| 整项目复制、模板保存/复用、历史报价复制修订 | 需要升级 | 可用 |
| 单项报价编辑、客户管理、价格记录 | 可用 | 可用 |
| 批量调价 | 需要升级 | 可用 |
| 新增/复制自定义材料 | 需要升级 | 可用 |
| PDF 预览、导出、保存历史版本 | 可用，保留 SteelFlow 标识 | 去除 SteelFlow 标识 |
| 7 套 PDF 样式、默认样式、纸张尺寸 | 可用 | 可用 |
| 公司资料与 Logo | 需要升级，免费生成的报价不带公司资料 | 可用 |
| CSV 导出：客户、采购、切割、内部成本 | 需要升级 | 可用 |
| 备份导出及导入恢复 | 需要升级 | 可用 |

已有数据不会因 Pro 失效而删除或强行裁剪；超额项目、明细仍可查看编辑。已有自定义材料也仍可使用、编辑或删除，新建/复制才检查 Pro。已有历史 PDF 保持原快照的公司资料/品牌状态，不被追溯改写。

依据：`PurchaseManager.swift:195`；`ProjectsView.swift`、`ProjectDetailView.swift`、`CalculatorEditorView.swift`、`CustomersAndTemplates.swift`、`MaterialsView.swift`、`SettingsView.swift`、`QuotePreviewView.swift` 和 `QuoteHistoryView.swift` 中的实际入口及保存检查。

## 发现的问题

1. **P2：当前报价预览不处理 Pro 撤销。** `QuotePreviewView.swift:99` 仅在 `isPro` 变为 true 时清空/重建快照。如果用户在 Pro 时打开预览，后台权益被撤销并同步为 false，当前快照和 PDF 仍保留公司资料且无 SteelFlow 标识，用户还可改样式、保存及分享。CSV 入口会隐藏，所以不能把它描述成撤销后 CSV 按钮仍可用。建议在两个方向的权限变化时都使当前未保存预览失效并重新生成；已有历史文件是否保留另按产品规则处理。
2. **支付测试覆盖缺口。** 现有支付 UI 测试只覆盖展示和取消，没有证据覆盖 Apple 成交、权益解锁及成功恢复。本次实际尝试因 Apple 账户登录未完成，不能算测试通过，也不能直接归因为线上支付失败。

证据目录：`Build/PaymentAudit-20260928/`，包含 Apple 状态/地区/价格及 RevenueCat 配置的只读快照。
