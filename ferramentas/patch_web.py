#!/usr/bin/env python3
"""Patch do build Web (rodar DEPOIS de cada exportacao Web).
O index.html gerado pelo Godot bloqueia o inicio com a mensagem
"Secure Context - use HTTPS" quando a pagina nao esta em HTTPS.
Como o build do Dragonfall NAO usa threads, ele roda perfeitamente em HTTP:
este patch remove esse bloqueio para o jogo ABRIR DIRETO no celular
(sem aviso de certificado, sem tela de erro)."""
import os, re, sys

DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "web_export"))
HTML = os.path.join(DIR, "index.html")
MARK = "/*DRAGONFALL-HTTP-OK*/"

def main() -> int:
    if not os.path.exists(HTML):
        print("patch_web: web_export/index.html nao encontrado; exporte antes.")
        return 1
    s = open(HTML, encoding="utf8").read()
    if MARK in s:
        print("patch_web: ja patchado, nada a fazer.")
        return 0
    n0 = s
    s = s.replace('"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false')
    s = re.sub(
        r"const missing = Engine\.getMissingFeatures\(\{\s*threads: GODOT_THREADS_ENABLED,\s*\}\);",
        "const missing = Engine.getMissingFeatures({\n\t\tthreads: GODOT_THREADS_ENABLED,\n\t})" + MARK + ".filter(function (f) {\n"
        "\t\treturn f.indexOf('Secure Context') !== 0 &&\n"
        "\t\t\tf.indexOf('Cross-Origin Isolation') !== 0 &&\n"
        "\t\t\tf.indexOf('SharedArrayBuffer') !== 0;\n\t});",
        s, count=1)
    if s == n0:
        print("patch_web: AVISO - padrao getMissingFeatures nao encontrado.")
        return 1
    open(HTML, "w", encoding="utf8").write(s)
    print("patch_web: index.html patchado (jogo abre direto em HTTP).")
    return 0

if __name__ == "__main__":
    sys.exit(main())
