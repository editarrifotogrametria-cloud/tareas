#!/bin/bash
# Script de instalación de dependencias para GNSS.AI en Raspberry Pi Zero 2W
# ComNav K222 - Sistema de captura de puntos geodésicos

echo "=========================================="
echo "🛰️  GNSS.AI - Instalador de Dependencias"
echo "=========================================="
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  NO ejecutes este script como root (sin sudo)"
    echo "   El script pedirá permisos cuando los necesite"
    exit 1
fi

# Actualizar sistema
echo "📦 Actualizando sistema..."
sudo apt-get update

# Instalar dependencias del sistema
echo ""
echo "📦 Instalando dependencias del sistema..."
sudo apt-get install -y python3-pip python3-dev python3-serial bluetooth bluez libbluetooth-dev

# Actualizar pip
echo ""
echo "📦 Actualizando pip..."
python3 -m pip install --upgrade pip

# Instalar dependencias Python - CORE
echo ""
echo "🐍 Instalando dependencias Python CORE..."
pip3 install --user pyserial

# Flask y Socket.IO con versiones compatibles
echo ""
echo "🌐 Instalando Flask y Socket.IO (versiones compatibles)..."
pip3 install --user 'Flask>=2.0.0,<3.0.0'
pip3 install --user 'flask-socketio>=5.0.0,<6.0.0'
pip3 install --user 'python-socketio>=5.0.0,<6.0.0'
pip3 install --user 'python-engineio>=4.0.0,<5.0.0'

# Bluetooth (opcional, puede fallar en algunos sistemas)
echo ""
echo "📡 Instalando PyBluez (puede tomar tiempo o fallar)..."
pip3 install --user pybluez || echo "⚠️  PyBluez no se pudo instalar, pero no es crítico"

# ML Dependencies (opcional)
echo ""
read -p "¿Deseas instalar dependencias ML (numpy, pandas, scikit-learn)? Esto puede tomar mucho tiempo en Pi Zero (s/N): " install_ml

if [[ $install_ml =~ ^[Ss]$ ]]; then
    echo "🧠 Instalando dependencias ML..."
    echo "⏳ ADVERTENCIA: Esto puede tomar 30-60 minutos en Pi Zero 2W"
    pip3 install --user numpy pandas scikit-learn joblib
else
    echo "⏭️  Saltando instalación ML"
fi

# Configurar permisos UART
echo ""
echo "🔌 Configurando permisos UART..."
sudo usermod -a -G dialout $USER
sudo usermod -a -G tty $USER

# Configurar Bluetooth (si está disponible)
if command -v bluetoothctl &> /dev/null; then
    echo ""
    echo "📡 Configurando Bluetooth..."
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
fi

# Crear directorios necesarios
echo ""
echo "📁 Creando directorios de trabajo..."
mkdir -p ~/tareas/ml_training_data
mkdir -p ~/tareas/ml_models
mkdir -p ~/tareas/logs

# Verificar instalación
echo ""
echo "=========================================="
echo "✅ Verificando instalación..."
echo "=========================================="

python3 -c "import serial; print('✅ pyserial:', serial.__version__)" || echo "❌ pyserial NO instalado"
python3 -c "import flask; print('✅ Flask:', flask.__version__)" || echo "❌ Flask NO instalado"
python3 -c "import flask_socketio; print('✅ Flask-SocketIO:', flask_socketio.__version__)" || echo "❌ Flask-SocketIO NO instalado"
python3 -c "import bluetooth; print('✅ PyBluez: OK')" 2>/dev/null || echo "⚠️  PyBluez no disponible (opcional)"

echo ""
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANTE: Debes cerrar sesión y volver a entrar para que"
echo "   los permisos del grupo 'dialout' tengan efecto."
echo ""
echo "📝 Próximos pasos:"
echo "   1. Cierra sesión: exit"
echo "   2. Vuelve a conectarte por SSH"
echo "   3. Ejecuta: python3 ~/tareas/dashboard_server.py"
echo ""
