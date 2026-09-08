# SteelFlow ASO 与竞品调研

调研时间：2026-08-28，2026-08-29 复核（Asia/Shanghai）

范围：中国大陆、美国；交叉验证英国、加拿大、澳大利亚。榜单均为 App Store 搜索结果快照，不是收入榜，排名会随时间、设备和个性化发生变化。英文关键词量级来自 KWTrack 第三方估算，不是 Apple 官方搜索量；中国大陆关键词无可用的 KWTrack 数据，因此只用 Apple 搜索结果与竞品存量判断。

## 结论

SteelFlow 值得继续，但不能只定位成另一个“钢材重量计算器”。更有机会的定位是：

`尺寸与材料 -> 可核对的重量/成本 -> 项目汇总 -> PDF 报价单与 CSV 清单 -> Pro 一次买断`

中国区应抢占精确词“钢材重量计算器”，用副标题表达“成本 + 报价清单”；英文区应把流量更大的 “metal calculator” 放在标题，把 “weight” 放在副标题组成完整意图。首屏不要强调型材数量，而要强调结果：“从尺寸到报价单 / From dimensions to a quote.”

综合评分：**3.75 / 5，Tier B，信心 B**。

| 维度 | 分数 | 判断 |
|---|---:|---|
| 真实需求 | 4/5 | 中美均有稳定精确搜索结果，英文核心词跨英、美、加、澳重复出现。 |
| 付费意愿 | 3/5 | 中国区存在 ¥28、¥38、¥58 的付费产品；英文区以免费+广告/订阅为主，专业报价闭环仍需验证。 |
| 获客便利 | 4/5 | “钢材重量计算器”“metal calculator”“metal weight calculator”意图明确，功能演示直观。 |
| 竞品缺口 | 3/5 | 老产品体验和维护问题明显，但 2026 年已出现与 SteelFlow 极接近的新竞品。 |
| 实现可行 | 5/5 | 客户端离线架构成熟，SteelFlow 已有可运行实现和自动化测试。 |
| 重复使用 | 4/5 | 加工、采购、报价是周频乃至日频工作，项目与价格数据具有沉淀价值。 |
| 合规安全 | 4/5 | 普通工具类风险；需保持理论重量免责声明、隐私政策和买断恢复可靠。 |

最大不确定性不是技术，而是用户是否愿意为“完整报价工作流”支付 ¥58 / US$14.99，而不是满足于免费单次算重。

## 关键词判断

### 美国英语

| 关键词 | KWTrack 热度 | 难度 | 机会 | 估算日搜索 | 结论 |
|---|---:|---:|---:|---:|---|
| metal calculator | 59 | 22 | 54 | 378 | 流量最大，适合标题核心词，但需用 subtitle 限定金属算重，避免泛流量。 |
| metal weight calculator | 51 | 31 | 46 | 218 | 最准确的核心意图；标题+副标题组合覆盖。 |
| fabrication calculator | 44 | 21 | 44 | 130 | 较好的次级获客词，适合关键词栏、内容页与广告组。 |
| steel weight calculator | 34 | 26 | 35 | 51 | 高意图钢材长尾，适合关键词栏和自定义产品页。 |
| pipe weight calculator | 15 | 17 | 16 | 5 | 搜索量小但转化意图强，作为长尾，不占标题。 |

建议优先级：`metal calculator` > `metal weight calculator` > `steel weight calculator` > `fabrication calculator` > `pipe/tube weight calculator`。

#### 2026-08-29 Apple 实时结果复核

使用 Apple iTunes Search API 的前 10 个结果，按结果相关性、已积累评分数和近两年更新比例做了可重复的竞争快照。这是竞争强度启发式评分，**不是 Apple 搜索量或官方难度**；搜索量仍以上表 KWTrack 估算为参考。

| 关键词 | 结果数 | 前 10 相关 | 已成熟（≥50 评分） | 近两年更新 | 启发式竞争分 | 判断 |
|---|---:|---:|---:|---:|---:|---|
| metal calculator | 45 | 10 | 3 | 7 | 90 | 高竞争，但流量与标题覆盖价值最高 |
| metal weight calculator | 46 | 9 | 3 | 6 | 83 | 高竞争、意图最准，由标题+副标题组合覆盖 |
| steel weight calculator | 45 | 8 | 4 | 7 | 86 | 高竞争长尾，放关键词栏 |
| fabrication calculator | 48 | 7 | 4 | 9 | 89 | 结果活跃但意图偏宽，不占标题 |
| pipe weight calculator | 47 | 5 | 4 | 6 | 69 | 中高竞争、小流量高意图长尾 |

### 中国大陆简体中文

中国大陆没有可用的第三方量级，以下根据 2026-08-28 Apple 搜索结果的相关性与成熟竞品数量排序：

