#!/bin/bash

# Script de inicio rápido para GNSS Point Collector

echo "╔════════════════════════════════════════════════════╗"
echo "║   📍 GNSS Point Collector - Comnav                ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Detectar sistema operativo
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    # Linux o macOS
    
    # Verificar si Python está instalado
    if command -v python3 &> /dev/null; then
        echo "✓ Python 3 detectado"
        echo "🚀 Iniciando servidor web en puerto 8080..."
        echo ""
        echo "📱 Abre tu navegador en: http://localhost:8080"
        echo ""
        echo "🛑 Presiona Ctrl+C para detener el servidor"
        echo ""
        python3 -m http.server 8080
    
    # Verificar si Node.js está instalado
    elif command -v node &> /dev/null; then
        echo "✓ Node.js detectado"
        
        # Verificar si http-server está instalado
        if command -v http-server &> /dev/null; then
            echo "🚀 Iniciando servidor web en puerto 8080..."
            echo ""
            echo "📱 Abre tu navegador en: http://localhost:8080"
            echo ""
            echo "🛑 Presiona Ctrl+C para detener el servidor"
            echo ""
            http-server -p 8080
        else
            echo "⚠️  http-server no está instalado"
            echo "Instalando http-server..."
            npm install -g http-server
            echo ""
            echo "🚀 Iniciando servidor web en puerto 8080..."
            echo ""
            echo "📱 Abre tu navegador en: http://localhost:8080"
            echo ""
            http-server -p 8080
        fi
    else
        echo "❌ No se encontró Python 3 ni Node.js"
        echo ""
        echo "Por favor instala uno de los siguientes:"
        echo "  - Python 3: https://www.python.org/downloads/"
        echo "  - Node.js: https://nodejs.org/"
        echo ""
        echo "O abre directamente index.html en tu navegador"
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Sistema Windows detectado"
    echo ""
    echo "Opciones para ejecutar:"
    echo ""
    echo "1. Python:"
    echo "   python -m http.server 8080"
    echo ""
    echo "2. Node.js:"
    echo "   npx http-server -p 8080"
    echo ""
    echo "3. O abre directamente index.html en tu navegador"
fi
