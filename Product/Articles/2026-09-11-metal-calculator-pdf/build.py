from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import re, html, json, shutil
r=Path(__file__).parent
src=r.parent/'2026-09-10-compare-steel-prices/screenshots'
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
board('01-overview.png','From metal dimensions to a PDF quote','Choose a profile. Check the weight. Keep the project and document together.',[('home','Choose'),('calculation','Calculate'),('project','Organise'),('quote','Share')],2000,1330,285)
board('02-calculation-materials.png','Check the input behind the weight','A visible result, with dimensions and density you can review.',[('calculation','Calculation'),('materials','Materials')],1400,1590,285)
board('03-project-pdf.png','Keep the quote connected to the job','Harbor Canopy: a separate, fictional three-line project.',[('project','Project detail'),('quote','PDF preview')],1400,1590,285)
shutil.copy(src/'provenance.json',r/'assets'/'provenance.json')
def inline(s):
 s=html.escape(s);s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s);s=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',s);return re.sub(r'\*(.+?)\*',r'<em>\1</em>',s)
blocks=[]; paste=[]
for block in (r/'article.md').read_text().strip().split('\n\n'):
 if block.startswith('# '): title=block[2:];out='<h1>'+inline(title)+'</h1>'
 elif block.startswith('## '):out='<h2>'+inline(block[3:])+'</h2>'
 elif block.startswith('!['):
  alt,path=re.fullmatch(r'!\[(.*?)\]\((.*?)\)',block).groups();out=f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(alt)}"></a></figure>'
 elif block.startswith('- '):out='<ul>'+''.join('<li>'+inline(x[2:])+'</li>' for x in block.splitlines())+'</ul>'
 else:out='<p>'+inline(block)+'</p>'
 blocks.append(out)
 if not block.startswith('# ') and not block.startswith('!['):paste.append(out)
style='''*{box-sizing:border-box}body{margin:0;color:#263943;background:#fff;font-family:Georgia,serif}main{max-width:820px;margin:auto;padding:64px 28px}h1,h2{font-family:Arial,sans-serif;color:#173d50;line-height:1.18}h1{font-size:44px;letter-spacing:-1px}h2{font-size:29px;margin-top:48px}p,li{font-size:20px;line-height:1.75}a{color:#08769a;overflow-wrap:anywhere}figure{margin:32px -18px}img{display:block;width:100%;height:auto}p:has(>em:only-child){font-size:15px;color:#60727d;line-height:1.6}li{margin:8px 0}@media(max-width:600px){main{padding:25px 20px}h1{font-size:32px}h2{font-size:25px}p,li{font-size:18px}figure{margin:25px -8px}}'''
desc='Use a metal weight calculator on iPhone to check dimensions, organise project items and export a PDF material quote. A practical SteelFlow guide.'
(r/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><meta name="description" content="'+desc+'"><style>'+style+'</style><main>'+''.join(blocks)+'</main></html>')
(r/'medium-body.html').write_text(''.join(paste))
(r/'seo.json').write_text(json.dumps(dict(title=title,description=desc,primaryKeyword='metal weight calculator',secondaryKeywords=['metal weight calculator app','PDF material quote','steel quotation'],searchVolume=None,volumeStatus='Ahrefs US Google query blocked by human verification; no volume claims',suggestedSlug='metal-weight-calculator-iphone-pdf-quote',publicationState='draft'),indent=2))
print('Created three screenshot layouts, HTML preview and Medium body; words:',len((r/'article.md').read_text().split()))
