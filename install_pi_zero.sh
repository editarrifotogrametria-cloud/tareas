#!/bin/bash
# =============================================================================
# Script de instalación para Raspberry Pi Zero 2W + ComNav K222
# GNSS.AI Point Collector System
# =============================================================================

set -e

echo "============================================================================"
echo "📍 GNSS.AI Point Collector - Instalación para Pi Zero 2W"
echo "============================================================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio de instalación
INSTALL_DIR="/home/pi/gnssai"
CURRENT_DIR="$(pwd)"

# =============================================================================
# 1. VERIFICAR SISTEMA
# =============================================================================

echo -e "${YELLOW}[1/8]${NC} Verificando sistema..."

# Verificar que es una Pi
if [ ! -f /proc/cpuinfo ] || ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    echo -e "${RED}❌ Este script está diseñado para Raspberry Pi${NC}"
    exit 1
fi

# Verificar usuario pi
if [ "$USER" != "pi" ]; then
    echo -e "${YELLOW}⚠️  Recomendado ejecutar como usuario 'pi'${NC}"
    read -p "¿Continuar de todos modos? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✅ Sistema verificado${NC}"

# =============================================================================
# 2. ACTUALIZAR SISTEMA
# =============================================================================

echo -e "\n${YELLOW}[2/8]${NC} Actualizando sistema..."
sudo apt-get update -qq
echo -e "${GREEN}✅ Sistema actualizado${NC}"

# =============================================================================
# 3. INSTALAR DEPENDENCIAS
# =============================================================================

echo -e "\n${YELLOW}[3/8]${NC} Instalando dependencias..."

# Paquetes del sistema
sudo apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-serial \
    python3-dev \
    build-essential \
    git

# Paquetes Python
sudo pip3 install --upgrade pip -q
sudo pip3 install -q \
    flask \
    flask-socketio \
    pyserial \
    simple-websocket

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# =============================================================================
# 4. CONFIGURAR UART
# =============================================================================

echo -e "\n${YELLOW}[4/8]${NC} Configurando UART para K222..."

# Habilitar UART
if ! grep -q "enable_uart=1" /boot/config.txt; then
    echo "enable_uart=1" | sudo tee -a /boot/config.txt > /dev/null
    echo -e "${GREEN}✅ UART habilitado en /boot/config.txt${NC}"
else
    echo -e "${GREEN}✅ UART ya estaba habilitado${NC}"
fi

# Deshabilitar consola serie
sudo raspi-config nonint do_serial 2

# Configurar permisos para /dev/serial0
sudo usermod -a -G dialout $USER

echo -e "${GREEN}✅ UART configurado${NC}"

# =============================================================================
# 5. CREAR ESTRUCTURA DE DIRECTORIOS
# =============================================================================

echo -e "\n${YELLOW}[5/8]${NC} Creando estructura de directorios..."

# Crear directorio de instalación si no existe
if [ "$CURRENT_DIR" != "$INSTALL_DIR" ]; then
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -r "$CURRENT_DIR"/* "$INSTALL_DIR/"
    sudo chown -R $USER:$USER "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Crear directorios necesarios
mkdir -p templates
mkdir -p static
mkdir -p point_data
mkdir -p ml_training_data
mkdir -p ml_models

echo -e "${GREEN}✅ Directorios creados${NC}"

# =============================================================================
# 6. CREAR SERVICIOS SYSTEMD
# =============================================================================

echo -e "\n${YELLOW}[6/8]${NC} Configurando servicios systemd..."

# Servicio: smart_processor.service
sudo tee /etc/systemd/system/gnssai-processor.service > /dev/null <<EOF
[Unit]
Description=GNSS.AI Smart Processor (K222 NMEA Processing)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/smart_processor.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Servicio: point_collector_app.service
sudo tee /etc/systemd/system/gnssai-collector.service > /dev/null <<EOF
[Unit]
Description=GNSS.AI Point Collector Web App
After=network.target gnssai-processor.service
Requires=gnssai-processor.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/point_collector_app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd
sudo systemctl daemon-reload

echo -e "${GREEN}✅ Servicios systemd configurados${NC}"

# =============================================================================
# 7. CONFIGURAR WIFI HOTSPOT (OPCIONAL)
# =============================================================================

echo -e "\n${YELLOW}[7/8]${NC} ¿Configurar WiFi Hotspot para acceso directo?"
echo "Esto permitirá conectarse directamente a la Pi desde el celular"
read -p "Configurar WiFi Hotspot? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Instalando hostapd y dnsmasq...${NC}"
    sudo apt-get install -y -qq hostapd dnsmasq

    echo -e "${YELLOW}Configurando Hotspot...${NC}"

    # Configurar hostapd
    sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=wlan0
driver=nl80211
ssid=GNSS-AI-Collector
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=gnssai2024
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

    sudo tee /etc/default/hostapd > /dev/null <<EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

    # Configurar dnsmasq
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

    # Configurar IP estática para wlan0
    sudo tee -a /etc/dhcpcd.conf > /dev/null <<EOF

# GNSS.AI Hotspot configuration
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF

    echo -e "${GREEN}✅ WiFi Hotspot configurado${NC}"
    echo -e "${GREEN}   SSID: GNSS-AI-Collector${NC}"
    echo -e "${GREEN}   Password: gnssai2024${NC}"
    echo -e "${GREEN}   URL: http://192.168.4.1:8080${NC}"
fi

# =============================================================================
# 8. INICIAR SERVICIOS
# =============================================================================

echo -e "\n${YELLOW}[8/8]${NC} Iniciando servicios..."

# Habilitar servicios
sudo systemctl enable gnssai-processor.service
sudo systemctl enable gnssai-collector.service

# Preguntar si iniciar ahora
read -p "¿Iniciar servicios ahora? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl start gnssai-processor.service
    sudo systemctl start gnssai-collector.service

    sleep 2

    echo -e "\n${GREEN}📊 Estado de servicios:${NC}"
    sudo systemctl status gnssai-processor.service --no-pager -l
    echo ""
    sudo systemctl status gnssai-collector.service --no-pager -l
fi

# =============================================================================
# FINALIZACIÓN
# =============================================================================

echo ""
echo "============================================================================"
echo -e "${GREEN}✅ INSTALACIÓN COMPLETADA${NC}"
echo "============================================================================"
echo ""
echo "🔧 Servicios instalados:"
echo "   • gnssai-processor.service  - Procesamiento NMEA del K222"
echo "   • gnssai-collector.service  - Aplicación web de puntos"
echo ""
echo "📱 Acceso a la aplicación:"
echo "   • Desde red local: http://$(hostname -I | awk '{print $1}'):8080"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   • Desde WiFi Hotspot: http://192.168.4.1:8080"
fi
echo ""
echo "🎮 Comandos útiles:"
echo "   sudo systemctl start gnssai-processor    # Iniciar procesador"
echo "   sudo systemctl start gnssai-collector    # Iniciar app web"
echo "   sudo systemctl stop gnssai-processor     # Detener procesador"
echo "   sudo systemctl stop gnssai-collector     # Detener app web"
echo "   sudo systemctl status gnssai-processor   # Ver estado"
echo "   sudo journalctl -u gnssai-processor -f   # Ver logs en vivo"
echo ""
echo "⚠️  IMPORTANTE: Reinicia la Raspberry Pi para aplicar cambios de UART:"
echo "   sudo reboot"
echo ""
echo "============================================================================"
