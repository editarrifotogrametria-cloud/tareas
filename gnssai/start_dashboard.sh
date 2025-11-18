#!/bin/bash
# GNSS.AI Dashboard - Start Script
# Author: GNSS.AI Team
# Description: Inicia el servidor Dashboard con todas las funcionalidades

clear
echo "=========================================="
echo "🛰️  GNSS.AI Dashboard - Iniciando..."
echo "=========================================="
echo ""
echo "✨ Funcionalidades:"
echo "  📊 Dashboard en tiempo real"
echo "  🤖 Machine Learning Classification"
echo "  📐 Compensación TILT"
echo "  📡 API REST /api/stats"
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

# Start the dashboard server
echo "🚀 Iniciando Dashboard Server..."
echo ""
python3 dashboard_server.py
