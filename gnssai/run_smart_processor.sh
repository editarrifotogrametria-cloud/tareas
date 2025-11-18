#!/bin/bash
# Script para lanzar smart_processor.py con su entorno virtual
# Ruta: /home/gnssai2/gnssai/run_smart_processor.sh

# Directorio base del proyecto
BASE_DIR="/home/gnssai2/gnssai"
cd "$BASE_DIR" || exit 1

# Activar entorno virtual
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
else
    echo "ERROR: No se encuentra el entorno virtual en $BASE_DIR/.venv"
    exit 1
fi

# Verificar que existe smart_processor.py
if [ ! -f "smart_processor.py" ]; then
    echo "ERROR: No se encuentra smart_processor.py"
    exit 1
fi

# Lanzar el procesador inteligente
echo "Iniciando Smart Processor..."
python3 smart_processor.py

# Desactivar entorno virtual al salir
deactivate
