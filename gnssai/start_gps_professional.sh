#!/bin/bash
# GPS Professional - Start Script
# Author: GPS Professional Team
# Description: Inicia el servidor GPS Professional con todas las funcionalidades

clear
echo "=========================================="
echo "🛰️  GPS PROFESSIONAL - Iniciando..."
echo "=========================================="
echo ""
echo "✨ Funcionalidades:"
echo "  📋 Gestión de Proyectos"
echo "  🌍 Selección de DATUM"
echo "  📍 Tomar Puntos GPS/RTK"
echo "  🎯 Replantear Puntos"
echo "  🔧 Comandos PPP"
echo "  📐 Compensación TILT"
echo "  📷 Cámara con EXIF Geolocalizado"
echo ""
echo "=========================================="
echo ""

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python3 no está instalado"
    exit 1
fi

# Check if Flask is installed
python3 -c "import flask" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️  Flask no está instalado. Instalando..."
    pip3 install flask flask-socketio
fi

# Change to script directory
cd "$(dirname "$0")"

# Start the server
echo "🚀 Iniciando servidor GPS Professional..."
echo ""
python3 gps_server.py
