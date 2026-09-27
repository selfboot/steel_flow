# SteelFlow 文章选题调研

日期：2026-09-10。目标：先做一篇中文功能使用指南，再扩展为问题驱动的系列。默认官网长文，兼顾公众号迁移；本次没有外部发布。

## 结论

首篇聚焦“钢材重量怎么算、怎样生成 PDF 报价单”。需求证据支持算重、计价单位、多规格汇总、报价依据这些具体任务；**尚不足以证明某个中文关键词有多大搜索量或能带来多少下载**。不要用“全能钢结构软件”“AI 识图算料”“实时钢价”吸引与产品不匹配的流量。

## 需求证据：区分用户、行业与厂商

| 类型 | 观察 | 对选题的意义 | 来源 |
|---|---|---|---|
| 用户讨论，2026-09-02 | 估算人员讨论钢结构按重量还是按长度计价，回复涉及吨位、米重转换 | 单位与计价依据是真实问题；是英文社区小样本，不能外推中国市场规模 | [Estimating cost weight/qty](https://www.reddit.com/r/estimators/comments/1w4zm0z/estimating_cost_weightqty/) |
| 用户讨论，2026-06-08 | 发帖者将手工估算整理成复杂表格，寻找适合自身工作流程的工具 | 文章应展示具体流程和数据可核对性，而非泛泛宣称取代 Excel | [Steel fab/erection estimators](https://www.reddit.com/r/estimators/comments/1u0l662/steel_faberection_estimators_what_is_the_software/) |
| 用户讨论，2026-04-22 | 询问钢板、HSS、梁、加工操作的估算软件；回复描述图纸计量与 Excel 工时核算分工 | 轻量材料报价和完整加工/施工估算不是同一任务；SteelFlow 不宜承诺自动算工时 | [Custom steel fabrication estimating](https://www.reddit.com/r/estimators/comments/1ssw50w/custom_steel_fabrication_estimating/) |
| 行业原始资料 | Mysteel 方法论明确区分理计价与过磅价及其转换 | “理论重量不是实际过磅重量”应成为 FAQ，而不是把两者混用 | [Mysteel 钢材价格指数方法论](https://a.mysteelcdn.com/common/mysteel/dataIndex/pdf/methods/gangcai.pdf) |
| 厂商自荐，不计作独立需求 | Steel & Metal Weight Calc 开发者推广项目、损耗、税费和 PDF 报价 | 说明竞品也在讲同一流程，PDF 不是独占卖点；帖子不能冒充用户访谈 | [开发者介绍帖](https://www.reddit.com/r/ShowYourApp/comments/1t9aufd/i_built_a_professional_metal_weight_quote_tool/) |

## 竞品有没有文章？有，至少有三种成熟做法

| 产品 / 关系 | 检查的页面 | 内容做法与可借鉴点 |
|---|---|---|
| Fabora Steel Tools，直接功能重叠 | [官方功能指南](https://www.faboraplatform.com/steel-tools) | 按工种和使用时机分组，配真实屏幕；包含重量、费用和 PDF 报价。可借鉴“什么时候用”，不能宣称 SteelFlow 独家支持 PDF。 |
| SteelFlo，相邻的钢结构图纸计量产品，与 SteelFlow 无关联 | [Free Steel Takeoff Template (Excel)](https://www.steelfloai.com/blog/free-steel-takeoff-template-excel)，页面标注 2026-08-28 | 用免费模板、步骤和算例承接长尾搜索，再解释模板边界。可借鉴先交付有用答案；不要照搬其 AI 识图定位、性能数字或文字。 |
| TrueAssistant，Excel 钢结构工具 | [官方中文使用说明](https://www.truetable.com/chs/products/TrueAssistant.html) | 围绕实际材料输入方式讲重量计算。说明中文用户也有表格工作流；重点讲如何核对参数，而非贬低表格。 |
| TradeCalc Studio，相邻施工计算 App | [User Guide](https://www.rgtsoftware.com/apps/tradecalc-studio/guide.html) | 按设置、项目、输出等任务写操作指南；可以借鉴把收费与导出条件解释清楚。 |
| 钢材快算，直接功能重叠 | [商店介绍](https://apps.apple.com/sn/app/id6793853007) | 强调材料清单、费用、报价图片等。本次只核实到商店介绍，不据此声称“没有独立文章”。 |

这里的“可借鉴”是编辑判断，不是已验证的竞品文章流量或转化表现。未取得对方搜索控制台数据。

## 首篇搜索策略

- 首要任务：在手机上算出钢材理论重量，再生成可发送的项目报价。
- 主词：钢材重量计算、钢材重量计算器。
- 自然相关词：钢板重量怎么算、钢材报价单、PDF 报价单、iPhone 钢材计算器。
- 不抢占的相邻意图：今日钢价、免费 Excel 模板下载、AI 图纸识别、排样下料、结构承载力。
- 标题：钢材重量怎么算、报价单怎么做？用 SteelFlow 从尺寸算到 PDF。
- 建议 slug：steel-weight-calculator-pdf-quote。
- 摘要：用一组钢板尺寸算出理论重量，再把多种规格汇总成项目，添加计价与费用，导出 PDF 报价单。附 SteelFlow 真实界面与示例文件。
- 页面提供语义 HTML 正文、图片 alt、可查看原图和 PDF 附件。不保证收录或排名。

## 系列规划：一篇回答一个问题

| 顺序 | 选题 | 搜索意图 | 需要补充的真实案例 |
|---|---|---|---|
| 1，本次完成 | 钢材重量怎么算、报价单怎么做？ | 总览与从计算到输出的完整路径 | 算重、项目、PDF 六屏 |
| 2 | 钢板重量怎么算？毫米、米与数量别填反 | 公式与单位 | 两组同体积尺寸、数量变化 |
| 3 | 圆管重量怎么算？外径与壁厚怎样输入 | 管材专门问题 | 圆管、实心圆钢对照，明示几何估算边界 |
| 4 | 钢材报价怎样计入损耗、加工费和运费？ | 成本构成 | 同一项目逐项加费前后结果 |
| 5 | 按公斤、按米、按件报价，怎么核对单价？ | 计价单位 | 同一规格的等价价格算例，不充当行情 |
| 6 | 客户改数量后，怎么保留前一版 PDF 报价？ | 改价与追溯 | 保存版本、修改项目、查看旧报价 |
| 7 | 常用规格总要重填？草稿、收藏与模板怎么选 | 重复操作 | 免费草稿收藏与 Pro 模板的实际区别 |

后续篇目未写完或发布前，不在正文放假内链。现阶段可内链真实产品页与支持页。

## 产品与截图核实

- 源码基线 `594d301`，版本 1.1.0（13）；2026-09-10 App Store Connect 返回 READY_FOR_SALE。
- 真实 SwiftUI 页面通过现有 DEBUG 营销入口运行，2026-09-10 于 iPhone 16 Pro / iOS 26.5 专用模拟器重拍；不是 AI UI 图。该入口直接展示页面，未包含主 Tab 外壳。
- 示例项目、客户名称及单价来自内置演示数据，不是真实客户交易或当前供应商报价。状态栏统一 9:41；界面内容未重绘。
- 免费限制从 ProPolicy 核实：2 个活跃项目、每项目 10 个条目；基础 PDF 可导出并含品牌标识。Pro 的 CSV、公司信息、去品牌等边界从实际代码核实。
- 查询包括中文重量/报价教程与英文 weight/quote/estimating 搜索；本次没有百度指数、Search Console、付费关键词量或中国客户访谈。建议发布后看真实查询与下载入口点击，再确定系列优先级；不要预设增长数值。
