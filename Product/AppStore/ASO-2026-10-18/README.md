# SteelFlow 支付修复与海外 ASO 优化

研究日期为 2026 年 10 月 18 日，Asia/Shanghai。2026 年 10 月 19 日已上传 1.3.1（27）构建，并将 12 套地区资料写入 App Store Connect 的 1.3.1 草稿；尚未提交审核，线上仍为 1.3。App 免费定价及 Pro 一次性购买价格均未修改。发布证据见 [发布记录](../Release-1.3.1-27-2026-10-19.md)。

建议先用稳定的购买链路承接已有下载，再扩大精准搜索覆盖。优先需求是金属加工、材料采购和钢材贸易中的“输入板材或管材尺寸 → 算理论重量与材料成本 → 输出客户报价”。公司品牌 PDF 是这条流程自然的 Pro 升级理由，单纯增加泛计算器流量未必增加购买。

## 支付与报价预览

`PurchaseManager.load()` 原先将商品目录与会员信息绑定为一次异步等待；会员查询失败会让已经返回的商品无法赋值，首次进入时表现为没有价格、按钮不可用。现在商品独立加载，会员信息由现有的 App 生命周期和 RevenueCat 更新流刷新。加载与购买／恢复分别维护状态；重复加载不会覆盖进行中的请求，取消不显示商店错误，暂时的刷新失败保留已加载商品。

报价预览顶部增加 Pro 入口，明确展示公司信息、Logo 和移除 SteelFlow PDF 标识的价值；保留免费 PDF 分享按钮，已购买用户不显示升级卡片。新增文案覆盖 8 种 App 语言。最大辅助字体下分享按钮改为随内容滚动，避免遮挡升级内容。

