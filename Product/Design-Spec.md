# SteelFlow 整体设计规范 / Product Design Specification

| 字段 | 内容 |
|---|---|
| 版本 | 0.1 |
| 日期 | 2026-08-28 |
| 设备 | iPhone first，iPad adaptive |
| 语言 | 简体中文、English |
| 主题 | Light、Dark、跟随系统 |

## 1. 设计方向

SteelFlow 的视觉不模拟生锈钢板、警示条纹或工业仪表盘。它应该像一把高质量测量工具：克制、清楚、可信、戴手套也能快速辨认。

### 设计原则

1. **结果先行，但不隐藏依据。** 总重量和总价最醒目，公式、密度、单位和警告一步可见。
2. **现场可读。** 大数字、短标签、稳定布局、足够触控面积；不依靠浅灰小字。
3. **输入与单位不可分。** 单位永远贴近数值，单位切换不会藏在全局设置里。
4. **专业但不过度。** 默认只显示完成当前任务所需字段，高级参数渐进展开。
5. **中英文同构。** 不把英文界面当中文翻译的残余，也不为中文做另一套信息架构。
6. **错误优先于漂亮。** 无效几何、单位歧义和材料异常必须阻止或显著警告。

## 2. 品牌与命名

### 工作名

- English: **SteelFlow**
- 中文显示名：**钢流**
- App Store 副标题候选：
  - 中文：`钢材算重、成本与报价`
  - English: `Metal Weight & Quote Calculator`

名称尚未做商标和商店重名检查，进入开发前需验证。

### 品牌语气

- 准确，不夸张：使用“估算 / Estimate”“理论重量 / Theoretical mass”，不使用“绝对精准”。
- 直接，不卖弄：按钮用动词，如“保存到项目 / Add to project”。
- 对专业边界诚实：明确密度、圆角忽略、标准表来源和复核要求。

## 3. 视觉系统

### 3.1 色彩角色

使用语义角色，不在业务代码中直接使用十六进制颜色。

| 角色 | Light 概念 | Dark 概念 | 用途 |
|---|---|---|---|
| Canvas | 冷白 | 深石墨 | 页面背景 |
| Surface | 白/浅灰 | 提升一级的石墨 | 输入组、结果组、Sheet |
| Primary text | 近黑蓝灰 | 近白 | 标题、值、核心说明 |
| Secondary text | 中灰 | 浅灰 | 单位、上下文、来源 |
| Steel blue | 中深蓝 | 明亮蓝 | 主动作、选中状态、链接 |
| Safety amber | 暖琥珀 | 高可见琥珀 | 警告、需复核，不代表错误 |
| Error red | 系统红 | 系统红 | 阻止性错误 |
| Success green | 系统绿 | 系统绿 | 已保存、验证通过 |

颜色不能单独表达状态；警告和错误必须有图标与文本。

### 3.2 字体

- UI：SF Pro / system font。
- 数值：系统 rounded 或 monospaced digits；对齐表格使用 `.monospacedDigit()`。
- 代码/公式/内部单位：SF Mono，仅用于短行。
- 禁止压缩字体来容纳英文；应换行或调整布局。

### 3.3 间距与形状

- 以 4pt 网格为基础，主间距 8/12/16/24/32。
- 输入和按钮最小高度 44pt，车间关键按钮建议 50–56pt。
- 圆角克制：输入 10–12pt，结果卡 16pt，底部 Sheet 20pt。
- 列表主要靠留白和细分隔线，不用每行卡片。

### 3.4 图标

- App 内使用 SF Symbols，线宽随文本。
- 型材使用自绘单色截面 SVG/PDF：plate、round、tube、angle、channel、I/H。
- 图标始终配名称；不要求用户仅凭截面猜型材。

### 3.5 App Icon 概念

主图形为一个由负空间构成的 I/H 截面与向右流动的两条平行线，暗示“材料进入、报价输出”。不使用货币符号，避免把产品局限为记账；不使用国旗，保持全球可用。

## 4. 导航结构

### iPhone

底部四 Tab：

1. **计算 / Calculate** — `function`
2. **项目 / Projects** — `folder`
3. **材料 / Materials** — `square.stack.3d.up`
4. **设置 / Settings** — `gearshape`

“新建项目”和“新计算”分别放在对应导航栏右侧；不使用悬浮大加号遮挡内容。

### iPad

使用 NavigationSplitView：

- Sidebar：Calculate、Projects、Materials、Settings。
- Content：型材或项目列表。
- Detail：计算编辑器、项目详情或报价预览。

窄 Split View 自动退化为 iPhone 导航，不维护第二套业务流程。

## 5. 核心页面

## 5.1 首次设置 / First-run setup

一页完成，不做多页营销 onboarding：

- 标题：`先设置你的工作方式 / Set up your workspace`
- 单位：公制 / US customary。
- 默认币种：按 Locale 推荐，可修改。
- App 语言：跟随系统、简体中文、English。
- 报价纸张：A4 / Letter，随地区预选。
- 主按钮：`开始计算 / Start calculating`
- 次按钮：`查看示例项目 / View sample project`

