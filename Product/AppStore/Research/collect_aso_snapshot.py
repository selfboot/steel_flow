#!/usr/bin/env python3
"""Read-only Apple search/lookup snapshot. Positions are API order, not device ranks."""
import datetime as dt
import importlib.util
import json
import pathlib
import time

SKILL = pathlib.Path.home() / '.codex/skills/find-ios-app-opportunities/scripts/app_store_research.py'
spec = importlib.util.spec_from_file_location('research', SKILL)
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)
opener = r.build_opener(False)
APP_ID = 6806282417
stamp = dt.datetime.now(dt.timezone.utc).astimezone().strftime('%Y-%m-%d')
out = pathlib.Path(__file__).parent / stamp
if out.exists():
    out = out / dt.datetime.now(dt.timezone.utc).strftime('%H%M%S-%fZ')
out.mkdir(parents=True, exist_ok=False)
print('Saving snapshot to ' + str(out), flush=True)
queries = {
    'us': ['SteelFlow', 'metal calculator', 'metal weight calculator', 'steel weight calculator', 'pipe weight calculator', 'tube weight calculator', 'fabrication calculator', 'metal cost calculator'],
    'cn': ['SteelFlow', '钢材重量计算器', '钢材计算器', '金属重量计算器', '材料重量计算器', '钢管重量计算器', '钢材报价', '算料'],
    'gb': ['metal weight calculator'],
    'ca': ['metal weight calculator'],
    'au': ['metal weight calculator'],
}
snapshots = []
for country, terms in queries.items():
    for term in terms:
        item = {'country': country, 'term': term, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'requestedLimit': 200, 'source': 'Apple Search API; ordinal is not a verified iPhone organic rank'}
        try:
            rows = r.search_apps(term, country, 200, opener=opener, timeout=20)
            item.update(results=rows, returnedCount=len(rows), position=next((a['searchRank'] for a in rows if a['id'] == APP_ID), None))
        except Exception as exc:
            item['error'] = str(exc)
        snapshots.append(item)
        (out / 'apple-search.json').write_text(json.dumps(snapshots, ensure_ascii=False, indent=2))
        print(json.dumps({k: v for k, v in item.items() if k != 'results'}, ensure_ascii=False), flush=True)
        time.sleep(3.2)

lookups = []
competitors = {'us': ['6455635445', '6456941823', '6749879113', '1442079573', '1291109620'], 'cn': ['6742086859', '533094372', '1297108312', '6778304774', '6779890043']}
for country in queries:
    item = {'country': country, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat()}
    try:
        item['apps'] = r.lookup_apps([str(APP_ID)] + competitors.get(country, []), country, opener=opener, timeout=20, include_description=True)
    except Exception as exc:
        item['error'] = str(exc)
    lookups.append(item)
    (out / 'apple-lookup.json').write_text(json.dumps(lookups, ensure_ascii=False, indent=2))
    own = [{k: v for k, v in a.items() if k in ['id', 'name', 'ratings', 'rating', 'released', 'updated', 'version', 'url']} for a in item.get('apps', []) if a['id'] == APP_ID]
    print(json.dumps({'lookupCountry': country, 'ownApp': own, 'error': item.get('error')}, ensure_ascii=False), flush=True)
    time.sleep(3.2)
