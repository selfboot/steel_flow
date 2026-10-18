"""Update the existing screenshot editor, preserving its rendering pipeline."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[4]
base=Path(__file__).resolve().parents[1]
p=root/'Product/AppStore/ScreenshotsEditor/app-store-screenshots.json'
j=json.loads((base/'previous-editor-project.json').read_text())
locales=['en-US','en-GB','en-AU','en-CA','zh-Hans','zh-Hant','ja','ko','de-DE','es-ES','es-MX','fr-FR']
english=[('Metal weight. Ready for work.','Dimensions to weight, in seconds.'),('Know the cost before you quote.','Material, waste, fees, margin and tax.'),('Your quote. Your company.','Pro: your logo. No SteelFlow branding.'),('Pick a profile. Start calculating.','Plate, tube, bar, angle and more.'),('The right density. At hand.','Steel, stainless, aluminium and more.'),('Allow for waste and processing.','Your prices. Your job costs.')]
chinese=[('金属重量，快速算清','输入尺寸，即得理论重量'),('材料成本，报价前算明白','材料、损耗、加工费、利润与税费'),('客户报价，用您的品牌','Pro：公司 Logo · 移除 SteelFlow 标识'),('选好型材，马上开算','钢板、钢管、棒材、角钢等'),('材料密度，随手可查','碳钢、不锈钢、铝等常用材料'),('损耗加工费，一并计入','用自己的单价，算实际项目成本')]
quote={
'zh-Hant':('客戶報價，用您的品牌','Pro：公司 Logo · 移除 SteelFlow 標示'),
'ja':('自社ブランドの見積書に','Pro：会社ロゴ付き・SteelFlow表記なし'),
'ko':('우리 회사 이름으로 견적','Pro: 회사 로고 · SteelFlow 표시 제거'),
'de-DE':('Ihr Angebot. Ihre Marke.','Pro: Firmenlogo, ohne SteelFlow-Branding.'),
'es-ES':('Presupuestos con tu marca.','Pro: tu logotipo, sin marca SteelFlow.'),
'es-MX':('Cotizaciones con tu marca.','Pro: tu logotipo, sin marca SteelFlow.'),
'fr-FR':('Vos devis. Votre marque.','Pro : votre logo, sans marque SteelFlow.')}
# Target material buyers and estimators through the actual weight -> cost -> customer quote workflow.
cost={
'zh-Hant':'材料、耗損、加工費、利潤與稅費',
'ja':'材料費・ロス・加工費・利益・税を計算',
'ko':'재료비·로스·가공비·이익·세금',
'de-DE':'Material, Verschnitt, Zuschlag und Steuer.',
'es-ES':'Material, merma, margen e impuestos.',
'es-MX':'Material, merma, margen e impuestos.',
'fr-FR':'Matière, pertes, marge et taxes.'}
for device in ['iphone','ipad']:
 for i,slide in enumerate(j['slidesByDevice'][device]):
  slide['screenshot']=f'/screenshots/aso-20261019/{device}/{{locale}}/{slide["id"]}.png'
  slide['label']={l:'' for l in locales};slide['headline']={l:'' for l in locales}
  for t in slide['textElements']:
   for locale in locales:
    if t['id']=='brand': value='SteelFlow Pro' if i==2 else 'SteelFlow'
    elif locale.startswith('en-'):
     value=english[i][0 if t['id']=='headline' else 1]
     if locale=='en-US':value=value.replace('aluminium','aluminum')
    elif locale=='zh-Hans':value=chinese[i][0 if t['id']=='headline' else 1]
    else:
     value=t['text'].get(locale,t['text'].get('es-ES',''))
     if locale=='es-MX':value=value.replace('costes','costos').replace('presupuestos','cotizaciones').replace('Presupuestos','Cotizaciones').replace('Chapas','Placas y láminas')
     if i==2:value=quote[locale][0 if t['id']=='headline' else 1]
     if i==1 and t['id']=='subtitle':value=cost[locale]
    t['text'][locale]=value
j.update(locales=locales,locale='en-US',device='iphone')
p.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n')
(base/'editor-project.json').write_text(p.read_text())
print('Prepared 12 locales × 6 slides × 2 devices')
