# SteelFlow 1.4：ASO 与付费转化复核

2026-10-19。价格不变；按用户选择，仅使用 Apple 和 RevenueCat，不新增 PostHog 或匿名行为统计。

## 本轮修复

- 计算页有效结果下增加“制作客户报价”；保存到项目后直接进入免费 PDF 预览。沿用项目和条目额度、币种确认与保存错误处理。取消不创建项目，不强制购买。9 个 App 本地化同步。
- 设置图标移除底板、渐变与阴影，统一 32pt 图标栏、20pt 单色符号，保留红色删除提示。Pro 卡片图标也直接显示。已查看浅色、深色实图。
- Pro 商品真实线上原来只有 en-US / zh-Hans；新增可审核版本 2，12 个地区文案写入并回读一致。明确公司品牌、CSV、备份等 Pro 权益，移除“所有 PDF 必须购买”的误导。旧版仍 APPROVED；新版仍 PREPARE_FOR_SUBMISSION，不能当作已经上线。
- 审核说明改为 1.4 (29)、9 个 App 本地化和实际免费／Pro 检查路径。12 地区更新说明补充新报价流程。
- 官网中英文新增 App Store 下载入口、三步流程、真实截图、免费额度和 Pro 权益对照。已部署并回读 HTTP 200，手机和桌面图片／链接检查通过。
- 英文截图 3 对照版扩大实际报价显示，强调“一次买断，无订阅”。原有 12 地区截图保持基线，本对照版未上传替换默认截图，也未开启线上实验。

## 第二轮 review 结论

修复了 UI 回归中发现的父视图覆盖按钮辅助功能标识问题。修复后，新免费流程在 iPhone / iPad 均通过；120 项单元测试通过。Pro 浅色／深色、德语最大辅助字号和设置默认值跨两条项目创建路径的回归通过。正式包版本、签名、语言资源另见发布记录。

未发现新的阻塞性代码／文案问题，但以下不是“已经验证成功”的事项：

1. 已配对 iPhone 的连接仍为 unavailable，无法验证 TestFlight 实际购买与恢复。上一轮本地 StoreKit 购买成功不能代替真机或生产支付验证。
2. Apple ONGOING 请求已开启，但本次下载与发现报告实例仍为 0，暂无可信地区曝光→下载转化率。Apple / RevenueCat 的现有数据无法还原完整 App 内升级路径。
3. 新内购文案需要审核后生效。现有 144 张默认截图沿用上一轮已验证上传的内容；英文对照图只是准备好的后续实验素材。
4. 官网下载入口改善站外转化，不等于直接提升 App Store 关键词排名。尚未获得 1.4 上线后的排名／下载／付费改善证据。

## 精准需求与观察方法

| 地区 | 需求与候选查询 | 本轮动作 | 上线后看什么 |
| --- | --- | --- | --- |
| 美国 | metal cost calculator；metal weight calculator；steel weight calculator | 保留重量＋成本＋PDF 报价组合，英制展示，强调品牌报价的付费价值 | Search 来源曝光、首次下载、产品页表现、美国净新增购买；固定日期查实际商店排名 |
| 日本 | 鋼材重量計算 | 保留本地化重量／材料费／PDF 見積書文案 | 日本曝光与首次下载是否增长，再判断是否补充新词 |
| 墨西哥 | calculadora peso metal；cotización metal | 墨西哥西语、MXN 示例、cotización / costo / lámina 用语 | 先确认可被发现与有效下载，再观察付费；不把未知热度当高需求 |
| 德国／英国 | blechgewicht；metal weight calculator | 保留已有词组与地区单位，观察新本地化上线效果 | 验证有曝光后再扩词，避免填满字符却稀释意图 |

`keyword-observation-20261019-1.4-draft.json` 是公开 Apple iTunes Search API 观察，不是真实 App Store 自然排名。API 暂未返回本 App 表示“这次该接口结果中未找到”，不代表在商店排在第 101 名或不存在。

实际商店检查需固定国家 storefront、设备、语言和时间，记录搜索画面；不要把 API 顺序和设备搜索排名拼成同一序列。脚本只用于低成本搜索覆盖观察，不提供流量或搜索量。

```bash
python3 Product/AppStore/ASO-2026-10-19-followup/scripts/observe_keywords.py --out /tmp/steelflow-keywords-YYYYMMDD.json
```

1.4 真正上线后，以其上线日为第 0 天。先保留标题／关键词和默认截图至少一个完整观察窗口（建议 14 天，低样本时延长）。分国家比较同样长度的窗口，注意曝光、下载和付费人数的分母与来源，不从少量购买推断提升。

英文素材对照仅替换截图 3，保持价格与其他截图不变；满足 Apple 产品页实验资格、流量和审核条件后再启动。以 Apple 给出的实验转化数据为依据，不以局部 API 排位或当天付费波动宣布胜出。未安排自动监控，也未启动实验。

## 素材与重现

- [缩略图和完整对照图](index.html)
- [图像尺寸／RGB 校验](asset-validation.json)：6 种导出尺寸。
- [测试与 review 记录](qa/review-results.json)
- [美国／日本等搜索覆盖基线](keyword-observation-baseline.json)

使用现有 ScreenshotsEditor，无新渲染器。`scripts/export_editor.cjs iphone` / `ipad` 临时载入此目录配置，通过现有 Export bundle 按钮导出，结束后恢复原编辑器配置。需现有编辑器服务监听 127.0.0.1:3026，并将 `PW_MODULE` 指向已安装的 Playwright 包；导出 zip 不提交。

依据：[Apple 产品页指南](https://developer.apple.com/app-store/product-page/)说明前 1–3 张截图会进入搜索展示，内购名称和说明分别限制为 35 / 55 字符；[Apple 搜索指南](https://developer.apple.com/app-store/search/)用于区分相关性、转化与排名影响。没有承诺排名提升。