自定义付费页补充 RevenueCat 官方曝光事件，每次展示只记一次，以入口区分，例如 `steelflow.quote.pro.detail`。这能帮助观察哪些入口产生付费页访问，但还不是包含每次点击、取消与错误原因的完整漏斗；开发测试不会作为生产转化证据。[RevenueCat 文档](https://www.revenuecat.com/docs/getting-started/tracking-custom-paywall-impressions)

已有源码缺陷并不证明它造成了全部零购买。上一轮审计中，2026-09-17 至 2026-10-16 共 38 次首次下载；日本 4、法国 3、韩国 2，德国、台湾、西班牙、印度各 1。样本仍小，需要新版上线后的曝光与购买数据才能区分购买意愿不足和交易故障。

## 验证结果

20 项 iPhone 定向回归通过，覆盖商品失败重试、取消、重复加载、语言键一致性、免费分享、Pro 用户隐藏入口、最大辅助字体和 StoreKit 购买确认／取消。iPad 同一升级流程另行通过，并检查实际明暗截图。加载进度动画仅做代码检查；未完成真机购买／恢复和小尺寸 iPhone 的独立视觉验证。

[浅色预览](qa/ipad-quote-pro-entry-light.png) · [深色预览](qa/ipad-quote-pro-entry-dark.png)

## 海外关键词基线

本次覆盖 US、GB、CA、AU、IN、JP、KR、DE、FR、ES、MX、TW、VN、TR 共 14 个商店地区，完成 46 次 Apple 搜索和 49 次 KWTrack 查询。下表数字是 **Apple Search API 返回顺序，不是手机 App Store 实测自然排名**；“未返回”只指本次结果集。KWTrack 热度／难度是第三方估算，不代表 Apple 官方搜索量。

| 地区 | 精准搜索词 | API 顺序 | 热度／难度估算 | 本次调整 |
|---|---|---:|---:|---|
| 日本 | 金属重量計算 | 6 | 44／16 | 保留当前主标题；补充板金，覆盖板材算重 |
| 日本 | 板金重量計算 | 未返回 | 20／8 | 关键词新增板金；不宣传未实现的折弯展开功能 |
| 韩国 | 금속 중량 계산기 | 6 | 44／20 | 保留主词；补充 판재，结合铁板、钢管、圆棒 |
| 台湾 | 金屬重量計算器 | 5 | 45／15 | 保留主词，关键词补充鋼材 |
| 台湾 | 鋼材重量計算 | 未返回 | 19／5 | 补足钢材检索表达 |
| 德国 | Metallrechner | 4 | 31／14 | 保留标题；强化 Metallgewicht、Blechgewicht 等材料词 |
| 法国 | poids métaux | 3 | 21／15 | 保留标题；补充 calculateur，减少泛密度／质量词 |
| 西班牙 | calculadora metales | 3 | 21／11 | 副标题改为 Calculadora acero y tubos |
| 西班牙 | calculadora peso metal | 未返回 | 31／15 | 用明确的计算器表达连接现有金属重量标题 |
| 墨西哥 | calculadora peso metal | 未返回 | 30／15 | 新增 es-MX，以 placa、lámina、costo、cotización 区分地区用语 |
| 美国 | metal weight calculator | 44 | 55／30 | 标题突出 Metal Weight，副标题保留 Steel Calculator |
| 美国 | steel weight calculator | 31 | 28／23 | 保留钢材意图；材料长尾继续覆盖 pipe、tube、plate、sheet |
| 美国 | metal cost calculator | 15 | 24／10 | 关键词保留 cost，PDF Quotes 继续表达付费输出价值 |
| 英国 | metal weight calculator | 未返回 | 50／27 | 新增 en-GB，使用 aluminium 等本地拼写 |
| 加拿大 | metal weight calculator | 未返回 | 52／21 | 新增 en-CA |
| 澳大利亚 | metal weight calculator | 未返回 | 50／22 | 新增 en-AU |
| 印度 | metal weight calculator | 63 | 56／29 | 用 en-GB 承接英语检索，优先可靠算重和材料列表体验 |

完整逐词数据见 [关键词基线](../Research/2026-10-18-international/keyword-baseline.json)，包含采样时间与实际返回条数。Apple 官方地区表分别列有英、美、澳、加拿大英语，印度默认英语为英国英语；墨西哥及多个拉美市场使用墨西哥西语。新增地区资料提供针对性的展示与关键词配置机会，但不能据此断言原来的搜索缺失一定由地区资料造成。[Apple 地区语言表](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)

## 精准需求与排除项

印度的 `Weight calculator for metals` 有 1,892 个评分，`Metal Weight Calculator App` 有 1,622 个评分；这证明同类工具在当地存在使用需求，不等于下载量或付费规模。在前者最近的 20 条评论样本中，多次出现材料选择列表不可见、暗色界面黑屏和购买后仍无法使用的抱怨，最近相关评论延续到 2026 年。这支持“可靠的材料选择与现场算重”作为卖点，不能直接推出用户会为 PDF 报价付款。[竞品页面](https://apps.apple.com/in/app/id1442079573)、[评论样本](../Research/2026-10-18-international/apple-reviews.json)

德国金属供应商 Kloeckner 提供板材重量计算工具，说明按板材尺寸和材料计算重量是实际业务任务。美国同一供应商也提供金属计算器；免费网页替代品意味着 App 的付费价值更应落在项目明细、客户交付和品牌报价，而不是仅有公式。[德国板材计算工具](https://facts.kloeckner.de/tools/blech-gewicht-berechnen/)、[美国金属计算工具](https://www.kloecknermetals.com/metal-calculator/)

本轮不主推这些词：

- 德语 `Gewichtsrechner`：前列主要是 BMI、体重管理；没有把它加入最终关键词。
- 法语 `poids tube`、西语 `peso tubo`：搜索结果大量偏向健身、VPN 等不相关产品。
- 印度 `steel calculator`：热度估算高，但结果混入普通计算器、钢筋 BBS；不能把未实现的钢筋下料表作为卖点。
- 越南语、土耳其语：有同类产品，但本轮自然长词的量级信号弱，App 也尚无对应语言。先完善已有语言市场，不追加两套完整翻译。

## 下一版商店资料

权威源为 [metadata.json](../Metadata/metadata.json)，可上传的逐语言文本在 [metadata](metadata)。新增 en-GB、en-AU、en-CA、es-MX，合计 12 套商店地区资料，App 本身仍为 8 种语言。简体中文的标题、副标题和关键词保留，只更新版本说明。

英文标题改为 `SteelFlow: Metal Weight`，副标题为 `Steel Calculator & PDF Quotes`。西语副标题改为 `Calculadora acero y tubos`。日、韩、德、法、繁中保留已有核心标题，做具体材料词补充。完整前后差异见 [metadata-diff.json](metadata-diff.json)。

所有标题和副标题不超过 30 字符；关键词同时满足 100 字符与更保守的 100 UTF-8 字节预算；推广文案不超过 170 字符。关键词字段不含竞品品牌、无关热词或价格。Apple 明确说明推广文案不影响搜索排名，因此此次索引调整集中在标题、副标题和关键词。[Apple 产品页指南](https://developer.apple.com/app-store/product-page/)

运行 `python3 Product/AppStore/ASO-2026-10-18/validate_metadata.py` 可核对限制及导出文本与权威源的一致性。发布时新增地区应沿用对应语言的现有截图，并核对默认展示语言；不要上传包含 Markdown 标题的描述源文件，应使用导出的 `description.txt`。

## 发布后的判断标准

1.3.1 构建和商店资料已上传，尚未提交审核。发布前需要在真机 TestFlight／沙盒完成一次购买、权益解锁及恢复闭环；当前验证包含本地 StoreKit 商品加载、调起系统购买确认和取消，不等同于生产交易成功。

上线后以同一商店、同一关键词、同一采样方式比较第 7、14、28 天的数据。先看新增精准词是否进入结果集，再看各地区搜索来源的首次下载，最后看付费页曝光与生产购买。不要把 API 顺序的单日波动当作增长，也不要用所有下载直接推断付费页转化。

对于没有足够曝光的地区，先改商店转化和入口触达；已有曝光却没有购买时，检查实际交易错误及用户对品牌 PDF 的需求。至少积累一批真实付费页访问再作定价实验，当前保持价格不变。
