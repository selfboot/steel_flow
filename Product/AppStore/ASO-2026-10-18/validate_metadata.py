#!/usr/bin/env python3
"""Validate next-release metadata and ensure upload text matches the canonical source."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent
source=root.parent/'Metadata'
data=json.loads((source/'metadata.json').read_text())
valid_locales={'en-US','en-GB','en-AU','en-CA','zh-Hans','zh-Hant','ja','ko','de-DE','es-ES','es-MX','fr-FR'}
report={}
for locale,item in data['localizations'].items():
    assert locale in valid_locales, locale
    assert len(item['name'])<=30, (locale,'name')
    assert len(item['subtitle'])<=30, (locale,'subtitle')
    assert len(item['keywords'])<=100, (locale,'keywords')
    # A conservative UTF-8 budget also keeps this compatible with existing uploader checks.
    assert len(item['keywords'].encode())<=100, (locale,'keyword bytes')
    assert len(item['promotionalText'])<=170, (locale,'promotional text')
    terms=item['keywords'].casefold().split(',')
    assert len(terms)==len(set(terms)) and all(terms), (locale,'duplicate/empty keywords')
    for field in ['name','subtitle','keywords','promotionalText','whatsNew']:
        assert (root/'metadata'/locale/(field+'.txt')).read_text().rstrip('\n')==item[field], (locale,field)
    description=(source/item['descriptionFile']).read_text()
    if description.startswith('# '):description=description.split('\n\n',1)[1]
    assert len(description)<=4000,(locale,'description')
    assert (root/'metadata'/locale/'description.txt').read_text()==description,(locale,'description mismatch')
    report[locale]={'nameCharacters':len(item['name']),'subtitleCharacters':len(item['subtitle']),
                    'keywordCharacters':len(item['keywords']),'keywordBytes':len(item['keywords'].encode()),
                    'promotionalCharacters':len(item['promotionalText'])}
assert data['app']['price']=='Free'
(root/'metadata-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(f'{len(report)} localizations valid; canonical metadata matches upload text. No price edits.')
