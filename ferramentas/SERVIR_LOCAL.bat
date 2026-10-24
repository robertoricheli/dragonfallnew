@echo off
title DRAGONFALL LOCAL HOST
python "%~dp0servir_local.py" || py -3 "%~dp0servir_local.py"
pause
