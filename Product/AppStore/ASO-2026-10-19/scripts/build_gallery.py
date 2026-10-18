from pathlib import Path
from PIL import Image, ImageDraw
import html,json
root=Path(__file__).resolve().parents[1]
config=json.loads((root/'editor-project.json').read_text())
body='<h1>SteelFlow · 12 地区商店素材</h1><p>1.3.1（28）· 2026-10-19 · 草稿素材，未提交审核。点击查看原尺寸。</p>'
for locale in config['locales']:
 body+=f'<section><h2>{locale}</h2>'
 for device,size in [('iphone','1320x2868'),('ipad','2064x2752')]:
  files=sorted((root/'exports/ios'/device/size/locale).glob('*.png'))
  assert len(files)==6
  body+=f'<h3>{device}</h3><div class="deck">'
  contact=Image.new('RGB',(1440,565 if device=='iphone' else 360),'#f2f5f9');draw=ImageDraw.Draw(contact)
  for i,p in enumerate(files):
   rel=p.relative_to(root);body+=f'<a href="{rel}"><img loading="lazy" src="{rel}" alt="{locale} {device} {i+1}"></a>'
   im=Image.open(p);im.thumbnail((240,535 if device=='iphone' else 330));contact.paste(im,(i*240,30));draw.text((i*240+5,7),p.name,fill='black')
  contact.save(root/'qa'/f'{device}-{locale}.jpg',quality=88)
  body+='</div>'
 body+='<details><summary>商店文案</summary>'
 for field in ['name','subtitle','keywords','promotionalText','description','whatsNew']:
  body+=f'<h3>{field}</h3><pre>'+html.escape((root/'metadata'/locale/f'{field}.txt').read_text())+'</pre>'
 body+='</details></section>'
(root/'index.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SteelFlow ASO 2026-10-19</title><style>body{font:16px system-ui;margin:32px;background:#eef3f7;color:#12344c}section{background:white;padding:24px;margin:24px 0;border-radius:16px}.deck{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}img{width:100%;border-radius:8px}pre{white-space:pre-wrap;font:inherit;line-height:1.6}@media(max-width:800px){.deck{grid-template-columns:repeat(3,1fr)}body{margin:12px}}</style>'+body+'</html>')
print('Built 24 contact sheets and local gallery')
