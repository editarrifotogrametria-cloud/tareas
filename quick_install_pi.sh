#!/bin/bash
# Quick Install Script for Pi Zero - GNSS System with FUNCIONABLE
# Run this on your Raspberry Pi Zero

set -e  # Exit on error

echo "================================================================"
echo "🛰️  GNSS System - Instalación Rápida para Pi Zero"
echo "================================================================"
echo ""
echo "Este script instalará:"
echo "  ⭐ FUNCIONABLE - Aplicación web profesional Comnav"
echo "  🎯 Sistema TILT/INS avanzado"
echo "  ⚙️  ComNav K222 Control"
echo "  🌐 GPS Professional y más interfaces"
echo ""
read -p "¿Continuar con la instalación? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Instalación cancelada"
    exit 1
fi

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 1: Verificando sistema${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que estamos en Linux
if [[ ! "$(uname)" == "Linux" ]]; then
    echo -e "${RED}❌ Error: Este script solo funciona en Linux${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Sistema Linux detectado${NC}"

# Verificar git
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}⚠️  Git no encontrado. Instalando...${NC}"
    sudo apt-get update
    sudo apt-get install -y git
fi
echo -e "${GREEN}✓ Git disponible${NC}"

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python3 no encontrado. Instalando...${NC}"
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
fi
echo -e "${GREEN}✓ Python3 disponible${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 2: Clonando repositorio${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Definir directorio de instalación
INSTALL_DIR="$HOME/gnss-system"

# Si ya existe, preguntar
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  El directorio $INSTALL_DIR ya existe${NC}"
    read -p "¿Deseas eliminarlo e instalar de nuevo? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Eliminando directorio anterior...${NC}"
        rm -rf "$INSTALL_DIR"
    else
        echo -e "${YELLOW}Usando directorio existente${NC}"
        cd "$INSTALL_DIR"
        git fetch origin
        git checkout claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D
        git pull origin claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D
        echo -e "${GREEN}✓ Repositorio actualizado${NC}"
    fi
fi

# Clonar si no existe
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Clonando repositorio...${NC}"
    git clone -b claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D \
        https://github.com/editarrifotogrametria-cloud/tareas.git \
        "$INSTALL_DIR"
    echo -e "${GREEN}✓ Repositorio clonado${NC}"
fi

cd "$INSTALL_DIR"

# Verificar archivos importantes
echo ""
echo -e "${YELLOW}Verificando archivos...${NC}"

if [ ! -d "funcionable" ]; then
    echo -e "${RED}❌ Error: Directorio 'funcionable' no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ FUNCIONABLE encontrado${NC}"

if [ ! -d "gnssai" ]; then
    echo -e "${RED}❌ Error: Directorio 'gnssai' no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Sistema GNSSAI encontrado${NC}"

if [ ! -f "gnssai/gps_server.py" ]; then
    echo -e "${RED}❌ Error: gps_server.py no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ GPS Server encontrado${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 3: Instalando dependencias${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Preguntar si instalar dependencias
read -p "¿Instalar dependencias Python? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Actualizando sistema...${NC}"
    sudo apt-get update

    echo -e "${YELLOW}Instalando paquetes del sistema...${NC}"
    sudo apt-get install -y python3-pip python3-serial python3-dev python3-venv

    echo -e "${YELLOW}Creando entorno virtual...${NC}"
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo -e "${GREEN}✓ Entorno virtual creado${NC}"
    fi

    echo -e "${YELLOW}Activando entorno virtual...${NC}"
    source venv/bin/activate

    echo -e "${YELLOW}Instalando librerías Python desde requirements.txt...${NC}"
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        echo -e "${GREEN}✓ Dependencias instaladas desde requirements.txt${NC}"
    else
        # Fallback: instalar versiones específicas manualmente
        echo -e "${YELLOW}⚠️  requirements.txt no encontrado, instalando versiones específicas...${NC}"
        pip install "Flask>=2.0.0,<3.0.0"
        pip install "Flask-Cors>=3.0.10"
        pip install "Flask-SocketIO>=4.3.0,<5.0.0"
        pip install "python-socketio>=4.6.0,<5.0.0"
        pip install "python-engineio>=3.14.0,<4.0.0"
        pip install "pyserial>=3.5"
        pip install "python-dotenv>=0.19.0"
        echo -e "${GREEN}✓ Dependencias instaladas manualmente${NC}"
    fi

    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
else
    echo -e "${YELLOW}⚠️  Saltando instalación de dependencias${NC}"
    echo -e "${YELLOW}   Asegúrate de tener: flask, flask-socketio, pyserial${NC}"
fi

# Verificar puerto serie
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 4: Configurando puerto GPS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Buscar puertos serie disponibles
SERIAL_PORTS=$(ls /dev/ttyUSB* /dev/ttyAMA* /dev/serial* 2>/dev/null | head -5)

