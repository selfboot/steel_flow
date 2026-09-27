from pathlib import Path
import re, html, json, base64, shutil, zipfile
root=Path(__file__).parent

def inline(s):
    s=html.escape(s)
    s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s)
    s=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',s)
    s=re.sub(r'\*(.+?)\*',r'<em>\1</em>',s)
    return s
blocks=[]
image_entries=[]
(root/"upload-images").mkdir(exist_ok=True)
for block in (root/'article.md').read_text().strip().split('\n\n'):
    if block.startswith('# '):
        title=block[2:];blocks.append('<h1>'+inline(title)+'</h1>')
    elif block.startswith('## '):
        label=block[3:];blocks.append('<h2>'+inline(label)+'</h2>')
    elif block.startswith('| '):
        rows=[r.strip().strip('|').split('|') for r in block.splitlines()]
        blocks.append('<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+inline(c.strip())+'</th>' for c in rows[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+inline(c.strip())+'</td>' for c in r)+'</tr>' for r in rows[2:])+'</tbody></table></div>')
    elif block.startswith('> '): blocks.append('<aside>'+inline(block[2:])+'</aside>')
    elif block.startswith('- '):blocks.append('<ul>'+''.join('<li>'+inline(x[2:])+'</li>' for x in block.splitlines())+'</ul>')
    elif block.startswith('!['):
        m=re.fullmatch(r'!\[(.*?)\]\((.*?)\)',block);alt,url=m.groups();cls='overview' if 'overview' in url else 'screen'
        number=len(image_entries)+1
        filename=f'{number:02d}-'+Path(url).name
        shutil.copyfile(root/url,root/'upload-images'/filename)
        image_entries.append({'id':number,'data':base64.b64encode((root/url).read_bytes()).decode(),'filename':filename})
        controls=f'<div class="image-tools" data-copy-ui><span>配图 {number:02d}</span><button type="button" data-image="{number}">复制这张图片</button><a href="upload-images/{filename}" download>下载原图</a></div>'
        blocks.append(f'<figure class="{cls}" data-image-number="{number}"><a href="{url}" target="_blank"><img src="{url}" alt="{html.escape(alt)}" loading="lazy"></a>{controls}</figure>')
    else:blocks.append('<p>'+inline(block.replace('\n',' '))+'</p>')
style='''.table-wrap{overflow-x:auto;margin:26px 0}table{border-collapse:collapse;width:100%;font-size:16px;line-height:1.6}th,td{text-align:left;padding:13px 12px;border-bottom:1px solid #dce7eb}th{background:#eef6fa;color:#103b50}h1{line-height:1.18!important}p,li{line-height:1.8!important}*{box-sizing:border-box}body{margin:0;background:#f5f8fb;color:#233443;font-family:-apple-system,BlinkMacSystemFont,"PingFang SC","Microsoft YaHei",sans-serif;-webkit-font-smoothing:antialiased}header{max-width:1040px;margin:0 auto;padding:36px 40px 24px;display:flex;align-items:center;gap:14px;font-size:14px;color:#526879}header img{width:44px;height:44px;border-radius:11px}header b{font-size:20px;color:#123e55}header span{margin-left:auto}main{max-width:1040px;margin:auto;background:white;padding:54px 88px 72px;border-top:4px solid #08759f}h1{font-size:42px;line-height:1.4;letter-spacing:-1px;color:#103b50;margin:0 0 30px}h2{font-size:27px;line-height:1.5;color:#103b50;margin:58px 0 20px;padding-top:20px;border-top:1px solid #dce7eb}p,li{font-size:18px;line-height:1.95}p{margin:20px 0}strong{color:#163e53;font-weight:650}a{color:#086e99;text-underline-offset:4px;text-decoration-thickness:1px;overflow-wrap:anywhere}aside{background:#eef6fa;border-left:3px solid #167aa0;padding:16px 20px;font-size:14px;line-height:1.9;color:#526675;margin:28px 0}ul{padding-left:24px}li{padding-left:4px;margin:7px 0}figure{margin:32px 0 16px}figure img{display:block;width:100%;height:auto}figure.screen{max-width:385px;margin:34px auto 14px;border:1px solid #dae3e8;border-radius:22px;overflow:hidden;box-shadow:0 12px 28px #163e530d}p:has(>em:only-child){font-size:14px;line-height:1.8;color:#5d7080;margin:10px 0 30px;text-align:center}em{font-style:normal}footer{max-width:1040px;margin:auto;padding:26px 40px 48px;color:#6c7d89;font-size:13px;line-height:1.8}@media(max-width:650px){header{padding:20px;gap:10px}header span{font-size:12px}main{padding:28px 22px 40px}h1{font-size:29px;letter-spacing:0}h2{font-size:23px;margin-top:44px}p,li{font-size:17px;line-height:1.95}aside{padding:14px;font-size:13px}figure.screen{max-width:100%;border-radius:16px}footer{padding:24px 22px}}'''
desc='Learn steel weight calculation for flat bar and plate, convert kg per metre into material cost, and check the details before sharing a PDF quote.'

controls = """<section class="copy-panel" aria-label="Substack 复制工具"><h2>复制到 Substack</h2><p>先复制正文，再在对应位置逐张粘贴图片，等待 Substack 上传完成。整页复制不会上传电脑里的图片。</p><div class="copy-actions"><button type="button" id="copy-title">复制标题</button><button type="button" id="copy-subtitle">复制副标题</button><button type="button" id="copy-body">复制排版正文</button><a href="substack-images.zip" download>下载全部 3 张配图</a></div><p class="hint">正文中的 [IMAGE 01] 等标记是插图位置。替换标记时可点击下方图片旁的“复制这张图片”，到 Substack 粘贴；若浏览器不支持图片剪贴板，下载后用编辑器图片按钮上传。图注已保留，发布前请删除位置标记。</p><p id="copy-status" role="status" aria-live="polite">配图上传后，请在 Substack 预览中确认显示正常。</p></section>"""
style += ".copy-panel{max-width:1040px;margin:0 auto 24px;padding:24px 32px;background:#e9f4f8;border:1px solid #c9e1eb}.copy-panel h2{margin:0 0 10px;padding:0;border:0;font-size:23px}.copy-panel p{font-size:15px;line-height:1.65!important}.copy-actions,.image-tools{display:flex;flex-wrap:wrap;gap:10px;align-items:center}button,.copy-actions a,.image-tools a{font:inherit;font-size:14px;padding:10px 14px;border:1px solid #8db4c5;border-radius:8px;background:white;color:#075a7d;cursor:pointer;text-decoration:none}button:focus-visible,a:focus-visible{outline:3px solid #08759f;outline-offset:3px}.image-tools{padding:14px;background:#edf5f8;font-size:13px}.image-tools span{width:100%;font-weight:600}.copy-panel .hint{color:#4a6270}#copy-status{min-height:24px;color:#075a7d}@media(max-width:650px){.copy-panel{margin:0 14px 20px;padding:20px}.copy-actions>*{flex:1 1 140px}}"
script = r"""
const imageData = __IMAGE_DATA__;
const status = document.getElementById('copy-status');
function tell(message){ status.textContent=message; }
async function copyText(text){
 if(navigator.clipboard && window.isSecureContext){ await navigator.clipboard.writeText(text); return; }
 const area=document.createElement('textarea'); area.value=text; document.body.append(area);area.select();
 const ok=document.execCommand('copy');area.remove();if(!ok)throw new Error('copy unsupported');
}
document.getElementById('copy-title').onclick=async()=>{try{await copyText(document.querySelector('main h1').textContent);tell('标题已复制。');}catch{tell('无法自动复制，请选中正文标题手动复制。');}};
document.getElementById('copy-subtitle').onclick=async()=>{try{await copyText(document.querySelector('main > p').textContent);tell('副标题已复制。');}catch{tell('无法自动复制，请选中副标题手动复制。');}};
document.getElementById('copy-body').onclick=async()=>{
 const clone=document.querySelector('main').cloneNode(true);
 clone.querySelector('h1').remove();clone.querySelector('p').remove();
 clone.querySelectorAll('figure').forEach(figure=>{const marker=document.createElement('p');marker.textContent='[IMAGE '+figure.dataset.imageNumber.padStart(2,'0')+' — insert the matching screenshot here]';figure.replaceWith(marker);});
 clone.querySelectorAll('[data-copy-ui]').forEach(el=>el.remove());
 clone.querySelectorAll('aside').forEach(el=>{const quote=document.createElement('blockquote');quote.innerHTML=el.innerHTML;el.replaceWith(quote);});
 try{
 if(navigator.clipboard && window.ClipboardItem && window.isSecureContext){
 await navigator.clipboard.write([new ClipboardItem({'text/html':new Blob([clone.innerHTML],{type:'text/html'}),'text/plain':new Blob([clone.innerText||clone.textContent],{type:'text/plain'})})]);
 }else{
 const holder=document.createElement('div');holder.contentEditable=true;holder.innerHTML=clone.innerHTML;document.body.append(holder);
 const range=document.createRange();range.selectNodeContents(holder);const selection=window.getSelection();selection.removeAllRanges();selection.addRange(range);
 const ok=document.execCommand('copy');holder.remove();selection.removeAllRanges();if(!ok)throw new Error('copy unsupported');
 }
 tell('排版正文已复制（图片位置已标记）。粘贴后逐张上传图片，并删除 [IMAGE] 标记。');
 }catch{tell('此浏览器阻止了剪贴板操作，请手动复制正文，配图使用下载后上传。');}
};
document.querySelectorAll('[data-image]').forEach(button=>button.onclick=async()=>{
 const item=imageData.find(image=>image.id===Number(button.dataset.image));
 try{
 if(!navigator.clipboard||!window.ClipboardItem)throw new Error('unsupported');
 const bytes=Uint8Array.from(atob(item.data),char=>char.charCodeAt(0));
 await navigator.clipboard.write([new ClipboardItem({'image/png':new Blob([bytes],{type:'image/png'})})]);
 tell('配图 '+String(item.id).padStart(2,'0')+' 已复制。到 Substack 对应位置粘贴并等待上传；若无反应，下载原图后上传。');
 }catch{tell('此浏览器不支持复制图片。请点击这张图旁的“下载原图”，再在 Substack 用图片按钮上传。');}
});
""".replace('__IMAGE_DATA__',json.dumps(image_entries))
with zipfile.ZipFile(root/'substack-images.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for item in image_entries:
        archive.write(root/'upload-images'/item['filename'],item['filename'])
    archive.writestr('README.txt','01 calculation: after the 108 metres flat bar paragraph.\n02 feature overview: after the SteelFlow workflow paragraph.\n03 PDF preview: after the feature overview caption.\nUpload each image into Substack. Remove [IMAGE] markers before publishing. Keep the original captions.\n')
(root/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><meta name="description" content="'+desc+'"><style>'+style+'</style></head><body><header><img src="../2026-09-10-compare-steel-prices/assets/app-icon.png" alt="SteelFlow icon"><b>SteelFlow</b><span>FIELD NOTES · SEP 2026</span></header>'+controls+'<main>'+''.join(blocks)+'</main><footer>Screenshots: SteelFlow 1.1.0 (13), iOS 26.5 simulator. Demo routes display actual app views without the main tab shell. All customer and pricing data is fictional.<br>Editorial draft, not yet published.</footer><script>'+script+'</script></body></html>')
print('Built copy-ready article, 3 image files and ZIP.')
