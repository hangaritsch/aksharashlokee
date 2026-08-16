import os
import json
import re
import subprocess
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

SHLOKA_FILE = os.path.join(os.path.dirname(__file__), 'aksharashlokee_mobile/assets/shlokas.json')
LOG_FILE = os.path.join(os.path.dirname(__file__), 'resolver.log')
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

        # Realtime JSON API for Instant Search
        if path == '/api/shlokas':
            data = load_data()
            shlokas = data.get('aksharas', [])
            raw_q = query.get('q', [''])[0].strip()

            filtered = []
            if not raw_q:
                filtered = shlokas
            else:
                q_lower = raw_q.lower()
                for s in shlokas:
                    content_str = s.get('content', '')
                    ref_str = s.get('reference', '')
                    akshara_str = s.get('akshara', '')
                    
                    if (raw_q in content_str or raw_q in ref_str or raw_q in akshara_str or
                        q_lower in content_str.lower() or q_lower in ref_str.lower() or q_lower in akshara_str.lower()):
                        filtered.append(s)

            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'count': len(filtered), 'shlokas': filtered[:100]}, ensure_ascii=False).encode('utf-8'))
            return

        # Realtime Live Logs Stream API
        if path == '/api/resolver-logs':
            log_content = "Terminal standby..."
            if os.path.exists(LOG_FILE):
                with open(LOG_FILE, 'r', encoding='utf-8') as f:
                    log_content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(log_content.encode('utf-8'))
            return

        # Edit Shloka Page
        if path.startswith('/edit/'):
            shloka_id = path.split('/edit/')[1]
            data = load_data()
            target = next((s for s in data.get('aksharas', []) if str(s.get('_id')) == str(shloka_id)), None)
            if not target:
                self.send_response(404)
                self.end_headers()
                return

            edit_html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Edit Shloka #{target['_id']}</title>
                <style>
                    body {{ font-family: sans-serif; background: #FAF8F5; padding: 20px; }}
                    .card {{ background: white; padding: 25px; border-radius: 12px; max-width: 650px; margin: auto; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }}
                    label {{ font-weight: bold; display: block; margin-top: 15px; font-size: 14px; }}
                    textarea, input {{ width: 100%; padding: 12px; border: 1px solid #CCC; border-radius: 8px; box-sizing: border-box; font-size: 16px; margin-top: 5px; }}
                    .btn {{ background: #800000; color: white; border: none; padding: 12px 20px; border-radius: 8px; cursor: pointer; font-weight: bold; margin-top: 20px; text-decoration: none; display: inline-block; font-size: 15px; }}
                </style>
            </head>
            <body>
                <div class="card">
                    <h2>✏️ Edit Shloka #{target['_id']}</h2>
                    <form action="/update/{target['_id']}" method="POST">
                        <label>Sanskrit Content:</label>
                        <textarea name="content" rows="6" required>{target.get('content', '')}</textarea>
                        <label>Reference (Grantha & Verse):</label>
                        <input type="text" name="reference" value="{target.get('reference', '')}" required>
                        <button type="submit" class="btn">Save Changes</button>
                        <a href="/" class="btn" style="background: #7F8C8D;">Cancel</a>
                    </form>
                </div>
            </body>
            </html>
            """
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(edit_html.encode('utf-8'))
            return

        # Delete Action
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

        # Main Dashboard Page
        msg = query.get('msg', [''])[0]

        html = f"""
        <!DOCTYPE html>
        <html lang="sa">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>अक्षरश्लोकी Admin Dashboard & Realtime Manager</title>
            <style>
                :root {{ --maroon: #800000; --saffron: #D35400; --gold: #FFF9E3; }}
                body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #FAF8F5; color: #2D1410; margin: 0; padding: 20px; }}
                .header {{ background: var(--maroon); color: white; padding: 20px; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; }}
                .header h1 {{ margin: 0; font-size: 24px; }}
                .btn {{ background: var(--saffron); color: white; border: none; padding: 10px 16px; border-radius: 8px; font-weight: bold; cursor: pointer; text-decoration: none; display: inline-block; }}
                .btn:hover {{ opacity: 0.9; }}
                .btn-danger {{ background: #C0392B; }}
                .btn-green {{ background: #27AE60; }}
                .btn-blue {{ background: #2980B9; }}
                .card {{ background: white; border-radius: 12px; padding: 20px; margin-top: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 15px; }}
                th, td {{ text-align: left; padding: 12px; border-bottom: 1px solid #EEE; }}
                th {{ background: var(--gold); color: var(--maroon); }}
                .form-group {{ margin-bottom: 15px; }}
                label {{ display: block; font-weight: bold; margin-bottom: 5px; }}
                input, textarea, select {{ width: 100%; padding: 10px; border: 1px solid #DDD; border-radius: 6px; box-sizing: border-box; font-size: 15px; }}
                .badge {{ background: #E8F8F5; color: #117A65; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }}
                .terminal {{ background: #1E1E1E; color: #00FF66; font-family: monospace; padding: 15px; border-radius: 8px; height: 200px; overflow-y: auto; white-space: pre-wrap; font-size: 13px; margin-top: 10px; line-height: 1.5; }}
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
                        <button type="submit" class="btn btn-blue">🔍 Auto-Resolve References (Zero Tokens)</button>
                    </form>
                </div>
            </div>

            {f'<div style="background: #E8F8F5; color: #117A65; padding: 15px; border-radius: 8px; margin-top: 20px;">{msg}</div>' if msg else ''}

            <!-- Real-time Live Terminal Box -->
            <div class="card">
                <h3 style="margin: 0; color: var(--maroon);">⚡ Live Terminal Console (Reference Resolver Stream)</h3>
                <div id="terminal" class="terminal">Initializing stream console...</div>
            </div>

            <!-- Add Shloka Card -->
            <div class="card">
                <h2>➕ Add New Shloka</h2>
                <form action="/add" method="POST">
                    <div style="display: flex; gap: 15px;">
                        <div style="flex: 2;" class="form-group">
                            <label>Shloka Content (Sanskrit):</label>
                            <textarea name="content" rows="3" required placeholder="वागर्थविव संपृक्तौ वागर्थप्रतिपत्तये..."></textarea>
                        </div>
                        <div style="flex: 1;" class="form-group">
                            <label>Reference:</label>
                            <input type="text" name="reference" placeholder="रघुवंशम्, 1/1" required>
                            <button type="submit" class="btn" style="margin-top: 15px; width: 100%;">Add Shloka</button>
                        </div>
                    </div>
                </form>
            </div>

            <!-- Real-time Filterable Table -->
            <div class="card">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <h2>📚 Corpus Database Manager (<span id="total-count">...</span> Shlokas)</h2>
                    <div style="display: flex; gap: 10px; width: 60%;">
                        <input type="text" id="search-input" placeholder="⚡ Realtime Search (Type Content, Reference, Akshara)..." oninput="fetchShlokas()">
                    </div>
                </div>

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
                    <tbody id="shloka-table-body">
                        <!-- Loaded via JS -->
                    </tbody>
                </table>
            </div>

            <script>
                // Fetch Live Terminal Logs
                function updateTerminal() {{
                    fetch('/api/resolver-logs')
                        .then(res => res.text())
                        .then(data => {{
                            const term = document.getElementById('terminal');
                            term.innerText = data || 'Terminal standby...';
                            term.scrollTop = term.scrollHeight;
                        }});
                }}
                setInterval(updateTerminal, 2000);
                updateTerminal();

                // Fetch & Filter Shlokas Realtime
                function fetchShlokas() {{
                    const query = document.getElementById('search-input').value;
                    fetch('/api/shlokas?q=' + encodeURIComponent(query))
                        .then(res => res.json())
                        .then(data => {{
                            document.getElementById('total-count').innerText = data.count;
                            const tbody = document.getElementById('shloka-table-body');
                            tbody.innerHTML = '';

                            data.shlokas.forEach(s => {{
                                const tr = document.createElement('tr');
                                tr.innerHTML = `
                                    <td>${{s._id}}</td>
                                    <td><span class="badge">${{s.akshara}}</span></td>
                                    <td style="white-space: pre-line; max-width: 400px;">${{s.content}}</td>
                                    <td><b>${{s.reference}}</b></td>
                                    <td>
                                        <a href="/edit/${{s._id}}" class="btn" style="padding: 4px 8px; font-size: 12px;">Edit</a>
                                        <a href="/delete/${{s._id}}" class="btn btn-danger" onclick="return confirm('Delete shloka?');" style="padding: 4px 8px; font-size: 12px; margin-left: 4px;">Delete</a>
                                    </td>
                                `;
                                tbody.appendChild(tr);
                            }});
                        }});
                }}
                fetchShlokas();
            </script>
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

        if self.path.startswith('/update/'):
            shloka_id = self.path.split('/update/')[1]
            content = post_data.get('content', [''])[0].strip()
            reference = post_data.get('reference', [''])[0].strip()

            if content and reference:
                data = load_data()
                shlokas = data.get('aksharas', [])
                for s in shlokas:
                    if str(s.get('_id')) == str(shloka_id):
                        s['content'] = content
                        s['reference'] = reference
                        s['akshara'] = extract_akshara(content)
                        s['updated_at'] = time.strftime("%m/%d/%Y %H:%M")
                        break
                save_data(data)
                self.send_response(303)
                self.send_header('Location', f'/?msg=Shloka+#{shloka_id}+updated!')
                self.end_headers()
                return

        elif self.path == '/add':
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
                self.send_header('Location', f'/?msg=Shloka+#{max_id}+added!')
                self.end_headers()
                return

        elif self.path == '/resolve-references':
            subprocess.Popen(['/usr/bin/python3', os.path.join(os.path.dirname(__file__), 'resolve_references.py')])
            self.send_response(303)
            self.send_header('Location', '/?msg=Reference+resolver+started!+Watch+terminal+console+below.')
            self.end_headers()
            return

        elif self.path == '/build/android':
            subprocess.Popen(['flutter', 'build', 'apk', '--release'], cwd=PROJECT_DIR)
            self.send_response(303)
            self.send_header('Location', '/?msg=Android+Release+build+launched!')
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
