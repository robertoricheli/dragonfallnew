#!/usr/bin/env python3
"""LOCAL HOST do Dragonfall (regra permanente: rodar apos cada atualizacao).
Serve o build Web em HTTP puro na porta 8060 para TODOS os dispositivos:
  PC/neste computador:  http://localhost:8060
  Celular/tablet:       http://SEU_IP:8060   (mesmo Wi-Fi, ABRE DIRETO)
Nao usa HTTPS/certificado: o build Web ja sai patchado (ferramentas/patch_web.py)
para abrir direto sem aviso de seguranca no celular."""
import http.server, socketserver, os, socket

DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "web_export"))

class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=DIR, **kw)
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()
    def log_message(self, *a):
        pass

ips = []
try:
    ips = socket.gethostbyname_ex(socket.gethostname())[2]
except Exception:
    pass
print("=" * 62)
print("DRAGONFALL LOCAL HOST ATIVO (sem certificado, abre direto)")
print("  PC neste computador:       http://localhost:8060")
for ip in ips:
    print("  Celular/tablet (mesmo Wi-Fi): http://%s:8060" % ip)
print("  Feche esta janela para desligar.")
print("=" * 62)
socketserver.TCPServer.allow_reuse_address = True
httpd = socketserver.ThreadingTCPServer(("0.0.0.0", 8060), H)
httpd.serve_forever()
