import os
import json
import re
import urllib.request
import urllib.parse
from bs4 import BeautifulSoup
import time

SHLOKA_FILE = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile/assets/shlokas.json')

def clean_text(text):
    return re.sub(r'[\s।,॥\d\-\\\/\.]+', '', text).strip()

def extract_akshara(text):
    cleaned = text.strip()
    if not cleaned:
        return 'अ'
    match = re.match(r'^([\u0900-\u097F][\u093E-\u094C\u0901-\u0903]?)', cleaned)
    return match.group(1) if match else cleaned[0]

def search_reference_online(shloka_text):
    """
    Query open digital archives (SanskritDocuments / Wikisource / Google)
    without using AI LLM API tokens.
    """
    # Take first 15-20 characters of shloka line
    query_line = shloka_text.split('\n')[0].strip()
    clean_query = re.sub(r'[।॥\d\s]+', ' ', query_line)[:40].strip()
    
    if len(clean_query) < 6:
        return None

    try:
        # 1. Search SanskritDocuments site index
        encoded = urllib.parse.quote(f'site:sanskritdocuments.org "{clean_query}"')
        url = f"https://html.duckduckgo.com/html/?q={encoded}"
        
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        )
        
        with urllib.request.urlopen(req, timeout=5) as response:
            html = response.read().decode('utf-8', errors='ignore')
            soup = BeautifulSoup(html, 'html.parser')
            
            snippets = soup.find_all('a', class_='result__snippet')
            for snip in snippets:
                txt = snip.text
                # Try extracting book/author pattern
                match = re.search(r'([अ-हौअंः॥\s]+(?:रामायण|महाभारत|शतक|संसार|काव्य|पुराण|संहिता|पद्धति|गीता|वृत्ति|भाष्य)[अ-हौअंः॥\s]*)', txt)
                if match:
                    found_ref = match.group(1).strip()
                    if len(found_ref) > 3:
                        return found_ref
    except Exception as e:
        pass
        
    return None

def resolve_all_references():
    if not os.path.exists(SHLOKA_FILE):
        print("Shloka file not found.")
        return

    with open(SHLOKA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    shlokas = data.get('aksharas', [])
    updated_count = 0

    print(f"Scanning {len(shlokas)} shlokas for generic or missing references...")

    for idx, s in enumerate(shlokas):
        ref = s.get('reference', '').strip()
        
        # Check if reference is generic
        if 'अक्षरश्लोकी सुभाषितसंग्रहः' in ref or ref == 'Aksharashlokee' or not ref:
            print(f"[{idx+1}/{len(shlokas)}] Finding reference for ID {s.get('_id')}...")
            
            found_ref = search_reference_online(s.get('content', ''))
            if found_ref:
                s['reference'] = found_ref
                s['updated_at'] = time.strftime("%m/%d/%Y %H:%M")
                updated_count += 1
                print(f"  ✓ Resolved reference: {found_ref}")
            else:
                print("  - No external match found. Kept as Subhashita.")
            
            time.sleep(1) # Rate limit request spacing

    # Save back to file
    with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"\nDone! Resolved {updated_count} shloka references.")

if __name__ == '__main__':
    resolve_all_references()
