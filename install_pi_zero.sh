#!/bin/bash
# ============================================================================
# Script de Instalación GNSS.AI para Raspberry Pi Zero 2 W
# Compatible con: ComNav K222
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "========================================="
echo "  GNSS.AI - Instalador para Pi Zero 2 W "
echo "  ComNav K222 RTK System                "
echo "========================================="
echo -e "${NC}"

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo -e "${YELLOW}⚠️  Advertencia: No se detectó Raspberry Pi${NC}"
    read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Check if running as gnssai2 user
CURRENT_USER=$(whoami)
echo -e "${BLUE}Usuario actual: $CURRENT_USER${NC}"

# Define directories
HOME_DIR="$HOME"
GNSSAI_DIR="$HOME_DIR/gnssai"
REPO_DIR="$HOME_DIR/tareas"

echo ""
echo -e "${GREEN}📍 Directorio de instalación: $GNSSAI_DIR${NC}"
echo ""

# Step 1: Update system
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[1/8] Actualizando el sistema...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo apt update
echo -e "${GREEN}✅ Sistema actualizado${NC}"
echo ""

# Step 2: Install Python dependencies
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2/8] Instalando dependencias Python...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo apt install -y python3-pip python3-serial python3-dev

pip3 install --user flask flask-socketio pyserial
echo -e "${GREEN}✅ Dependencias Python instaladas${NC}"
echo ""

# Step 3: Create gnssai directory
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3/8] Creando directorio GNSS.AI...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
mkdir -p "$GNSSAI_DIR"
echo -e "${GREEN}✅ Directorio creado: $GNSSAI_DIR${NC}"
echo ""

# Step 4: Copy files from repo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[4/8] Copiando archivos del repositorio...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "$REPO_DIR/gnssai" ]; then
    cp -r "$REPO_DIR/gnssai/"* "$GNSSAI_DIR/"
    echo -e "${GREEN}✅ Archivos copiados desde $REPO_DIR/gnssai/${NC}"
else
    echo -e "${RED}❌ No se encontró el directorio $REPO_DIR/gnssai/${NC}"
    echo -e "${YELLOW}💡 Asegúrate de clonar el repositorio primero:${NC}"
    echo -e "${YELLOW}   cd ~ && git clone <repo-url> tareas${NC}"
    exit 1
fi
echo ""

