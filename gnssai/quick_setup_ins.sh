#!/bin/bash
# Quick Setup Script for ComNav K222 INS/TILT
# Configura automáticamente el módulo para usar INS con todos los mensajes necesarios

echo "============================================================"
echo "🛰️  ComNav K222 - Configuración Rápida INS/TILT"
echo "============================================================"
echo ""
echo "Este script configurará tu módulo ComNav con:"
echo "  ✅ Modo INS activado (eje tipo 6)"
echo "  ✅ Mensajes NMEA básicos (GGA, RMC, GSV)"
echo "  ✅ Mensajes de actitud (GPNAV, GPYBM)"
echo "  ✅ Frecuencia 5 Hz para posición"
echo "  ✅ Elevación mínima 10°"
echo ""
read -p "¿Continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "📡 Enviando comandos al módulo..."
echo ""

# Función para enviar comando
send_cmd() {
    echo "▶ $1"
    python3 "$SCRIPT_DIR/test_comnav_commands.py" "$1"
    sleep 1
}

# 1. Detener todos los mensajes actuales
send_cmd "unlogall"

# 2. Activar modo INS con eje tipo 6
echo ""
echo "🔄 Activando modo INS..."
send_cmd "INSMODE ENABLE 6"

# 3. Configurar mensajes NMEA básicos a 5 Hz
echo ""
echo "📊 Configurando mensajes NMEA (5 Hz)..."
send_cmd "log com1 gpgga ontime 0.2"
send_cmd "log com1 gprmc ontime 0.2"
send_cmd "log com1 gpgsv ontime 5"

# 4. Activar mensajes de actitud
echo ""
echo "🎯 Activando mensajes de actitud..."
send_cmd "log com1 gpnav ontime 1"
send_cmd "log com1 gpybm ontime 1"
send_cmd "log com1 gptra ontime 1"

# 5. Configurar elevación mínima
echo ""
echo "📐 Configurando elevación mínima (10°)..."
send_cmd "ecutoff 10"

# 6. Guardar configuración
echo ""
echo "💾 Guardando configuración..."
send_cmd "saveconfig"

echo ""
echo "============================================================"
echo "✅ Configuración completada!"
echo "============================================================"
echo ""
echo "El módulo ComNav ahora está configurado con:"
echo "  ✓ Modo INS activado"
echo "  ✓ Mensajes NMEA a 5 Hz"
echo "  ✓ Mensajes de actitud (GPNAV, GPYBM, GPTRA)"
echo "  ✓ Configuración guardada en memoria"
echo ""
echo "🌐 Accede a la interfaz web para monitorear:"
echo "   http://$(hostname -I | awk '{print $1}'):5000/comnav"
echo ""
echo "📝 Nota: Si el módulo no tiene IMU integrado (K222 básico),"
echo "         los mensajes de actitud pueden no estar disponibles."
echo "         Solo K803 y K823 tienen IMU integrado."
echo ""
