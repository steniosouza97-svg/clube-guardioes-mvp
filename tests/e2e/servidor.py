"""Réplica local mínima do Supabase para teste ponta a ponta da interface.
- /rest/v1/*  -> PostgREST (mesmo motor de API do Supabase), com as mesmas regras do banco
- /auth/v1/*  -> login simulado que emite JWT com e-mail, como o Supabase Auth
- demais      -> arquivos estáticos de web/, com config.js apontando para esta réplica
"""
import base64, hashlib, hmac, json, time, uuid, urllib.request, urllib.error
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

SEGREDO = b"segredo-local-de-teste-com-mais-de-32-caracteres"
USUARIOS = {"voluntario@example.com": "senha-teste", "curioso@example.com": "senha-teste"}
WEB = Path(__file__).resolve().parents[2] / "web"
PGRST = "http://127.0.0.1:3001"

def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()
def jwt(claims):
    cab = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode()); corpo = b64(json.dumps(claims).encode())
    ass = b64(hmac.new(SEGREDO, f"{cab}.{corpo}".encode(), hashlib.sha256).digest())
    return f"{cab}.{corpo}.{ass}"

class H(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k): super().__init__(*a, directory=str(WEB), **k)
    def log_message(self, *a): pass
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS")
    def do_OPTIONS(self): self.send_response(204); self._cors(); self.end_headers()
    def _json(self, cod, obj):
        d = json.dumps(obj).encode(); self.send_response(cod); self._cors()
        self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(d))); self.end_headers(); self.wfile.write(d)
    def _auth(self):
        if self.path.startswith("/auth/v1/token"):
            corpo = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
            email = corpo.get("email", "").lower()
            if USUARIOS.get(email) != corpo.get("password"):
                return self._json(400, {"error": "invalid_grant", "error_description": "Invalid login credentials", "msg": "Invalid login credentials", "code": 400})
            agora = int(time.time()); uid = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            user = {"id": uid, "aud": "authenticated", "role": "authenticated", "email": email, "app_metadata": {}, "user_metadata": {}, "created_at": "2026-09-28T00:00:00Z"}
            tok = jwt({"sub": uid, "aud": "authenticated", "role": "authenticated", "email": email, "iat": agora, "exp": agora + 3600})
            return self._json(200, {"access_token": tok, "token_type": "bearer", "expires_in": 3600, "expires_at": agora + 3600, "refresh_token": "local", "user": user})
        if self.path.startswith("/auth/v1/logout"):
            self.send_response(204); self._cors(); self.end_headers(); return
        return self._json(404, {"msg": "não simulado"})
    def _rest(self):
        n = int(self.headers.get("Content-Length", 0)); corpo = self.rfile.read(n) if n else None
        req = urllib.request.Request(PGRST + self.path[len("/rest/v1"):], data=corpo, method=self.command)
        for k, v in self.headers.items():
            if k.lower() in ("host", "content-length", "apikey", "connection", "origin", "referer"): continue
            if k.lower() == "authorization" and v.count(".") != 2: continue   # chave publicável não é JWT
            req.add_header(k, v)
        try: r = urllib.request.urlopen(req); cod, dados, hdr = r.status, r.read(), r.headers
        except urllib.error.HTTPError as e: cod, dados, hdr = e.code, e.read(), e.headers
        self.send_response(cod); self._cors()
        for k in ("Content-Type", "Content-Range", "Preference-Applied"):
            if hdr.get(k): self.send_header(k, hdr.get(k))
        self.send_header("Content-Length", str(len(dados))); self.end_headers(); self.wfile.write(dados)
    def do_GET(self):
        if self.path.startswith("/rest/v1"): return self._rest()
        if self.path.startswith("/auth/v1"): return self._auth()
        if self.path.split("?")[0] == "/config.js":
            d = b'window.CLUBE_CONFIG = { supabaseUrl: "http://localhost:8080", supabaseKey: "sb_publishable_local", demonstracao: true, guardiaoDemo: { telefone: "(11) 90000-0050", cpf: "800.000.050-45" } };'
            self.send_response(200); self.send_header("Content-Type", "application/javascript"); self.send_header("Content-Length", str(len(d))); self.end_headers(); self.wfile.write(d); return
        return super().do_GET()
    def do_POST(self):
        if self.path.startswith("/rest/v1"): return self._rest()
        if self.path.startswith("/auth/v1"): return self._auth()
        self.send_error(404)
    do_PATCH = do_DELETE = _rest

ThreadingHTTPServer(("127.0.0.1", 8080), H).serve_forever()