不要求注册、手机号、通知或照片权限。

## 5.2 计算首页 / Calculate home

结构：

1. 导航标题和搜索。
2. 最近使用型材（最多 4 个横向或 2×2 网格）。
3. 全部型材，以“实心 / Solid”“管材 / Hollow”“结构型材 / Structural”“自定义 / Custom”分组。
4. 最近计算列表，仅显示型材、关键尺寸和结果。

首屏避免统计仪表盘。用户的第一目标是选择型材。

## 5.3 计算编辑器 / Calculator editor

从上到下：

1. 型材名称和可交互截面图。
2. 尺寸输入；单位是每个字段右侧的 Menu。
3. 材料与密度；密度默认折叠显示。
4. 长度和数量。
5. 固定在输入下方的结果区：单件重量、总重量。
6. 可选“加入价格 / Add pricing”。
7. 底部主动作：`保存到项目 / Add to project`。

输入焦点切换时结果保持可见；小屏使用键盘工具栏的上一项/下一项/完成。

### 无效状态

- 字段下显示具体原因：`壁厚必须小于外径的一半。`
- 结果区显示 `—`，不保留上一个看似有效的结果。
- 主动作禁用并保留原因，VoiceOver 使用 live region 播报一次。

## 5.4 结果详情 / Calculation details

使用中等高度 Sheet：

- 截面积、体积、密度、净重、损耗后重量。
- 公式示意，不显示难以阅读的完整程序表达式。
- `几何估算 / Geometry estimate` 或 `目录理论值 / Catalog theoretical value` 标签。
- 来源、目录版本和舍入说明。
- 警告：例如“通用角钢公式未计圆角”。

## 5.5 项目列表 / Projects

默认按最近修改排序：

- 项目名、客户、项目号。
- 条目数量、总重量、报价总额。
- 状态：Draft、Quoted、Accepted、Archived；状态文字与图标共同呈现。
- Swipe：复制、归档；删除放在更多菜单并提供撤销。

顶部筛选只在有足够项目后出现，不给新用户展示空筛选器。

## 5.6 项目详情 / Project detail

顶层显示：项目名、客户、项目号、币种，以及重量和报价总额。

主体是可编辑条目表：

- 型材/说明。
- 数量 × 长度。
- 重量。
- 客户报价。

底部：

- `添加材料 / Add item`
- `报价设置 / Quote settings`
- 主动作 `预览报价 / Preview quote`

内部成本和利润默认只在“汇总详情”中显示，避免客户在现场看到不应展示的信息。

## 5.7 报价设置 / Quote settings

分组：

- Document：语言、币种、A4/Letter、报价号、有效期。
- Company：Logo、公司名、联系方式。
- Customer visibility：单位重量、总重量、单价、税、内部料号。
- Pricing：税名/税率、利润策略、加工费。
- Terms：付款、交货和免责声明。

利润策略必须明确选择：

- Markup on cost / 成本加成
- Margin on selling price / 销售毛利率

两者不可用同一“利润率”标签混淆。

## 5.8 报价预览 / Quote preview

- 顶部工具栏：关闭、语言、分享。
- 主体为实际 PDF 页面，不用近似 HTML 预览。
- 底部显示页数和文件大小。
- 分享前若缺公司/客户信息，仅提示，不阻断。

## 5.9 材料目录 / Materials

- 搜索名称和别名。
- 内置与自定义分组。
- 每行显示名称、密度、来源类型。
- 点入查看密度、典型值说明、来源和被多少条目使用。
- 自定义材料可复制内置材料后修改，避免从空白开始。

## 5.10 设置 / Settings

顺序：

1. Language & region / 语言与地区
2. Units & precision / 单位与精度
3. Quote defaults / 报价默认值
4. Company profile / 公司资料
5. SteelFlow Pro / Pro 与恢复购买
6. Data / 备份、恢复、删除
7. About / 公式版本、数据来源、隐私和免责声明

## 6. 关键组件

### DimensionField

- 标签、数值输入、单位 Menu、可选帮助。
- 数值使用大键盘；粘贴时解析 locale。
- 单位变化后即时转换并短暂显示转换反馈。

### ProfileDiagram

- 按当前字段高亮宽、高、壁厚或直径。
- 不做装饰性 3D；首版只用清晰截面图。
- VoiceOver 提供文字描述，如“矩形管，外宽、外高和壁厚”。

### ResultStrip

- 两个主结果：unit mass 与 total mass。
- 有价格后可切换为 total weight + quote total，但不同时堆四个 KPI。
- 点按打开 Calculation details。

### MoneyField

- 币种代码和符号同时可辨，例如 `USD $`，避免 `$` 歧义。
- 内部 Decimal；编辑时不实时插入千分位造成光标跳动。

### WarningBanner

- Amber：可继续但必须复核。
- Red：阻止结果或导出。
- 文案先说问题，再给解决方式。