# Step 5: Set permissions
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[5/8] Configurando permisos...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
chmod +x "$GNSSAI_DIR"/*.sh
chmod +x "$GNSSAI_DIR"/*.py
echo -e "${GREEN}✅ Permisos configurados${NC}"
echo ""

# Step 6: Add user to dialout group
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[6/8] Agregando usuario al grupo dialout...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo usermod -a -G dialout "$CURRENT_USER"
echo -e "${GREEN}✅ Usuario agregado al grupo dialout${NC}"
echo ""

# Step 7: Configure serial port
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[7/8] Configurando puerto serial...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Disable serial console, enable serial hardware
if [ -f /boot/config.txt ]; then
    # Check if already configured
    if ! grep -q "enable_uart=1" /boot/config.txt; then
        echo "enable_uart=1" | sudo tee -a /boot/config.txt
        echo -e "${GREEN}✅ UART habilitado en /boot/config.txt${NC}"
    else
        echo -e "${YELLOW}ℹ️  UART ya estaba habilitado${NC}"
    fi
fi

# Disable serial console in cmdline.txt
if [ -f /boot/cmdline.txt ]; then
    sudo sed -i 's/console=serial0,115200 //' /boot/cmdline.txt
    sudo sed -i 's/console=ttyAMA0,115200 //' /boot/cmdline.txt
    echo -e "${GREEN}✅ Consola serial deshabilitada${NC}"
fi

echo -e "${GREEN}✅ Puerto serial configurado${NC}"
echo ""

# Step 8: Create systemd services
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[8/8] ¿Instalar servicios systemd? (s/n)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -p "Respuesta: " -n 1 -r
echo

if [[ $REPLY =~ ^[Ss]$ ]]; then
    # Instalar servicios desde gnssai/servicios_systemd/
    if [ -d "$GNSSAI_DIR/servicios_systemd" ]; then
        # Reemplazar USER en los archivos de servicio
        for service_file in "$GNSSAI_DIR/servicios_systemd/"*.service; do
            if [ -f "$service_file" ]; then
                service_name=$(basename "$service_file")
                # Copiar y reemplazar el usuario gnssai2 por el usuario actual
                sed "s/User=gnssai2/User=$CURRENT_USER/g; s/Group=gnssai2/Group=$CURRENT_USER/g; s|/home/gnssai2|$HOME_DIR|g" "$service_file" | sudo tee "/etc/systemd/system/$service_name" > /dev/null
                echo -e "${GREEN}✅ Instalado: $service_name${NC}"
            fi
        done

        sudo systemctl daemon-reload

        echo ""
        echo -e "${GREEN}✅ Servicios systemd instalados${NC}"
        echo ""
        echo -e "${YELLOW}Servicios disponibles:${NC}"
        echo -e "${YELLOW}  • gnssai-smart.service      - Procesador NMEA/RTCM${NC}"
        echo -e "${YELLOW}  • gnssai-dashboard.service  - Dashboard web${NC}"
        echo -e "${YELLOW}  • bt-gps-spp.service        - Bluetooth SPP${NC}"
        echo ""
        echo -e "${YELLOW}Para habilitar al inicio:${NC}"
        echo -e "${YELLOW}  sudo systemctl enable gnssai-smart${NC}"
        echo -e "${YELLOW}  sudo systemctl enable gnssai-dashboard${NC}"
        echo -e "${YELLOW}  sudo systemctl enable bt-gps-spp${NC}"
        echo ""
        echo -e "${YELLOW}Para iniciar ahora:${NC}"
        echo -e "${YELLOW}  sudo systemctl start gnssai-smart${NC}"
        echo -e "${YELLOW}  sudo systemctl start gnssai-dashboard${NC}"
        echo -e "${YELLOW}  sudo systemctl start bt-gps-spp${NC}"
    else
        echo -e "${RED}❌ No se encontró el directorio servicios_systemd/${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Servicios systemd no instalados${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Instalación completada exitosamente!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo ""
echo -e "${YELLOW}1. Reiniciar la Pi para aplicar cambios de serial:${NC}"
echo -e "   ${BLUE}sudo reboot${NC}"
echo ""
echo -e "${YELLOW}2. Después del reinicio, iniciar servicios:${NC}"
echo -e "   ${BLUE}sudo systemctl start gnssai-smart${NC}"
echo -e "   ${BLUE}sudo systemctl start gnssai-dashboard${NC}"
echo -e "   ${BLUE}sudo systemctl start bt-gps-spp${NC}"
echo ""
echo -e "${YELLOW}3. O iniciar manualmente:${NC}"
echo -e "   ${BLUE}cd ~/gnssai${NC}"
echo -e "   ${BLUE}./run_smart_processor.sh &${NC}"
echo -e "   ${BLUE}./start_dashboard.sh${NC}"
echo ""
echo -e "${YELLOW}4. Acceder al dashboard desde el navegador:${NC}"
echo -e "   ${BLUE}http://$(hostname).local:5000${NC}"
echo -e "   ${BLUE}http://$(hostname -I | awk '{print $1}'):5000${NC}"
echo ""
echo -e "${YELLOW}5. Ver logs de los servicios:${NC}"
echo -e "   ${BLUE}journalctl -u gnssai-smart -f${NC}"
echo -e "   ${BLUE}journalctl -u gnssai-dashboard -f${NC}"
echo -e "   ${BLUE}journalctl -u bt-gps-spp -f${NC}"
echo ""
echo -e "${GREEN}🎉 Disfruta de GNSS.AI!${NC}"
echo ""
