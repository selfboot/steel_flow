from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import re, html, json, shutil
r=Path(__file__).parent
src=r/'screenshots'
font='/System/Library/Fonts/Supplemental/Arial.ttf'
bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def f(n,b=False): return ImageFont.truetype(bold if b else font,n)
def board(name,title,subtitle,items,w,h,top):
 im=Image.new('RGB',(w,h),'#f0f5f7');d=ImageDraw.Draw(im)
 d.rectangle((0,0,w,12),fill='#08769a')
 d.text((65,45),'STEELFLOW / PRACTICAL GUIDE',font=f(23,True),fill='#08769a')
 d.text((65,91),title,font=f(49,True),fill='#173d50')
 d.text((65,156),subtitle,font=f(25),fill='#536b79')
 gap=35; cw=(w-130-gap*(len(items)-1))//len(items)
 for i,(screen,label) in enumerate(items):
  x=65+i*(cw+gap)
  d.text((x,225),f'{i+1:02d}  {label}',font=f(27,True),fill='#173d50')
  shot=Image.open(src/(screen+'.png')).convert('RGB')
  shot.thumbnail((cw,h-top-80),Image.Resampling.LANCZOS)
  xx=x+(cw-shot.width)//2
  d.rounded_rectangle((xx-5,top-5,xx+shot.width+5,top+shot.height+5),radius=24,fill='white')
  im.paste(shot,(xx,top))
 d.text((65,h-44),'Real app screens · v1.1.0 · iPhone simulator · Fictional demo data',font=f(21),fill='#536b79')
 im.save(r/'assets'/name)
board('01-workflow.png','One flat-bar order, from input to PDF','100 × 10 mm · 6 m × 18 bars · 847.8 kg · USD 627.37',[('input','Enter dimensions'),('pricing','Apply the rate'),('project','Review the order'),('quote','Preview the PDF')],2200,1480,285)
board('02-input-pricing.png','Start with dimensions. Then add a rate.','Length belongs to one bar; quantity belongs to the order.',[('input','100 × 10 mm / 18 bars'),('pricing','0.74 USD per kg')],1500,1750,285)
board('03-project-quote.png','The same order, ready to share','One item · 847.8 kg · USD 627.37 · Fictional demo price',[('project','Check the project'),('quote','Review the PDF')],1500,1750,285)
def inline(s):
 s=html.escape(s);s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s);s=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',s);return re.sub(r'\*(.+?)\*',r'<em>\1</em>',s)
blocks=[]; paste=[]
for block in (r/'article.md').read_text().strip().split('\n\n'):
 if block.startswith('# '): title=block[2:];out='<h1>'+inline(title)+'</h1>'
 elif block.startswith('## '):out='<h2>'+inline(block[3:])+'</h2>'
 elif block.startswith('!['):
  lines=block.splitlines(); alt,path=re.fullmatch(r'!\[(.*?)\]\((.*?)\)',lines[0]).groups();out=f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(alt)}"></a><figcaption>'+inline(' '.join(lines[1:]))+'</figcaption></figure>'
 elif block.startswith('- '):out='<ul>'+''.join('<li>'+inline(x[2:])+'</li>' for x in block.splitlines())+'</ul>'
 else:out='<p>'+inline(block)+'</p>'
 blocks.append(out)
 if not block.startswith('# ') and not block.startswith('!['):paste.append(out)
style='''*{box-sizing:border-box}body{margin:0;color:#263943;background:#fff;font-family:Georgia,serif}main{max-width:820px;margin:auto;padding:64px 28px}h1,h2{font-family:Arial,sans-serif;color:#173d50;line-height:1.18}h1{font-size:44px;letter-spacing:-1px}h2{font-size:29px;margin-top:48px}p,li{font-size:20px;line-height:1.75}a{color:#08769a;overflow-wrap:anywhere}figure{margin:32px -18px}img{display:block;width:100%;height:auto}p:has(>em:only-child){font-size:15px;color:#60727d;line-height:1.6}li{margin:8px 0}figcaption{font-size:15px;line-height:1.6;color:#60727d;margin-top:12px}@media(max-width:600px){main{padding:25px 20px}h1{font-size:32px}h2{font-size:25px}p,li{font-size:18px}figure{margin:25px -8px}}'''
desc=json.loads((r/'seo.json').read_text())['description']
(r/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><meta name="description" content="'+desc+'"><style>'+style+'</style><main>'+''.join(blocks)+'</main></html>')
(r/'medium-body.html').write_text(''.join(paste))
print('Built article layouts and HTML')
