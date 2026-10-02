from pathlib import Path
import json,html
out=Path(__file__).resolve().parents[1]
data=json.loads((out/'localizations.json').read_text()); names={'zh-Hant':'繁體中文','ja':'日本語','ko':'한국어','de-DE':'Deutsch','es-ES':'Español','fr-FR':'Français'}
def img(l,i,d='iphone',size='1320x2868'):
 p=f'exports/ios/{d}/{size}/{l}/{i:02d}-device-bottom.png'; return f'<a href="{p}"><img loading="eager" src="{p}" alt="{html.escape(data[l]["captions"][i-1][0])}"></a>'
css='''*{box-sizing:border-box}body{margin:0;background:#eef3f7;color:#122a3f;font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",sans-serif}main{max-width:1540px;margin:auto;padding:40px}h1{font-size:30px;margin:0 0 12px}h2{font-size:24px}p{line-height:1.6}nav{display:flex;gap:10px;flex-wrap:wrap;margin:24px 0}nav a,button{background:#fff;border:1px solid #b6c9d7;border-radius:8px;padding:10px;color:#123a56;text-decoration:none;cursor:pointer}section{margin:30px 0;background:white;border-radius:16px;padding:24px}.deck{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:12px}.deck img{width:100%;display:block;border-radius:8px}details{margin:18px 0}summary{cursor:pointer;font-weight:600}.fields{display:grid;grid-template-columns:1fr 1fr;gap:18px}.field{background:#f3f7fa;padding:16px;border-radius:8px}.field strong{display:block;margin-bottom:10px}.value{white-space:pre-wrap;line-height:1.65}.desc{grid-column:1/-1}button{float:right;font-size:12px}.muted{color:#5d7182}#covers{display:grid;grid-template-columns:repeat(6,180px);gap:14px;width:max-content;padding:20px;background:#eef3f7}#covers img{width:180px;display:block}#covers figcaption{margin:0 0 10px;font-weight:600}figure{margin:0}.thumbqa{display:grid;grid-template-columns:repeat(3,160px);gap:12px}.thumbqa img{width:160px;display:block}#search-qa{display:grid;grid-template-columns:repeat(2,504px);gap:24px;width:max-content;padding:24px;background:#eef3f7}#search-qa h3{margin:0 0 10px}.raw img{width:100%}@media(max-width:800px){main{padding:16px}.deck{grid-template-columns:repeat(3,1fr)}.fields{grid-template-columns:1fr}}'''
body='<main><h1>SteelFlow · 六语言 App Store 素材</h1><p class="muted">1.3 / 2026-09-28 · 真实本地化界面 · 点击图片查看原尺寸。文案与首选尺寸截图已随 1.3（26）提交商店审核，当前等待审核。</p><nav>'+''.join(f'<a href="#{l}">{n}</a>' for l,n in names.items())+'</nav>'
body+='<div id="covers">'+''.join(f'<figure><figcaption>{names[l]}</figcaption>{img(l,1)}</figure>' for l in data)+'</div>'
for l,e in data.items():
 body+=f'<section id="{l}" lang="{l}"><h2>{names[l]} <small class="muted">{l}</small></h2><div class="deck">'+''.join(img(l,i) for i in range(1,7))+'</div>'
 body+='<details><summary>iPad · 2064 × 2752</summary><div class="deck">'+''.join(img(l,i,'ipad','2064x2752') for i in range(1,7))+'</div></details><div class="fields">'
 for k,title in [('name','标题 / Name'),('subtitle','副标题 / Subtitle'),('keywords','关键词 / Keywords'),('promotionalText','推广文字'),('description','描述'),('whatsNew','版本更新')]:
  body+=f'<div class="field {"desc" if k in ["description","whatsNew"] else ""}"><button onclick="copyField(this)">复制</button><strong>{title}</strong><div class="value">{html.escape(e[k])}</div></div>'
 body+='</div></section>'
body+='<h2>前 3 张搜索缩略图检查 · 每张 160 px</h2><div id="search-qa">'
for l in data:
 body+=f'<div><h3>{names[l]}</h3><div class="thumbqa">'+''.join(img(l,i) for i in range(1,4))+'</div></div>'
body+='</div><p class="muted">布局参考英文版：深蓝底、简洁标题、正面设备与大幅真实界面。品牌、单位和材料牌号保留标准写法。部分截图展示 Pro 功能，具体免费与付费范围见描述。</p></main>'
(out/'index.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SteelFlow — 六语言 ASO 素材</title><style>'+css+'</style>'+body+'''<script>async function copyField(b){const t=b.parentElement.querySelector('.value').textContent;try{await navigator.clipboard.writeText(t);b.textContent='已复制'}catch{const r=document.createRange();r.selectNodeContents(b.parentElement.querySelector('.value'));getSelection().removeAllRanges();getSelection().addRange(r);b.textContent='已选中，请复制'}setTimeout(()=>b.textContent='复制',1800)}</script></html>''')
print(out/'index.html')
