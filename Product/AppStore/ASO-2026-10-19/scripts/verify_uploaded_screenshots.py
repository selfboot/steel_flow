"""Check an asc screenshots list JSON dump against the exact primary PNGs."""
from pathlib import Path
import sys,json,hashlib
root=Path(__file__).resolve().parents[1]
j=json.loads(Path(sys.argv[1]).read_text());locales=json.loads((root/'editor-project.json').read_text())['locales']
assert sorted(l['locale'] for l in j['localizations'])==sorted(locales)
types={'APP_IPHONE_67':('iphone','1320x2868'),'APP_IPAD_PRO_3GEN_129':('ipad','2064x2752')}
count=0
for locale in j['localizations']:
 assert len(locale['sets'])==2
 for group in locale['sets']:
  device,size=types[group['set']['attributes']['screenshotDisplayType']]
  shots=group['screenshots'];assert len(shots)==6
  for i,shot in enumerate(shots,1):
   a=shot['attributes'];name=f'{i:02d}-device-bottom.png';assert a['fileName']==name
   path=root/'exports/ios'/device/size/locale['locale']/name
   assert a['assetDeliveryState']['state']=='COMPLETE',(locale['locale'],name,a['assetDeliveryState'])
   assert a['sourceFileChecksum']==hashlib.md5(path.read_bytes()).hexdigest(),(locale['locale'],device,name,'checksum')
   assert (a['imageAsset']['width'],a['imageAsset']['height'])==tuple(map(int,size.split('x')))
   count+=1
assert count==144
(root/'qa/uploaded-screenshots.json').write_text(json.dumps({'locales':12,'screenshots':count,'state':'COMPLETE','checks':['exact source MD5','dimensions','order','count'],'versionId':j.get('versionId','2cf0c050-54ae-499b-8496-19a7dc203ff9')},indent=2)+'\n')
print('PASS: all 144 uploaded screenshots match exact local PNGs, ordered and COMPLETE')
