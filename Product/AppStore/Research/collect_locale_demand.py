#!/usr/bin/env python3
"""Read public storefront evidence; no account access or store mutations."""
import concurrent.futures
import datetime as dt
import importlib.util
import json
import pathlib
import time
import urllib.parse

ROOT = pathlib.Path(__file__).parent
OUT = ROOT / '2026-09-27-localization'
OUT.mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location('research', pathlib.Path.home() / '.codex/skills/find-ios-app-opportunities/scripts/app_store_research.py')
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)
QUERIES = {
    'us': ['metal weight calculator', 'steel weight calculator'],
    'de': ['Metallgewicht Rechner', 'Stahl Gewicht Rechner'],
    'jp': ['金属重量計算', '鋼材重量計算'],
    'kr': ['금속 무게 계산기', '철강 중량 계산'],
    'tw': ['鋼材重量計算', '金屬重量計算器'],
    'br': ['calculadora peso metal', 'peso aço'],
    'mx': ['calculadora peso metal', 'peso acero'],
    'es': ['calculadora peso metal', 'peso acero'],
    'tr': ['metal ağırlık hesaplama', 'çelik ağırlık hesaplama'],
    'ru': ['металлокалькулятор', 'калькулятор металла'],
    'fr': ['calcul poids métal', 'calcul poids acier'],
    'it': ['calcolo peso metalli', 'peso acciaio'],
    'pl': ['kalkulator wagi metalu', 'kalkulator stali'],
    'in': ['metal weight calculator', 'steel weight calculator'],
    'vn': ['tính trọng lượng thép', 'tính khối lượng thép'],
    'id': ['kalkulator berat besi', 'berat baja'],
    'sa': ['حاسبة وزن الحديد', 'metal weight calculator'],
}
IDS = ['6806282417', '6455635445', '6456941823', '6749879113', '1442079573', '1291109620', '1381240441']

def save(name, rows):
    (OUT / name).write_text(json.dumps(rows, ensure_ascii=False, indent=2))

def apple():
    opener = r.build_opener(False)
    lookups, searches = [], []
    for country, terms in QUERIES.items():
        item = {'country': country, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat()}
        try:
            url = 'https://itunes.apple.com/lookup?' + urllib.parse.urlencode({'id': ','.join(IDS), 'country': country})
            item.update(sourceURL=url, raw=r.fetch_json(url, opener=opener, timeout=25))
        except Exception as exc:
            item['error'] = str(exc)
        lookups.append(item)
        save('apple-lookup.json', lookups)
        print('LOOKUP ' + country, flush=True)
        time.sleep(3.2)
        for term in terms:
            item = {'country': country, 'term': term, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'requestedLimit': 30, 'source': 'Apple Search API order, not verified organic rank'}
            try:
                item['results'] = r.search_apps(term, country, 30, opener=opener, timeout=25)
            except Exception as exc:
                item['error'] = str(exc)
            searches.append(item)
            save('apple-search.json', searches)
            print('APPLE ' + country + ' ' + term + ' ' + str(len(item.get('results', []))), flush=True)
            time.sleep(3.2)

def kwtrack():
    opener = r.build_opener(False)
    rows = []
    for country, terms in QUERIES.items():
        for term in terms:
            try:
                item = r.get_keyword(term, country, opener=opener, timeout=25)
            except Exception as exc:
                item = {'country': country, 'term': term, 'error': str(exc), 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat()}
            rows.append(item)
            save('kwtrack.json', rows)
            print('KW ' + json.dumps(item, ensure_ascii=False), flush=True)
            time.sleep(4)

if __name__ == '__main__':
    save('query-plan.json', QUERIES)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(apple), pool.submit(kwtrack)]
        for future in futures:
            future.result()
