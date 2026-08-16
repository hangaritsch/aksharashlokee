import os
import json
import re
import subprocess
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

SHLOKA_FILE = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile/assets/shlokas.json')
PROJECT_DIR = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile')

def load_data():
    if not os.path.exists(SHLOKA_FILE):
        return {'aksharas': []}
    with open(SHLOKA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_data(data):
    with open(SHLOKA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def extract_akshara(text):
    cleaned = text.strip()
    if not cleaned:
        return 'अ'
    match = re.match(r'^([\u0900-\u097F][\u093E-\u094C\u0901-\u0903]?)', cleaned)
    return match.group(1) if match else cleaned[0]

class AdminHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path.startswith('/delete/'):
            shloka_id = path.split('/delete/')[1]
            data = load_data()
            shlokas = data.get('aksharas', [])
            data['aksharas'] = [s for s in shlokas if str(s.get('_id')) != str(shloka_id)]
            save_data(data)
            self.send_response(303)
            self.send_header('Location', '/?msg=Deleted+successfully')
            self.end_headers()
            return

        data = load_data()
        shlokas = data.get('aksharas', [])
        msg = query.get('msg', [''])[0]

        shloka_rows = ""
        for s in shlokas[:100]:
            shloka_rows += f"""
            <tr>
                <td>{s.get('_id', '')}</td>
                <td><span class="badge">{s.get('akshara', '')}</span></td>
                <td style="white-space: pre-line; max-width: 400px;">{s.get('content', '')}</td>
                <td><b>{s.get('reference', '')}</b></td>
                <td>
                    <a href="/delete/{s.get('_id')}" class="btn btn-danger" onclick="return confirm('Delete shloka?');" style="padding: 4px 8px; font-size: 12px;">Delete</a>
                </td>
            </tr>
            """

        msg_box = f'<div style="background: #E8F8F5; color: #117A65; padding: 15px; border-radius: 8px; margin-top: 20px;">{msg}</div>' if msg else ''

        html = f"""
        <!DOCTYPE html>
        <html lang="sa">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>अक्षरश्लोकी Admin Dashboard & Build Portal</title>
            <style>
                :root {{ --maroon: #800000; --saffron: #D35400; --gold: #FFF9E3; }}
                body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #FAF8F5; color: #2D1410; margin: 0; padding: 20px; }}
                .header {{ background: var(--maroon); color: white; padding: 20px; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; }}
                .header h1 {{ margin: 0; font-size: 24px; }}
                .btn {{ background: var(--saffron); color: white; border: none; padding: 10px 16px; border-radius: 8px; font-weight: bold; cursor: pointer; text-decoration: none; display: inline-block; }}
                .btn:hover {{ opacity: 0.9; }}
                .btn-danger {{ background: #C0392B; }}
                .btn-green {{ background: #27AE60; }}
                .card {{ background: white; border-radius: 12px; padding: 20px; margin-top: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 15px; }}
                th, td {{ text-align: left; padding: 12px; border-bottom: 1px solid #EEE; }}
                th {{ background: var(--gold); color: var(--maroon); }}
                .form-group {{ margin-bottom: 15px; }}
                label {{ display: block; font-weight: bold; margin-bottom: 5px; }}
                input, textarea, select {{ width: 100%; padding: 10px; border: 1px solid #DDD; border-radius: 6px; box-sizing: border-box; }}
                .badge {{ background: #E8F8F5; color: #117A65; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🌺 अक्षरश्लोकी Corpus & Build Manager</h1>
                <div>
                    <form action="/build/android" method="POST" style="display:inline;">
                        <button type="submit" class="btn btn-green">📱 Build Android APK/AAB</button>
                    </form>
                    <form action="/resolve-references" method="POST" style="display:inline; margin-left: 8px;">
                        <button type="submit" class="btn">🔍 Auto-Resolve References (Zero API Tokens)</button>
                    </form>
                </div>
            </div>

            {msg_box}

            <div class="card">
                <h2>➕ Add New Shloka / Import</h2>
                <form action="/add" method="POST">
                    <div style="display: flex; gap: 15px;">
                        <div style="flex: 2;" class="form-group">
                            <label>Shloka Content (Sanskrit Text):</label>
                            <textarea name="content" rows="3" required placeholder="वागर्थविव संपृक्तौ वागर्थप्रतिपत्तये..."></textarea>
                        </div>
                        <div style="flex: 1;" class="form-group">
                            <label>Reference (Grantha & Verse):</label>
                            <input type="text" name="reference" placeholder="रघुवंशम्, 1/1" required>
                            <button type="submit" class="btn" style="margin-top: 15px; width: 100%;">Add & Organize</button>
                        </div>
                    </div>
                </form>
            </div>

            <div class="card">
                <h2>📚 Current Corpus (Total: {len(shlokas)} Shlokas)</h2>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Akshara</th>
                            <th>Content</th>
                            <th>Reference</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {shloka_rows}
                    </tbody>
                </table>
            </div>
        </body>
        </html>
        """
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        post_data = urllib.parse.parse_qs(self.rfile.read(length).decode('utf-8'))

        if self.path == '/add':
            content = post_data.get('content', [''])[0].strip()
            reference = post_data.get('reference', [''])[0].strip()
            if content and reference:
                data = load_data()
                shlokas = data.get('aksharas', [])
                max_id = max([int(s['_id']) for s in shlokas if str(s['_id']).isdigit()] or [0]) + 1
                akshara = extract_akshara(content)
                new_entry = {
                    '_id': str(max_id),
                    'akshara': akshara,
                    'content': content,
                    'reference': reference,
                    'created_at': time.strftime("%m/%d/%Y %H:%M"),
                    'updated_at': time.strftime("%m/%d/%Y %H:%M")
                }
                shlokas.insert(0, new_entry)
                data['aksharas'] = shlokas
                save_data(data)
                self.send_response(303)
                self.send_header('Location', f'/?msg=Shloka+#{max_id}+added+under+{akshara}!')
                self.end_headers()
                return

        elif self.path == '/resolve-references':
            subprocess.Popen(['/usr/bin/python3', os.path.join(os.path.dirname(__file__), 'resolve_references.py')])
            self.send_response(303)
            self.send_header('Location', '/?msg=Automated+reference+resolver+started+(0+API+tokens)!')
            self.end_headers()
            return

        elif self.path == '/build/android':
            subprocess.Popen(['flutter', 'build', 'apk', '--release'], cwd=PROJECT_DIR)
            self.send_response(303)
            self.send_header('Location', '/?msg=Android+Release+build+launched+in+background!')
            self.end_headers()
            return

        self.send_response(303)
        self.send_header('Location', '/')
        self.end_headers()

def run_server(port=5005):
    server = HTTPServer(('0.0.0.0', port), AdminHandler)
    print(f"Server running at http://localhost:{port}")
    server.serve_forever()

if __name__ == '__main__':
    run_server()
