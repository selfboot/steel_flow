"""Validate the deliverable. --normalize-rgb strips only a fully opaque alpha channel."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image
parser=argparse.ArgumentParser();parser.add_argument('--normalize-rgb',action='store_true');parser.add_argument('--primary-only',action='store_true');args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
entries=json.loads((root/'editor-project.json').read_text())['locales']
records=[]
sizes={'iphone':[(1320,2868),(1284,2778),(1206,2622),(1125,2436)],'ipad':[(2064,2752),(2048,2732)]}
if args.primary_only:sizes={device:[dims[0]] for device,dims in sizes.items()}
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
assert len(records)==(144 if args.primary_only else 432)
(root/('primary-asset-manifest.json' if args.primary_only else 'asset-manifest.json')).write_text(json.dumps({'count':len(records),'assets':records},ensure_ascii=False,indent=2)+'\n')
print(f'PASS: {len(entries)} metadata localizations; {len(records)} RGB PNGs; dimensions, order, opacity and corners checked.')
