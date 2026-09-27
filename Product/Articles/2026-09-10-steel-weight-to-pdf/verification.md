# 交付检查

- 需求调研记录：research.md，含用户讨论、行业资料、竞品文章与七篇系列选题。
- 正文：article.md；排版预览：index.html；可复现排版：render.py。
- 六屏拼接图：assets/feature-overview.png，2400×3829；排版源：collage.html。
- 六张截图均来自当前源码运行的真实页面，来源见 screenshots/provenance.json。正文就近使用计算、项目、PDF、材料四张大图。
- PDF 附件直接复制自专用模拟器中 App 生成的文件；不是重写的报价模板。
- 桌面 1280px、手机 390px 预览；已检查文章首屏、PDF 段落和免费/Pro 段落。手机 documentWidth=390，无横向溢出；全部图片正常加载。
- 已目视检查六屏拼接图和全部六张原截图；金额、标签未进行图像修改。
- 算例 47.1kg × 18 = 847.8kg，847.8 × 5.32 元/kg舍入为4510.30元；单次练习与港区雨棚项目已明确区分。
- 项目与 PDF 界面均显示35228.94元，示例项目总重量4461.559kg。
- 下载、产品介绍、支持链接直接 HTTP 检查均返回200；搜索抓取器未能取得这些页面，未据此误报失效。
- 新 skill 已安装到 /Users/daemonzhao/.codex/skills/write-product-guide/SKILL.md，quick_validate 通过；目录内保留同内容副本。
- 本次未发布文章、未修改 App 功能代码、未更改商店资料。搜索效果有待实际发布后的站点数据验证。
