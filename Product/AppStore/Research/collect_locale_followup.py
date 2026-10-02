#!/usr/bin/env python3
"""Adaptive query variants, run after the first pass to avoid bursts."""
import json
import time
import datetime as dt
import collect_locale_demand as base

QUERIES = {
    'de': ['Metallrechner', 'Stahlrechner'],
    'kr': ['금속 계산기', '중량 계산기'],
    'br': ['calculadora de metais', 'peso de metais'],
    'mx': ['calculadora de metales'],
    'es': ['calculadora de metales'],
    'tr': ['metal hesaplama', 'metal ağırlık', 'profil ağırlık hesaplama', 'metal weight calculator'],
    'fr': ['calculatrice métal', 'calculateur métal'],
    'it': ['calcolatore metalli', 'calcolatrice metalli'],
}

if __name__ == '__main__':
    rows, searches = [], []
    opener = base.r.build_opener(False)
    for country, terms in QUERIES.items():
        for term in terms:
            try:
                row = base.r.get_keyword(term, country, opener=opener, timeout=25)
            except Exception as exc:
                row = {'country': country, 'term': term, 'error': str(exc)}
            rows.append(row)
            base.save('kwtrack-followup.json', rows)
            print(json.dumps(row,ensure_ascii=False), flush=True)
            time.sleep(4)
    for country, terms in QUERIES.items():
        for term in terms:
            item = {'country': country, 'term': term, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'requestedLimit': 30}
            try:
                item['results'] = base.r.search_apps(term, country, 30, opener=opener, timeout=25)
            except Exception as exc:
                item['error'] = str(exc)
            searches.append(item)
            base.save('apple-search-followup.json', searches)
            print('APPLE ' + country + ' ' + term, flush=True)
            time.sleep(4)
