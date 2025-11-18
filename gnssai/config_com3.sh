#!/bin/bash
# =============================================================================
# Configuración del puerto COM3 para ComNav K222
# =============================================================================
#
# USO:
#   - En Windows: export GPS_PORT="COM3"
#   - En Linux (USB): export GPS_PORT="/dev/ttyUSB2"  # COM3 = tercer puerto USB
#   - En Linux (ACM): export GPS_PORT="/dev/ttyACM2"  # COM3 = tercer puerto ACM
#   - En Raspberry Pi: export GPS_PORT="/dev/serial0" # Puerto serial por defecto
#
# Luego ejecutar el servidor:
#   python3 gps_server.py
# =============================================================================

# Configurar el puerto según el sistema operativo
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    export GPS_PORT="COM3"
    echo "✅ Configurado para Windows: COM3"
elif [[ -e "/dev/ttyUSB2" ]]; then
    # Linux con USB
    export GPS_PORT="/dev/ttyUSB2"
    echo "✅ Configurado para Linux USB: /dev/ttyUSB2"
elif [[ -e "/dev/ttyACM2" ]]; then
    # Linux con ACM
    export GPS_PORT="/dev/ttyACM2"
    echo "✅ Configurado para Linux ACM: /dev/ttyACM2"
else
    # Por defecto Raspberry Pi
    export GPS_PORT="/dev/serial0"
    echo "✅ Configurado para Raspberry Pi: /dev/serial0"
fi

echo ""
echo "Puerto GPS configurado: $GPS_PORT"
echo "Iniciando servidor GNSS.AI..."
echo ""

# Iniciar el servidor
cd "$(dirname "$0")"
python3 gps_server.py
