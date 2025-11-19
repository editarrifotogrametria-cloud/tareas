@echo off
echo ╔════════════════════════════════════════════════════╗
echo ║   📍 GNSS Point Collector - Comnav                ║
echo ╚════════════════════════════════════════════════════╝
echo.

REM Verificar si Python está instalado
python --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Python detectado
    echo 🚀 Iniciando servidor web en puerto 8080...
    echo.
    echo 📱 Abre tu navegador en: http://localhost:8080
    echo.
    echo 🛑 Presiona Ctrl+C para detener el servidor
    echo.
    python -m http.server 8080
    goto :end
)

REM Verificar si Node.js está instalado
node --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Node.js detectado
    echo 🚀 Iniciando servidor web en puerto 8080...
    echo.
    echo 📱 Abre tu navegador en: http://localhost:8080
    echo.
    echo 🛑 Presiona Ctrl+C para detener el servidor
    echo.
    npx http-server -p 8080
    goto :end
)

echo ❌ No se encontró Python ni Node.js
echo.
echo Por favor instala uno de los siguientes:
echo   - Python 3: https://www.python.org/downloads/
echo   - Node.js: https://nodejs.org/
echo.
echo O abre directamente index.html en tu navegador
echo.
pause

:end
