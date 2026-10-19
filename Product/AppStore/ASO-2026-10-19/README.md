# SteelFlow ASO 转化改进 · 2026-10-19

范围：沿用 1.3.1 草稿的 12 个地区，价格不变。素材和文案围绕金属加工、材料采购、钢材贸易中的“尺寸 → 重量 → 项目成本 → 客户品牌报价”。更新草稿不等于审核通过或上线，最终上传状态见 [1.3.1（28）发布记录](../Release-1.3.1-28-2026-10-19.md)：Apple VALID、已关联草稿，144 张截图已 COMPLETE 且与本地逐张比对通过。

## 已落实的产品改进

- 报价、公司资料、CSV 入口的 Pro 页面先解释品牌交付价值；按入口调整权益顺序。报价入口显示由真实 PDF 渲染器生成的当前报价 Pro 样张，标明示例公司，样张不保存、不提供免费导出。免费报价仍能正常分享。
- Pro 权限变化时重新生成报价文件，清除旧 PDF/CSV，避免继续使用不符合当前权限的旧预览。
- 首次计算不再触发评分邀请。需在三个不同日期完成有效计算，或实际成功分享 PDF；编辑、反复打开页面、取消分享不累加成功。保留同版本一次和 90 天间隔，不根据用户满意程度筛选。
- 新增墨西哥西语界面和 PDF 用语，使用 cotización/costo；地区演示币种为 GBP、AUD、CAD、MXN。美国展示英制，其他地区保持公制。演示单价不是实时汇率或行情。

## 商店转化与关键词

前 3 张保持重量、成本、报价顺序。第 3 张改成可辨认的完整品牌 PDF：公司 Logo、客户、明细、总额，并明确标记 Pro；文案强调耗损、加工费、利润与税费，避免仅重复竞品已有的算重功能。

保留已准备的标题、副标题与关键词基线，不以单次 API 波动反复改名。美国优先观察 metal cost calculator，日本优先观察 鋼材重量計算；保留 metal weight 等核心需求，不把 HVAC 展开意图的 sheet metal calculator 或低量的 blechgewicht 当主攻方向。

推广文案和描述用于解释价值、改善转化，不把它们当新增索引词。修正了内置材料包含钛的错误表述、免费额度不清晰、PDF 备注输出表述以及墨西哥描述残留的西班牙用词和语法错误。12 地区标题、关键词等长度与重复校验通过。

权威文案为 `../Metadata/metadata.json` 和对应 Markdown；本目录 `metadata/` 为纯文本导出。运行 `python3 Product/AppStore/ASO-2026-10-19/validate_metadata.py` 校验。

## 截图复现

沿用 `../ScreenshotsEditor/`，没有更换模板或另造截图渲染器。`editor-project.json` 保存项目配置，`previous-editor-project.json` 保存旧配置。DEBUG 真实页面由 `UITests/SteelFlowUITests.swift` 的 12 个 CaptureMarketingScreens 测试采集。

`import_captures.py <iphone|ipad> <xcresult 导出目录>` 将真实截图导入 `ScreenshotsEditor/public/screenshots/aso-20261019/`。`export_editor.cjs <iphone|ipad>` 通过已有编辑器的 Export bundle 按钮调用 html-to-image；PW_MODULE 可指定本地 Playwright 包。主上传尺寸为 iPhone 1320×2868、iPad 2064×2752，按 01–06 排序。Git 保存这 144 张主尺寸和 144 张原始界面；其他尺寸保存在本地导出包，可用编辑器重新生成。`validate_assets.py --normalize-rgb` 检查完整导出的 432 张，只有完全不透明的 alpha 才可去除。克隆仓库后，可用 `validate_assets.py --primary-only` 检查已提交的主尺寸。

## 数据与验证边界

Apple 持续分析 ONGOING 请求已创建并回读确认 active；首次检查已有报告目录，但 App Downloads 和 App Store Discovery and Engagement 均为 0 个数据实例。报表生成前不计算地区曝光到下载的转化。

新增匿名付费漏斗的 PostHog 独立项目方案等待用户回复。当前 RevenueCat 付费页曝光不等于完整的购买点击、取消、失败和解锁漏斗。未接入前不能宣称这项已完成。

120 项单元测试、iPhone 14 项和 iPad 14 项界面测试通过；美国英制演示修正后，两种设备各重采 1 项测试通过。已检查全部 24 组截图的排版和前 3 张缩略图。

通过 Xcode IDE Run 成功完成本地 StoreKit 测试购买，观察到 Apple 成功提示，随后 RevenueCat 权益使 App 显示“已解锁 Pro”。命令行启动的本地 StoreKit 曾发生环境错误，不据此认定生产支付故障。恢复购买及真机 TestFlight 仍未闭环，当前真机不可连接；本地 StoreKit 与 TestFlight/生产交易须区分记录。测试环境的交易、匿名客户不能充作真实购买和下载转化。

## 观察方法

新版真正发布后，以同一商店、同一关键词和同一采样方式对比第 7、14、28 天：曝光、产品页访问、首次下载、付费页曝光、购买及 Pro 解锁。搜索来源单独统计，区分首次下载/重新下载、生产/测试。小样本不同时开展多个截图实验；先积累足够曝光，再一次测试一个主要信息。

Apple Search API 返回顺序不等于手机 App Store 实测自然排名。当前基线：美国 metal weight calculator 43/91、metal cost calculator 16/93、日本 鋼材重量計算 7/19；这些是 2026-10-19 API 样本，不承诺排名提升。第三方热度是估算，不能当 Apple 搜索量。

参考：[Apple 搜索](https://developer.apple.com/app-store/search/)、[产品页](https://developer.apple.com/app-store/product-page/)、[分析指标口径](https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions)、[RevenueCat 测试环境](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store)。