if [ -z "$SERIAL_PORTS" ]; then
    echo -e "${YELLOW}⚠️  No se detectaron puertos serie${NC}"
    echo -e "${YELLOW}   Conecta tu módulo GPS y verifica con: ls /dev/tty*${NC}"
    GPS_PORT="/dev/serial0"
else
    echo -e "${GREEN}Puertos serie detectados:${NC}"
    echo "$SERIAL_PORTS"
    echo ""

    # Usar /dev/serial0 por defecto si existe
    if [ -e "/dev/serial0" ]; then
        GPS_PORT="/dev/serial0"
        echo -e "${GREEN}✓ Usando puerto por defecto: $GPS_PORT${NC}"
    else
        GPS_PORT=$(echo "$SERIAL_PORTS" | head -1)
        echo -e "${YELLOW}⚠️  Usando primer puerto detectado: $GPS_PORT${NC}"
    fi
fi

# Añadir usuario al grupo dialout
echo -e "${YELLOW}Añadiendo usuario al grupo dialout...${NC}"
sudo usermod -a -G dialout $USER
echo -e "${GREEN}✓ Usuario añadido al grupo dialout${NC}"
echo -e "${YELLOW}   (Puede requerir reiniciar sesión)${NC}"

# Crear archivo .env
echo ""
echo -e "${YELLOW}Creando archivo de configuración...${NC}"
cat > "$INSTALL_DIR/gnssai/.env" << EOF
# Configuración GPS
GPS_PORT=$GPS_PORT
GPS_BAUD=115200

# Configuración Servidor
SERVER_PORT=5000
SERVER_HOST=0.0.0.0

# Paths
FIFO_PATH=/tmp/gnssai_smart
JSON_PATH=/tmp/gnssai_dashboard_data.json
EOF

echo -e "${GREEN}✓ Archivo .env creado en gnssai/.env${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 5: Verificación final${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Mostrar resumen de archivos
echo -e "${GREEN}Archivos instalados:${NC}"
echo ""
echo "  📁 Directorio principal: $INSTALL_DIR"
echo ""
echo "  ⭐ FUNCIONABLE:"
echo "     $INSTALL_DIR/funcionable/"
echo "     - index.html, README.md, config.example.json"
echo "     - static/css/ (2 archivos CSS)"
echo "     - static/js/ (3 archivos JS)"
echo ""
echo "  🎯 Sistema GNSSAI:"
echo "     $INSTALL_DIR/gnssai/"
echo "     - gps_server.py (servidor principal)"
echo "     - smart_processor.py (procesador con TILT)"
echo "     - comnav_control.html (control K222)"
echo "     - quick_setup_ins.sh (configuración INS)"
echo ""

# Obtener IP
echo -e "${GREEN}Tu IP de red:${NC}"
IP_ADDRESS=$(hostname -I | awk '{print $1}')
if [ -n "$IP_ADDRESS" ]; then
    echo "  $IP_ADDRESS"
else
    echo "  (No detectada - usa: hostname -I)"
fi

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ Instalación completada exitosamente!${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${BLUE}🚀 Para iniciar el sistema:${NC}"
echo ""
echo "  cd $INSTALL_DIR"
echo "  source venv/bin/activate"
echo "  cd gnssai"
echo "  python gps_server.py"
echo ""
echo -e "${BLUE}📱 Accede desde tu navegador:${NC}"
echo ""
if [ -n "$IP_ADDRESS" ]; then
    echo "  🌟 FUNCIONABLE:     http://$IP_ADDRESS:5000/funcionable"
    echo "  ⚙️  ComNav Control:  http://$IP_ADDRESS:5000/comnav"
    echo "  🏠 Página Principal: http://$IP_ADDRESS:5000"
else
    echo "  🌟 FUNCIONABLE:     http://<TU_IP>:5000/funcionable"
    echo "  ⚙️  ComNav Control:  http://<TU_IP>:5000/comnav"
    echo "  🏠 Página Principal: http://<TU_IP>:5000"
fi
echo ""
echo -e "${YELLOW}📚 Documentación:${NC}"
echo "  $INSTALL_DIR/INSTALL_PI_ZERO.md"
echo "  $INSTALL_DIR/funcionable/README.md"
echo ""
echo -e "${YELLOW}💡 Consejo:${NC} Añade 'export GPS_PORT=$GPS_PORT' a tu ~/.bashrc"
echo ""

# Preguntar si iniciar ahora
read -p "¿Iniciar el servidor GPS ahora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${GREEN}🚀 Iniciando servidor GPS...${NC}"
    echo ""
    cd "$INSTALL_DIR"
    source venv/bin/activate
    cd gnssai
    python gps_server.py
else
    echo ""
    echo -e "${GREEN}✨ Para iniciar manualmente:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  source venv/bin/activate"
    echo "  cd gnssai"
    echo "  python gps_server.py"
    echo ""
fi
