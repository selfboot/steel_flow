"""Validate the deliverable. --normalize-rgb strips only a fully opaque alpha channel."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image
parser=argparse.ArgumentParser();parser.add_argument('--normalize-rgb',action='store_true');args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
entries=json.loads((root/'localizations.json').read_text())
checks={}
for locale,e in entries.items():
    limits={'name':30,'subtitle':30,'promotionalText':170,'description':4000,'whatsNew':4000}
    checks[locale]={key:len(e[key]) for key in limits}
    for key,limit in limits.items():
        assert 0<len(e[key])<=limit,(locale,key)
        assert (root/'metadata'/locale/(key+'.txt')).read_text().rstrip('\n')==e[key]
    checks[locale]['keywordsUTF8Bytes']=len(e['keywords'].encode('utf-8'))
    assert checks[locale]['keywordsUTF8Bytes']<=100,locale
    assert (root/'metadata'/locale/'keywords.txt').read_text().strip()==e['keywords']
    assert len(e['captions'])==6
    assert all(len(c)==2 and all(c) for c in e['captions'])
records=[]
sizes={'iphone':[(1320,2868),(1284,2778),(1206,2622),(1125,2436)],'ipad':[(2064,2752),(2048,2732)]}
for device,dims in sizes.items():
    for w,h in dims:
        for locale in entries:
            folder=root/'exports/ios'/device/f'{w}x{h}'/locale
            files=sorted(folder.glob('*.png'))
            assert len(files)==6,(str(folder),len(files))
            for i,path in enumerate(files,1):
                assert path.name.startswith(f'{i:02d}-')
                im=Image.open(path);im.load();assert im.size==(w,h),(path,im.size)
                if im.mode=='RGBA':
                    assert im.getchannel('A').getextrema()==(255,255),f'Transparent pixels: {path}'
                    if args.normalize_rgb:
                        rgb=im.convert('RGB');temp=path.with_suffix('.tmp.png');rgb.save(temp,compress_level=6);temp.replace(path);im=Image.open(path)
                assert im.mode=='RGB',(path,im.mode)
                # A dark background must extend to every corner, with no white gutters.
                assert all(max(im.getpixel(p))<150 for p in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]),path
                records.append({'path':str(path.relative_to(root)),'width':w,'height':h,'mode':im.mode,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert len(records)==216
(root/'metadata-validation.json').write_text(json.dumps(checks,indent=2)+'\n')
(root/'asset-manifest.json').write_text(json.dumps({'count':len(records),'assets':records},ensure_ascii=False,indent=2)+'\n')
print(f'PASS: {len(entries)} metadata localizations; {len(records)} RGB PNGs; dimensions, order, opacity and corners checked.')
