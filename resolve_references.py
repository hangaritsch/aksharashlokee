import os
import json
import re
import urllib.request
import urllib.parse
import time
import sys

SHLOKA_FILE = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile/assets/shlokas.json')
LOG_FILE = os.path.join(os.path.dirname(__file__), 'resolver.log')

def log(msg):
    timestamp = time.strftime("%H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted, flush=True)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(formatted + '\n')

def search_reference_online(shloka_text):
    query_line = shloka_text.split('\n')[0].strip()
    clean_query = re.sub(r'[।॥\d\s]+', ' ', query_line)[:40].strip()
    
    if len(clean_query) < 6:
        return None

    try:
        encoded = urllib.parse.quote(f'site:sanskritdocuments.org "{clean_query}"')
        url = f"https://html.duckduckgo.com/html/?q={encoded}"
        
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        )
        
        with urllib.request.urlopen(req, timeout=5) as response:
            html = response.read().decode('utf-8', errors='ignore')
            
            # Simple regex search on snippet blocks (no bs4 dependency needed)
            matches = re.findall(r'([अ-हौअंः॥\s]+(?:रामायण|महाभारत|शतक|संसार|काव्य|पुराण|संहिता|पद्धति|गीता|वृत्ति|भाष्य)[अ-हौअंः॥\s]*)', html)
            for m in matches:
                clean_m = m.strip()
                if len(clean_m) > 4 and len(clean_m) < 40:
                    return clean_m
    except Exception as e:
        pass
        
    return None

def resolve_all_references():
    open(LOG_FILE, 'w', encoding='utf-8').write(f"--- Reference Resolver Engine Started at {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
    log("Initializing dataset inspection...")

    if not os.path.exists(SHLOKA_FILE):
        log("ERROR: Shloka file assets/shlokas.json not found!")
        return

    with open(SHLOKA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    shlokas = data.get('aksharas', [])
    log(f"Corpus loaded: Total {len(shlokas)} shlokas found.")

    target_shlokas = [s for s in shlokas if 'अक्षरश्लोकी सुभाषितसंग्रहः' in s.get('reference', '') or s.get('reference', '') == 'Aksharashlokee' or not s.get('reference', '')]
    log(f"Identified {len(target_shlokas)} shlokas requiring external reference resolution.")

    resolved_count = 0
    for idx, s in enumerate(target_shlokas, 1):
        line = s.get('content', '').split('\n')[0][:35].replace('\n', ' ')
        log(f"[{idx}/{len(target_shlokas)}] Querying ID #{s.get('_id')} ('{line}')...")

        found_ref = search_reference_online(s.get('content', ''))
        if found_ref:
            s['reference'] = found_ref
            s['updated_at'] = time.strftime("%m/%d/%Y %H:%M")
            resolved_count += 1
            log(f"  ✓ FOUND MATCH: '{found_ref}'")
        else:
            log(f"  - No external match. Retaining Subhashita classification.")

        if idx % 5 == 0:
            with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            log(f"Saved dataset progress ({idx}/{len(target_shlokas)} items processed).")

        time.sleep(1)

    with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    log(f"--- Process Complete! Successfully resolved {resolved_count} shlokas. ---")

if __name__ == '__main__':
    resolve_all_references()
