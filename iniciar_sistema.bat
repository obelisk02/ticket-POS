@echo off
title Sistema Impresora Termica POS - Tickets SIX
echo =========================================================
echo       INICIANDO DRIVER Y SERVIDOR DE TICKETS SIX POS
echo =========================================================
echo.
echo 1. Comprobando Node.js...
node -v >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Node.js no detectado en el PATH.
    echo Abriendo la aplicacion directamente en tu navegador...
    start "" "index.html"
    pause
    exit /b
)

echo [OK] Node.js detectado.
echo 2. Iniciando Servidor Driver Local en el puerto 3000...
echo.
start "" "http://localhost:3000"
node server.js
pause
