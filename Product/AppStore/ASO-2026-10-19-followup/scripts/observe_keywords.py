#!/usr/bin/env python3
"""Public search coverage observation, NOT organic App Store rank tracking."""
import argparse
import datetime
import json
from pathlib import Path
import time
import urllib.parse
import urllib.request

QUERIES = [
    ('us', 'metal cost calculator'), ('us', 'metal weight calculator'),
    ('us', 'steel weight calculator'), ('gb', 'metal weight calculator'),
    ('jp', '鋼材重量計算'), ('de', 'blechgewicht'),
    ('mx', 'calculadora peso metal'), ('mx', 'cotización metal'),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Choose a new output path; previous observations are preserved.')
    rows = []
    for country, query in QUERIES:
        row = {'country': country, 'query': query,
               'observedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'source': 'Apple iTunes Search API; NOT App Store organic rank'}
        url = 'https://itunes.apple.com/search?' + urllib.parse.urlencode(
            {'term': query, 'country': country, 'entity': 'software', 'limit': 100})
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                results = json.load(response)['results']
            row.update(resultCount=len(results), apiResultPosition=next(
                (i + 1 for i, app in enumerate(results)
                 if str(app.get('trackId')) == '6806282417'), None))
        except Exception as error:
            row['error'] = str(error)
        rows.append(row)
        time.sleep(3)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
    print(f'Saved {len(rows)} observations; {sum("error" in r for r in rows)} request errors. These are not organic ranks.')

if __name__ == '__main__':
    main()
