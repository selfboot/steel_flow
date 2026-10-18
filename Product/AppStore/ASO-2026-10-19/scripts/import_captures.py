import json,sys,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[4]
device,folder=sys.argv[1:3];src=Path(folder)
count=0
for test in json.loads((src/'manifest.json').read_text()):
 for a in test['attachments']:
  name=a['suggestedHumanReadableName']
  if not name.endswith('.png'):continue
  stem=name.split('_')[0]
  try:locale,screen=stem.rsplit('-',1)
  except ValueError:continue
  locale={'zh-TW':'zh-Hant','ja-JP':'ja','ko-KR':'ko'}.get(locale,locale)
  if screen not in ['home','calculation','pricing','project','quote','materials']:continue
  dest=root/f'Product/AppStore/ScreenshotsEditor/public/screenshots/aso-20261019/{device}/{locale}/{screen}.png'
  dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src/a['exportedFileName'],dest);count+=1
print(f'Imported {count} actual {device} captures')