## 7. 中英文关键文案 / Core copy deck

| Key | 简体中文 | English |
|---|---|---|
| nav.calculate | 计算 | Calculate |
| nav.projects | 项目 | Projects |
| nav.materials | 材料 | Materials |
| nav.settings | 设置 | Settings |
| action.add_to_project | 保存到项目 | Add to project |
| action.preview_quote | 预览报价 | Preview quote |
| action.share_pdf | 分享 PDF | Share PDF |
| result.unit_mass | 单件重量 | Unit mass |
| result.total_mass | 总重量 | Total mass |
| result.total_price | 报价总额 | Quote total |
| field.outer_diameter | 外径 | Outer diameter |
| field.wall_thickness | 壁厚 | Wall thickness |
| field.length | 长度 | Length |
| field.quantity | 数量 | Quantity |
| field.material | 材料 | Material |
| field.density | 密度 | Density |
| pricing.waste | 损耗 | Waste |
| pricing.tax | 税费 | Tax |
| pricing.markup | 成本加成 | Markup on cost |
| pricing.margin | 销售毛利率 | Margin on selling price |
| detail.calculation | 计算详情 | Calculation details |
| detail.geometry_estimate | 几何估算 | Geometry estimate |
| error.wall_too_thick | 壁厚必须小于外径的一半。 | Wall thickness must be less than half the outer diameter. |
| warning.corner_radii | 通用公式未计入圆角，请按实际型材复核。 | Corner radii are not included in this generic estimate. Verify against the actual section. |
| empty.projects.title | 还没有项目 | No projects yet |
| empty.projects.body | 保存一次计算，即可开始制作报价。 | Add a calculation to start building a quote. |

## 8. 响应式布局

### iPhone compact

- 单列。
- 结果区随内容滚动但在输入区后尽早出现。
- 项目条目每行最多两个右对齐数值，更多信息进入详情。
- 不使用横向滚动表格作为主要编辑器。

### iPad regular

- 计算器采用左侧截面图和字段、右侧结果与价格的两栏布局。
- 项目详情显示真正表格；点击行在右侧 Inspector 编辑。
- 报价预览与设置可并排显示。

### 横屏与 Stage Manager

- 以可用宽度断点决定布局，不根据设备型号。
- 最窄 320pt 仍不截断主动作和金额。

## 9. 无障碍

- 支持 Dynamic Type 到最大辅助字号；金额可换行，不缩小至不可读。
- 所有图形有文本名称；截面图提供描述。
- 错误与结果变化不在每次键入时反复朗读，完成输入后播报一次。
- 色彩之外使用图标和明确文本。
- 支持 Reduce Motion；单位转换不做大幅动画。
- 外接键盘：Tab 顺序与视觉顺序一致，Command-N 新建，Command-E 导出。

## 10. 空状态、错误和确认

| 场景 | 设计 |
|---|---|
| 无项目 | 一句价值说明 + “新建计算”，不展示模板轮播 |
| 无搜索结果 | 显示当前查询和“创建自定义材料/型材”入口 |
| 无效几何 | 字段内联错误 + 结果清空 + 图形高亮冲突尺寸 |
| PDF 生成失败 | 保留项目；显示可重试原因，不丢临时设置 |
| 备份校验失败 | 列出版本/checksum 问题，不部分导入 |
| 删除项目 | 立即移除并提供 Undo；永久删除备份需二次确认 |
| 删除全部数据 | 显示对象数量，输入确认词后执行 |

## 11. 动效与反馈

- 修改尺寸时截面图尺寸线轻微过渡，遵循 Reduce Motion。
- 有效输入完成后结果数字使用短暂 cross-dissolve，不滚动老虎机数字。
- 保存项目使用小型成功反馈和 haptic；错误使用 notification haptic。
- 购买和导出使用系统进度，不自造无法取消的全屏加载页。

## 12. 报价视觉

PDF 应像专业供应商报价，而不是 App 截图：

- 页眉：公司、Quote、编号、日期。
- 客户与项目分两列；中文时允许单列回流。
- 条目表格：Item、Description、Qty、Length、Material、Mass、Unit price、Amount，根据可见性配置缩减。
- 合计：Subtotal、Tax、Total，Total 最突出。
- 页脚：条款、公式/理论重量免责声明、页码。
- 客户版本不显示内部成本和利润。
- 品牌只在免费版页脚保留小型 “Made with SteelFlow”。

## 13. 设计验收清单

- 中文和英文分别在 iPhone 320/390/430pt 与 iPad Split View 检查。
- 至少使用 10 个真实、长名称材料和客户案例验证截断。
- 小数逗号、三字符币种、无小数币种和大金额均不溢出。
- 深色、浅色、高对比度、最大 Dynamic Type 通过。
- 关键流程不依赖隐藏 Swipe 或长按。
- 新用户无需阅读说明即可在 30 秒内完成圆管重量计算。
- 客户版 PDF 不泄露成本、利润或内部备注。
- 所有阻止性错误有可执行的修复建议。
