from pathlib import Path
import json
root=Path(__file__).resolve().parents[4]
base=Path(__file__).resolve().parents[1]
source=root/'Product/AppStore/Metadata'
j=json.loads((source/'metadata.json').read_text())
promo={
'en-US':'Metal weight to client quote: include waste, processing, margin and tax. Upgrade once to Pro for your company logo and PDFs without SteelFlow branding.',
'zh-Hans':'面向金属加工、钢材贸易与材料采购：从尺寸算重，到损耗、加工费、利润和税费核算，再生成客户报价。Pro 一次买断，添加公司 Logo 并移除 PDF 中的 SteelFlow 标识。',
'zh-Hant':'從尺寸算重，到耗損、加工費、利潤與稅費，再產生客戶報價。適合金屬加工與材料採購。Pro 一次買斷，加入公司 Logo 並移除 PDF 中的 SteelFlow 標示。',
'ja':'鋼材の重量から材料費、ロス、加工費、利益、税まで計算し、顧客向けPDF見積書を作成。買い切りProで会社ロゴを追加し、PDFのSteelFlow表記を削除できます。',
'ko':'금속 중량부터 재료비, 로스, 가공비, 이익과 세금까지 계산하고 고객용 PDF 견적서를 만드세요. Pro 일회성 구매로 회사 로고를 넣고 SteelFlow 표시를 제거할 수 있습니다.',
'de-DE':'Vom Metallgewicht zum Angebot: Material, Verschnitt, Zuschlag und Steuer kalkulieren. Pro einmal kaufen: Firmenlogo und PDFs ohne SteelFlow-Branding.',
'es-ES':'Del peso al presupuesto: material, merma, margen e impuestos. Compra Pro una vez para añadir tu logotipo y exportar PDF sin la marca SteelFlow.',
'es-MX':'Del peso a la cotización: material, merma, margen e impuestos. Compra Pro una vez para añadir tu logotipo y exportar PDF sin la marca SteelFlow.',
'fr-FR':'Du poids au devis : matière, pertes, marge et taxes. Un achat Pro ajoute votre logo et retire la marque SteelFlow des PDF.'}
quote_pro={
'zh-Hant':'Pro 可加入公司資料與 Logo，移除 PDF 中的 SteelFlow 標示。',
'ja':'Proでは会社情報とロゴを追加し、PDFからSteelFlow表記を削除できます。',
'ko':'Pro에서는 회사 정보와 로고를 추가하고 PDF의 SteelFlow 표시를 제거할 수 있습니다.',
'de-DE':'Mit Pro ergänzen Sie Firmendaten und Logo und entfernen das SteelFlow-Branding aus PDFs.',
'es-ES':'Con Pro, añade los datos y el logotipo de tu empresa y elimina la marca SteelFlow del PDF.',
'es-MX':'Con Pro, añade los datos y el logotipo de tu empresa y elimina la marca SteelFlow del PDF.',
'fr-FR':'Avec Pro, ajoutez les coordonnées et le logo de votre entreprise et retirez la marque SteelFlow des PDF.'}
for locale,item in j['localizations'].items():
 item['promotionalText']=promo['en-US' if locale.startswith('en-') else locale]
 p=source/item['descriptionFile'];s=p.read_text()
 if locale.startswith('en-'):
  s=s.replace('Calculate metal weight from dimensions, check material costs, and turn a project into a PDF quote. SteelFlow works offline with no account required.','For metal fabricators, stock suppliers and estimators: calculate weight from dimensions, include waste and processing costs, then prepare a client PDF quote. Core calculations work offline with no account required.')
  s=s.replace('Create a polished PDF quote or export a machine-friendly CSV material list. Add company and customer details, validity, and notes before sharing.','Share a clear PDF with customer details, line items, totals and validity. Free PDFs include SteelFlow branding. Pro adds your company details and logo, removes SteelFlow branding, and unlocks CSV material lists. One purchase, no subscription.')
  s=s.replace('titanium and more','cast iron').replace('Quick calculations and essential project tools are free.','Quick calculations and up to 2 active projects with 10 items each are free.')
 elif locale=='zh-Hans':
  s=s.replace('输入尺寸计算钢材重量，核算材料成本，并将项目生成 PDF 报价单。SteelFlow 核心功能离线可用，无需注册账号。','面向金属加工、钢材贸易和材料采购：输入尺寸算重量，计入损耗与加工费核算成本，再生成客户 PDF 报价。核心计算离线可用，无需注册账号。')
  s=s.replace('生成排版清晰的 PDF 报价单，或导出便于表格软件处理的 CSV 材料清单。分享前可填写公司、客户、有效期与备注。','免费生成带 SteelFlow 标识的 PDF，展示客户、明细、总额和有效期。Pro 可加入公司资料与 Logo、移除 SteelFlow 标识，并导出 CSV 材料清单；一次买断，无需订阅。')
  s=s.replace('黄铜、钛等','黄铜、铸铁等').replace('快速计算和基础项目工具免费使用。','快速计算免费，可使用 2 个活动项目，每个项目最多 10 个条目。')
 else:
  # Bring the paid business deliverable into the first visible paragraph, before the long feature list.
  paragraphs=s.split('\n\n')
  if quote_pro[locale] not in paragraphs[1]: paragraphs[1]+=' '+quote_pro[locale]
  s='\n\n'.join(paragraphs)
  if locale in ['es-ES','es-MX']:s=s.replace('validez y notas','fecha de validez')
  if locale=='ja':s=s.replace('顧客情報、有効期限、備考を含む','顧客情報と有効期限を含む')
  if locale=='es-MX':
   for a,b in [('COSTES','COSTOS'),('PRESUPUESTOS','COTIZACIONES'),('chapas y pletinas','placas, láminas y soleras'),('chapas','placas'),('un cotización','una cotización'),('del cotización','de la cotización'),('los cotizaciones','las cotizaciones')]:s=s.replace(a,b)
 p.write_text(s)
 out=base/'metadata'/locale;out.mkdir(parents=True,exist_ok=True)
 for k in ['name','subtitle','keywords','promotionalText','whatsNew']:(out/(k+'.txt')).write_text(item[k]+'\n')
 (out/'description.txt').write_text(s.split('\n\n',1)[1] if s.startswith('# ') else s)
(source/'metadata.json').write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n')
