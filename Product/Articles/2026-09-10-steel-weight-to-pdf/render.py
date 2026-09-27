from pathlib import Path
import re, html, json
root=Path(__file__).parent

def inline(s):
    s=html.escape(s)
    s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s)
    s=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',s)
    s=re.sub(r'\*(.+?)\*',r'<em>\1</em>',s)
    return s
blocks=[]
for block in (root/'article.md').read_text().strip().split('\n\n'):
    if block.startswith('# '):
        title=block[2:];blocks.append('<h1>'+inline(title)+'</h1>')
    elif block.startswith('## '):
        label=block[3:];blocks.append('<h2>'+inline(label)+'</h2>')
    elif block.startswith('> '): blocks.append('<aside>'+inline(block[2:])+'</aside>')
    elif block.startswith('- '):blocks.append('<ul>'+''.join('<li>'+inline(x[2:])+'</li>' for x in block.splitlines())+'</ul>')
    elif block.startswith('!['):
        m=re.fullmatch(r'!\[(.*?)\]\((.*?)\)',block);alt,url=m.groups();cls='overview' if 'overview' in url else 'screen'
        blocks.append(f'<figure class="{cls}"><a href="{url}" target="_blank"><img src="{url}" alt="{html.escape(alt)}" loading="lazy"></a></figure>')
    else:blocks.append('<p>'+inline(block.replace('\n',' '))+'</p>')
style='''*{box-sizing:border-box}body{margin:0;background:#f5f8fb;color:#233443;font-family:-apple-system,BlinkMacSystemFont,"PingFang SC","Microsoft YaHei",sans-serif;-webkit-font-smoothing:antialiased}header{max-width:1040px;margin:0 auto;padding:36px 40px 24px;display:flex;align-items:center;gap:14px;font-size:14px;color:#526879}header img{width:44px;height:44px;border-radius:11px}header b{font-size:20px;color:#123e55}header span{margin-left:auto}main{max-width:1040px;margin:auto;background:white;padding:54px 88px 72px;border-top:4px solid #08759f}h1{font-size:42px;line-height:1.4;letter-spacing:-1px;color:#103b50;margin:0 0 30px}h2{font-size:27px;line-height:1.5;color:#103b50;margin:58px 0 20px;padding-top:20px;border-top:1px solid #dce7eb}p,li{font-size:18px;line-height:1.95}p{margin:20px 0}strong{color:#163e53;font-weight:650}a{color:#086e99;text-underline-offset:4px;text-decoration-thickness:1px;overflow-wrap:anywhere}aside{background:#eef6fa;border-left:3px solid #167aa0;padding:16px 20px;font-size:14px;line-height:1.9;color:#526675;margin:28px 0}ul{padding-left:24px}li{padding-left:4px;margin:7px 0}figure{margin:32px 0 16px}figure img{display:block;width:100%;height:auto}figure.screen{max-width:385px;margin:34px auto 14px;border:1px solid #dae3e8;border-radius:22px;overflow:hidden;box-shadow:0 12px 28px #163e530d}p:has(>em:only-child){font-size:14px;line-height:1.8;color:#5d7080;margin:10px 0 30px;text-align:center}em{font-style:normal}footer{max-width:1040px;margin:auto;padding:26px 40px 48px;color:#6c7d89;font-size:13px;line-height:1.8}@media(max-width:650px){header{padding:20px;gap:10px}header span{font-size:12px}main{padding:28px 22px 40px}h1{font-size:29px;letter-spacing:0}h2{font-size:23px;margin-top:44px}p,li{font-size:17px;line-height:1.95}aside{padding:14px;font-size:13px}figure.screen{max-width:100%;border-radius:16px}footer{padding:24px 22px}}'''
desc='用一组钢板尺寸算出理论重量，再把多种规格汇总成项目，添加计价与费用，导出 PDF 报价单。附 SteelFlow 真实界面与示例文件。'
(root/'index.html').write_text('<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><meta name="description" content="'+desc+'"><style>'+style+'</style></head><body><header><img src="assets/app-icon.png" alt="SteelFlow 图标"><b>SteelFlow</b><span>使用指南 · 2026.09.10</span></header><main>'+''.join(blocks)+'</main><footer>真实界面采集：SteelFlow 1.1.0（13） · iOS 26.5 模拟器。通过演示入口直接展示功能页面，未包含主 Tab 外壳。项目、客户与价格均为演示数据。<br>点击图片可打开原图。本文为待发布图文稿。</footer></body></html>')
items=[('home','选对型材','先选截面，再填尺寸'),('calculation','核对重量','尺寸、材料与数量一起计算'),('materials','选择材料','查看典型密度，核对材料'),('projects','整理项目','按项目、客户或编号查找'),('project','汇总报价','多种规格放到一张清单'),('quote','生成 PDF','预览后保存版本并分享')]
css='''*{box-sizing:border-box}body{margin:0;font-family:-apple-system,"PingFang SC",sans-serif;background:#eef5f9;color:#123c51}.board{width:2400px;padding:86px 100px 64px;background:linear-gradient(155deg,#e7f3fb,#f7fafc 46%,#e4f0f5)}header{display:flex;align-items:center;gap:38px;margin-bottom:52px}header img{width:150px;height:150px;border-radius:34px}h1{font-size:78px;margin:0 0 18px;line-height:1.2;letter-spacing:1px}header p{font-size:34px;color:#4f6c7d;margin:0}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:58px 54px}.panel h2{font-size:42px;line-height:1.25;margin:0 0 12px;display:flex;gap:20px;align-items:center}.panel b{font-size:29px;color:#08739b;border:2px solid #82b6ca;padding:8px 12px;border-radius:12px}.panel p{font-size:29px;margin:0 0 22px;color:#557080}.screen{width:100%;display:block;border:6px solid white;border-radius:40px;box-shadow:0 16px 34px #224c5d12}.foot{font-size:27px;color:#5c7481;margin:54px 0 0;line-height:1.65}.foot strong{color:#194c65}'''
cards=''.join(f'<section class="panel"><h2><b>{i:02d}</b>{name}</h2><p>{sub}</p><img class="screen" src="screenshots/{f}.png" alt="{name}真实截图"></section>' for i,(f,name,sub) in enumerate(items,1))
(root/'collage.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>SteelFlow 六屏功能总览</title><style>'+css+'</style><div class="board"><header><img src="assets/app-icon.png"><div><h1>从钢材尺寸，到一份 PDF 报价</h1><p>SteelFlow · 算重 / 计价 / 项目 / 报价输出</p></div></header><div class="grid">'+cards+'</div><p class="foot"><strong>真实 App 页面 · 1.1.0</strong>　iPhone 模拟器采集，演示入口直接展示页面。<br>图中项目、客户及价格均为演示数据，不代表实际订单或实时行情。</p></div></html>')
(root/'seo.json').write_text(json.dumps({'title':title,'description':desc,'suggestedSlug':'steel-weight-calculator-pdf-quote','primaryIntent':'手机钢材理论算重与 PDF 报价','primaryKeyword':'钢材重量计算','relatedKeywords':['钢板重量怎么算','钢材报价单','PDF 报价单','iPhone 钢材计算器'],'author':'SteelFlow','date':'2026-09-10','publicationState':'draft','canonical':'set only after actual publication','internalLinks':['https://docs.puzzles-game.com/zh/steelflow','https://docs.puzzles-game.com/zh/steelflow/support']},ensure_ascii=False,indent=2))
print('Generated article and collage HTML')
