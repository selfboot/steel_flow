import json,sys,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[4];device=sys.argv[1];src=Path(sys.argv[2]);dev=device.lower()
for t in json.loads((src/'manifest.json').read_text()):
 for a in t['attachments']:
  stem=a['suggestedHumanReadableName'].split('_')[0]; locale,screen=stem.rsplit('-',1);locale={'zh-TW':'zh-Hant','ja-JP':'ja','ko-KR':'ko'}.get(locale,locale)
  dest=root/f'Product/AppStore/ScreenshotsEditor/public/screenshots/localized-20260928/{dev}/{locale}/{screen}.png';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src/a['exportedFileName'],dest)
print('Copied',device, 'from', src)
