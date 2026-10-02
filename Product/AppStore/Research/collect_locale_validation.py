#!/usr/bin/env python3
"""Validate Vietnamese acquisition terms and sample local user reviews."""
import json
import time
import datetime as dt
import collect_locale_demand as base

if __name__ == '__main__':
    opener = base.r.build_opener(False)
    reviews = []
    for country, app_id in [('vn','1442079573'),('tr','1291109620'),('de','1291109620'),('kr','1291109620'),('jp','1291109620'),('in','6749879113')]:
        item = {'country': country, 'appId': app_id, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat()}
        try:
            item['reviews'] = base.r.get_reviews(app_id, country, 5, 20, opener=opener, timeout=25)
        except Exception as exc:
            item['error'] = str(exc)
        reviews.append(item)
        base.save('apple-reviews.json', reviews)
        print('REVIEWS ' + country + ' ' + str(len(item.get('reviews',[]))), flush=True)
        time.sleep(4)
    keywords, searches = [], []
    for term in ['metal weight calculator', 'tính thép', 'tính phôi']:
        try:
            item = base.r.get_keyword(term, 'vn', opener=opener, timeout=25)
        except Exception as exc:
            item = {'country': 'vn', 'term': term, 'error': str(exc)}
        keywords.append(item)
        base.save('kwtrack-validation.json', keywords)
        print(json.dumps(item,ensure_ascii=False),flush=True)
        time.sleep(4)
    # Fetch Apple after reviews and keyword checks to keep requests modest.
    for term in ['metal weight calculator', 'tính thép', 'tính phôi']:
        item = {'country': 'vn', 'term': term, 'queriedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'requestedLimit': 30}
        try:
            item['results'] = base.r.search_apps(term, 'vn', 30, opener=opener, timeout=25)
        except Exception as exc:
            item['error'] = str(exc)
        searches.append(item)
        base.save('apple-search-validation.json', searches)
        print('APPLE VN ' + term,flush=True)
        time.sleep(4)
