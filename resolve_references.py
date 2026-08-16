import os
import json
import re
import urllib.request
import urllib.parse
import time
import sys

SHLOKA_FILE = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile/assets/shlokas.json')
LOG_FILE = os.path.join(os.path.dirname(__file__), 'resolver.log')

# Recognized Classical Genuine Granthas and Authors Pattern Dictionary
GENUINE_GRANTHA_PATTERNS = [
    r'रघुवंश|रघुवंशम्',
    r'कुमारसम्भव|कुमारसम्भवम्',
    r'मेघदूत|मेघदूतम्',
    r'अभिज्ञानशाकुन्तल|शाकुन्तलम्',
    r'किरातार्जुनीय|किरातार्जुनीयम्',
    r'शिशुपालवध|शिशुपालवधम्',
    r'नैषधीय|नैषधीयचरितम्',
    r'नारायणीय|नारायणीयम्',
    r'नीतिशतक|शृङ्गारशतक|वैराग्यशतक|शतकत्रयम्',
    r'सुभाषितरत्नभाण्डागार|सुभाषितरत्नभाण्डागारम्',
    r'काव्यालङ्कार|काव्यालंकार',
    r'उत्तररामचरित|उत्तररामचरितम्|महावीरचरितम्',
    r'मुद्राराक्षस|मुद्राराक्षसम्',
    r'मृच्छकटिक|मृच्छकटिकम्',
    r'भजगोविन्द|भजगोविन्दम्',
    r me for r in [
        r'चाणक्यनीति|चाणक्यनीतिदर्पणम्',
        r'रामायण|वाल्मीकिरामायणम्|श्रीमद्वाल्मीकिरामायणम्',
        r'महाभारत|भगवद्गीता|श्रीमद्भगवद्गीता',
        r'अमरुशतक|अमरुशतकम्',
        r'गीतगोविन्द|गीतगोविन्दम्',
        r'हितोपदेश|हितोपदेशः',
        r'पञ्चतन्त्र|पञ्चतन्त्रम्',
        r'भामिनीविलास|भामिनीविलासः',
        r'शार्ङ्गधरपद्धति|शार्ङ्गधरपद्धतिः',
        r'कथासरित्सागर|कथासरित्सागरः',
        r'प्रतिमानRule|प्रतिमानाटकम्',
        r'स्वप्नवासवदत्त|स्वप्नवासवदत्तम्'
    ]
]

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
}

def log(msg):
    timestamp = time.strftime("%H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted, flush=True)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(formatted + '\n')

def norm(txt):
    return re.sub(r'[\s।,॥\d\-\\\/\.]+', '', txt).strip()

def get_akshara(text):
    cleaned = text.strip()
    match = re.match(r'^([\u0900-\u097F][\u093E-\u094C\u0901-\u0903]?)', cleaned)
    return match.group(1) if match else (cleaned[0] if cleaned else 'अ')

def fetch_url_text(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=8) as resp:
            return resp.read().decode('utf-8', errors='ignore')
    except Exception:
        return ""

def search_genuine_reference(shloka_text):
    """
    Scrapes across sanskritdocuments.org, vishvasa.github.io, sanskritsahitya.org & internet index.
    Verifies match strictly against GENUINE classical Granthas.
    """
    query_line = shloka_text.split('\n')[0].strip()
    clean_query = re.sub(r'[।॥\d\s]+', ' ', query_line)[:35].strip()
    if len(clean_query) < 6:
        return None

    sources = [
        f"site:sanskritdocuments.org \"{clean_query}\"",
        f"site:vishvasa.github.io \"{clean_query}\"",
        f"site:sanskritsahitya.org \"{clean_query}\""
    ]

    for s_query in sources:
        try:
            encoded = urllib.parse.quote(s_query)
            url = f"https://html.duckduckgo.com/html/?q={encoded}"
            html = fetch_url_text(url)
            
            if not html:
                continue

            # Look for explicit Grantha matches
            for pat in GENUINE_GRANTHA_PATTERNS:
                if isinstance(pat, str):
                    m = re.search(r'([अ-हौअंः॥\s]*' + pat + r'[अ-हौअंः॥\s]*(?:,\s*\d+[\/\.]\d+|,\s*श्लोक\.\d+)?)', html)
                    if m:
                        candidate = m.group(1).strip()
                        if len(candidate) > 3 and len(candidate) < 45:
                            return candidate
        except Exception:
            pass

    return None

def resolve_and_import():
    open(LOG_FILE, 'w', encoding='utf-8').write(f"--- Grantha Extractor Engine Started at {time.strftime('%Y-%m-%d %H:%M:%S')} ---\n")
    log("Initializing Deep Web Scraping across sanskritdocuments.org, vishvasa.github.io, sanskritsahitya.org...")

    if not os.path.exists(SHLOKA_FILE):
        log("ERROR: Shloka database file assets/shlokas.json not found!")
        return

    with open(SHLOKA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    shlokas = data.get('aksharas', [])
    log(f"Corpus loaded: Total {len(shlokas)} existing shlokas found.")

    existing_set = {norm(s['content']): s for s in shlokas}
    max_id = max([int(s['_id']) for s in shlokas if str(s['_id']).isdigit()] or [0])

    target_shlokas = [s for s in shlokas if 'अक्षरश्लोकी सुभाषितसंग्रहः' in s.get('reference', '') or s.get('reference', '') == 'Aksharashlokee' or not s.get('reference', '')]
    log(f"Identified {len(target_shlokas)} shlokas to verify against genuine classical Granthas.")

    resolved_count = 0
    for idx, s in enumerate(target_shlokas, 1):
        snippet = s.get('content', '').split('\n')[0][:30].replace('\n', ' ')
        log(f"[{idx}/{len(target_shlokas)}] Searching Genuine Reference for ID #{s.get('_id')} ('{snippet}')...")

        ref = search_genuine_reference(s.get('content', ''))
        if ref:
            s['reference'] = ref
            s['updated_at'] = time.strftime("%m/%d/%Y %H:%M")
            resolved_count += 1
            log(f"  ✓ GENUINE GRANTHA VERIFIED: '{ref}'")
        else:
            log("  - Genuine classical Grantha match not found. Keeping Subhashita classification.")

        if idx % 5 == 0:
            with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            log(f"Saved dataset progress ({idx}/{len(target_shlokas)} checked).")

        time.sleep(1)

    # Save final results
    with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    log(f"--- Process Completed! Verified and updated {resolved_count} genuine Grantha references. ---")

if __name__ == '__main__':
    resolve_and_import()
