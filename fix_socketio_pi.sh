#!/bin/bash
# Fix Socket.IO Compatibility on Raspberry Pi
# This script fixes the "unsupported version of Socket.IO" error

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}🔧 Socket.IO Compatibility Fix${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Detect script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}Directorio de trabajo: $SCRIPT_DIR${NC}"
echo ""

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}❌ Error: requirements.txt no encontrado en $SCRIPT_DIR${NC}"
    echo -e "${YELLOW}   Asegúrate de estar en el directorio raíz del repositorio${NC}"
    exit 1
fi
echo -e "${GREEN}✓ requirements.txt encontrado${NC}"

# Check if venv exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}⚠️  Entorno virtual no encontrado. Creando...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✓ Entorno virtual creado${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 1: Limpiando instalaciones anteriores${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Activate virtual environment
source venv/bin/activate

echo -e "${YELLOW}Desinstalando versiones incompatibles de Flask-SocketIO...${NC}"
pip uninstall -y Flask-SocketIO python-socketio python-engineio 2>/dev/null || true
echo -e "${GREEN}✓ Limpieza completada${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 2: Instalando versiones compatibles${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Instalando dependencias desde requirements.txt...${NC}"
pip install -r requirements.txt

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Paso 3: Verificando instalación${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}Versiones instaladas:${NC}"
echo ""
pip list | grep -E "Flask|socketio|engineio" || echo -e "${RED}No se encontraron los paquetes${NC}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Verificación de versiones requeridas${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check versions
FLASK_SOCKETIO_VERSION=$(pip show Flask-SocketIO 2>/dev/null | grep Version | awk '{print $2}' | cut -d. -f1)
PY_SOCKETIO_VERSION=$(pip show python-socketio 2>/dev/null | grep Version | awk '{print $2}' | cut -d. -f1)
PY_ENGINEIO_VERSION=$(pip show python-engineio 2>/dev/null | grep Version | awk '{print $2}' | cut -d. -f1)

ERROR=0

if [ "$FLASK_SOCKETIO_VERSION" = "4" ]; then
    echo -e "${GREEN}✓ Flask-SocketIO versión correcta (4.x)${NC}"
else
    echo -e "${RED}❌ Flask-SocketIO versión incorrecta: $FLASK_SOCKETIO_VERSION (necesita 4.x)${NC}"
    ERROR=1
fi

if [ "$PY_SOCKETIO_VERSION" = "4" ]; then
    echo -e "${GREEN}✓ python-socketio versión correcta (4.x)${NC}"
else
    echo -e "${RED}❌ python-socketio versión incorrecta: $PY_SOCKETIO_VERSION (necesita 4.x)${NC}"
    ERROR=1
fi

if [ "$PY_ENGINEIO_VERSION" = "3" ]; then
    echo -e "${GREEN}✓ python-engineio versión correcta (3.x)${NC}"
else
    echo -e "${RED}❌ python-engineio versión incorrecta: $PY_ENGINEIO_VERSION (necesita 3.x)${NC}"
    ERROR=1
fi

echo ""

if [ $ERROR -eq 1 ]; then
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}⚠️  ADVERTENCIA: Versiones incorrectas detectadas${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Intentando forzar instalación de versiones correctas...${NC}"
    pip install --force-reinstall "Flask-SocketIO>=4.3.0,<5.0.0" \
                                   "python-socketio>=4.6.0,<5.0.0" \
                                   "python-engineio>=3.14.0,<4.0.0"
    echo ""
    echo -e "${YELLOW}Verificando nuevamente...${NC}"
    pip list | grep -E "Flask|socketio|engineio"
    echo ""
fi

echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ Instalación completada${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${BLUE}🚀 Para iniciar el servidor:${NC}"
echo ""
echo "  cd $SCRIPT_DIR"
echo "  source venv/bin/activate"
echo "  cd gnssai"
echo "  python gps_server.py"
echo ""
echo -e "${YELLOW}📋 Después de iniciar, verifica que:${NC}"
echo "  - NO aparezca: 'unsupported version of Socket.IO'"
echo "  - NO aparezca: 'GET /socket.io/?EIO=3 HTTP/1.1\" 400'"
echo "  - SÍ aparezca: 'Client connected to /gnss' (al abrir FUNCIONABLE)"
echo ""
echo -e "${GREEN}✨ Socket.IO está ahora configurado para Engine.IO v3${NC}"
echo ""