1. **钢材重量计算器**：最准确，首屏结果高度相关，必须进入标题。
2. **钢材计算器**：更宽泛，相关结果仍集中，标题已有“钢材+计算器”可组合覆盖。
3. **材料重量计算器**：能覆盖铝、铜、不锈钢用户，适合描述和后续 A/B 测试。
4. **算料**：建筑/加工语境强，但会混入建工计算器，放关键词栏。
5. **钢材报价**：流量意图混杂，前排主要是行情资讯、期货和指数 App，不宜作为标题主词；用“PDF 报价清单”强调本 App 是制作报价，不是查市场行情。

2026-08-29 同样的 Apple 前 10 结果启发式复核中，“钢材重量计算器”、“钢材计算器”、“材料重量计算器”、“金属重量计算器”与“算料”的竞争分分别为 86、95、85、82、97，均属高竞争。“钢材报价”虽为 85，但前 10 仅 1 个结果与制作报价单相关，再次证明它不适合作首发核心词。

## 竞品矩阵

### 中国大陆

| 竞品 | 搜索位置与价格 | 评分 / 更新 | 已覆盖 | SteelFlow 可赢的位置 |
|---|---|---|---|---|
| [材料重量计算器](https://apps.apple.com/cn/app/id6742086859) | “钢材重量计算器”第 1；免费 | 2.0 / 4；2026-08-03 | 常见型材、价格、历史 | 评分弱；项目报价、导出、双语、可核对公式与稳定性。 |
| [钢材重量计算器](https://apps.apple.com/cn/app/id533094372) | 精确词第 3；¥58 | 3.63 / 63；2026-05-08 | 国标规格、算重、价格、历史、清单/库存 | 低分评论集中在付费恢复、更新后不可用、旧行情与崩溃；SteelFlow 应把恢复购买、离线权益与免责声明做成信任点。 |
| [钢材清单-构件重量统计](https://apps.apple.com/cn/app/id1297108312) | 精确词第 12；免费+限制 | 4.04 / 26；2024-08-13 | 29 种钢材、报价、CSV、iCloud | 有工作流但界面/更新较旧；SteelFlow 的 PDF 报价、价格来源、双语与现代 iPad 体验更完整。 |
| [钢材重量计算助手](https://apps.apple.com/cn/app/id6778304774) | “钢材计算器”第 13；¥38 | 0 / 0；2026-06-11 | 21 种钢材、价格、历史、清单、离线 | 新品但无评分，未突出 PDF/CSV、公司资料、复杂费用与英制。 |
| [钢材重量计算器-报价清单](https://apps.apple.com/cn/app/id6779890043) | “钢材报价”第 12；¥28 | 0 / 0；2026-06-17 | 项目、重量、损耗、税费、PDF/CSV、备份、中英文、离线 | **最接近且是最大风险。** SteelFlow 必须用免费入口、验证过的计算、价格可追溯、报价快照、iPad 与更强品牌质量拉开差距。 |

“钢材报价”本身不应当作精确产品词：该查询前两名是[我的钢铁](https://apps.apple.com/cn/app/id381230745)和[卓创资讯](https://apps.apple.com/cn/app/id1464624925)，用户更可能在找市场行情而不是制作报价单。

### 美国及英语市场

| 竞品 | 美国搜索位置 | 评分 / 更新 | 已覆盖 | SteelFlow 可赢的位置 |
|---|---|---|---|---|
| [Steel Weight Calculator App](https://apps.apple.com/us/app/id6456941823) | steel weight 第 1 | 4.72 / 61；2024-05-02 | 多型材、kg/lb、即时结果 | 更新较旧，版本说明为去广告订阅；没有项目、复杂成本和正式报价交付。 |
| [Metal Weight Calculator App](https://apps.apple.com/us/app/id6455635445) | metal weight 第 1 | 4.63 / 152；2024-05-01 | 多单位、材料密度、多型材、数量 | 仍是单次计算器，版本说明为去广告订阅；SteelFlow 以无广告+一次买断和项目报价区分。 |
| [Metal Weight Calculator Pro](https://apps.apple.com/us/app/id6749879113) | metal weight 第 2 | 4.63 / 19；2026-02-18 | 多材料/型材、公英制、保存与分享 | 活跃新品但评价量小；没有完整费用、报价模板、PDF/CSV 和客户交付闭环。 |
| [Weight calculator for metals](https://apps.apple.com/us/app/id1442079573) | metal weight 第 5 | 4.13 / 262；2022-12-14 | 重量/长度/价格、多材料、自定义材料 | 低分评论反复提到英制/默认单位、键盘遮挡、滚动、广告和计算可信度；SteelFlow 应强调可核对公式、单位记忆和无广告。 |
| [steelyard](https://apps.apple.com/us/app/id1291109620) | steel weight 第 9、metal weight 第 8 | 4.71 / 297；2026-07-01 | 质量与成本、公英制、历史、离线、车间 UI | 当前最强英文功能竞品；没有客户/公司资料、项目级费用、PDF 报价与 CSV 物料表。旧低分评论曾明确要求付费去广告。 |

跨区验证：`metal weight calculator` 在英国、加拿大、澳大利亚的前五名仍反复由 Metal Weight Calculator Pro、MWC、Weight calculator for metals 与 Metal Weight Calculator App 占据，说明不是美国单区偶然词，但这些区的评分量明显更少。

## 推荐 Metadata

| 字段 | 简体中文 | English (U.S.) |
|---|---|---|
| 标题 | SteelFlow 钢材重量计算器 | SteelFlow: Metal Calculator |
| 副标题 | 成本、损耗与PDF报价清单 | Weight, Cost & PDF Quotes |
| 主类目 | 工具 | Utilities |
| 次类目 | 商务 | Business |
| 定价 | 免费下载 + Pro 永久版 ¥58 标准价 | Free + Pro Lifetime US$14.99 standard |
| 首屏主张 | 从尺寸到报价单。 | From dimensions to a quote. |

标题分别为 17 和 27 个字符，副标题分别为 13 和 25 个字符，均不超过 Apple 的 30 字符限制。关键词栏分别为 97 与 96 UTF-8 bytes，不超过 100 bytes。完整可复制字段见 `Metadata/metadata.json`。

英文标题备选 A/B：

- A（首发）：`SteelFlow: Metal Calculator` + `Weight, Cost & PDF Quotes`，优先覆盖更大词 metal calculator。
- B：`SteelFlow: Weight Calculator` + `Metal Cost & PDF Quotes`，精确度略高，但 title 里的 Weight Calculator 可能引入人体体重类泛流量。

中国标题不建议首发时 A/B，先守住精确词“钢材重量计算器”；有足够曝光后再测试副标题“型材算重与PDF报价单”。

## 定价与商业化

建议保持当前“免费基础版 + Pro 一次买断”架构：

- 中国大陆标准价：¥58；可用 30–45 天 ¥38 首发窗口，积累评价后恢复标准价。
- 美国标准价：US$14.99；可用 30–45 天 US$9.99 首发窗口，验证专业用户转化后再考虑测试 US$19.99。
- 免费版必须完成一次真实算重，并允许建立有限项目；不要在用户看到准确结果前弹付费墙。
- Pro 的付费结果要写成“无限项目 + 自定义报价 + 完整 PDF/CSV + 备份”，不要只写“更多型材”。
- 不放广告。英文头部竞品的低分评论已经证明，车间工具中的广告会破坏核心任务。

## 截图策略

六页顺序已经写入 `ScreenshotsEditor/app-store-screenshots.json`：

1. 从尺寸到报价单 / From dimensions to a quote.
2. 输入尺寸，即刻算重。
3. 损耗、费用、税费与利润。
4. 项目级材料汇总。
5. PDF 报价与 CSV 清单。
6. 离线可用、无需账号。

当前已有中英文各 6 张真实 App 界面，分别覆盖首页、计算详情、定价、项目汇总、报价预览和材料库，并已导出四组 iPhone 尺寸。提交前仍需从当前最新构建重新拍摄与逐张校验，确保数量直接输入、长度输入优化与项目删除等最新交互与上架包一致。

## 两周验证计划

1. 用当前中英文首屏和价格页做一个关键词落地页，分别投放 `钢材重量计算器`、`metal weight calculator` 两组小额搜索广告。
2. 找 5 位钢构加工、机械加工、采购或五金销售用户，让他们用现有方法和 SteelFlow 完成同一份三项材料报价。
3. 分开记录“看到价格页”“选择 ¥58/US$14.99”“TestFlight 申请”“实际导出 PDF”四层信号。
4. 推进标准：至少 3/5 用户能在无需解释下完成报价；至少 2/5 明确接受目标价格；落地页到 TestFlight 申请转化达到 8%。
5. 停止或改定位：用户只需要单次重量、普遍拒绝项目报价价值，或最接近竞品已在价格/质量上建立明显优势。

## Apple 提交规则核对

[Apple 当前规定](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) App 名称与副标题分别最多 30 字符，宣传文本最多 170 字符，描述最多 4000 字符，关键词最多 100 bytes；iOS 还必须提供[隐私政策 URL](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)。[截图要求](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)为每个设备/语言至少 1 张、最多 10 张。提交前必须替换 metadata 中的支持、营销与隐私 URL 占位符。
