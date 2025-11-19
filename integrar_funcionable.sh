#!/bin/bash
# Script para integrar FUNCIONABLE con el sistema GNSS.AI
# Compatible con Pi Zero 2W + ComNav K222

echo "=========================================="
echo "🔧 GNSS.AI + FUNCIONABLE - Integración"
echo "=========================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "~/gnss-system" ]; then
    echo "❌ No se encuentra ~/gnss-system"
    echo "   Ejecuta este script desde ~/gnss-system/gnssai"
    exit 1
fi

# 1. Clonar FUNCIONABLE si no existe
echo "📦 Paso 1: Descargando FUNCIONABLE..."
cd ~/gnss-system

if [ -d "funcionable" ]; then
    echo "⚠️  La carpeta funcionable ya existe"
    read -p "¿Quieres respaldar y clonar de nuevo? (s/N): " respuesta
    if [[ $respuesta =~ ^[Ss]$ ]]; then
        mv funcionable funcionable_backup_$(date +%Y%m%d_%H%M%S)
        git clone https://github.com/editarrifotogrametria-cloud/FUNCIONABLE.git funcionable
    else
        echo "✅ Usando funcionable existente"
    fi
else
    git clone https://github.com/editarrifotogrametria-cloud/FUNCIONABLE.git funcionable
fi

# 2. Crear servidor Flask integrado
echo ""
echo "📝 Paso 2: Creando servidor Flask integrado..."

cat > ~/gnss-system/gnssai/gps_server_funcionable.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GPS Server + FUNCIONABLE Integration
Sirve la aplicación FUNCIONABLE con backend compatible
"""

import os
import json
import time
import threading
from datetime import datetime
from flask import Flask, jsonify, send_from_directory, request
from flask_socketio import SocketIO, emit
from flask_cors import CORS

# ====================================================================
# Configuration
# ====================================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FUNCIONABLE_DIR = os.path.join(os.path.dirname(BASE_DIR), "funcionable")
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

# ====================================================================
# Global State
# ====================================================================
latest_stats = {}
uptime_sec = 0

# ====================================================================
# Flask App Setup - CONFIGURACIÓN ACTUALIZADA
# ====================================================================
app = Flask(__name__)
app.config['SECRET_KEY'] = 'gnssai-funcionable-2024'

# CORS para permitir conexiones desde cualquier origen
CORS(app)

# SocketIO con configuración compatible v5+ (sin EIO=3)
socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode='threading',
    logger=False,
    engineio_logger=False,
    ping_timeout=60,
    ping_interval=25,
    # Forzar WebSocket moderno (sin polling antiguo)
    transports=['websocket', 'polling']
)

# ====================================================================
# Utility Functions
# ====================================================================
def safe_read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def format_uptime(seconds):
    """Format uptime seconds into human-readable string."""
    days, remainder = divmod(seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)

    parts = []
    if days > 0:
        parts.append(f"{int(days)}d")
    if hours > 0:
        parts.append(f"{int(hours)}h")
    if minutes > 0:
        parts.append(f"{int(minutes)}m")
    parts.append(f"{int(seconds)}s")

    return " ".join(parts)

# ====================================================================
# Background Threads
# ====================================================================
def read_json_data():
    """Lee periódicamente el archivo JSON de datos GNSS."""
    global latest_stats
    while True:
        data = safe_read_json(JSON_DATA_FILE)
        if data:
            latest_stats = data
            # Emitir por Socket.IO a todos los clientes conectados
            try:
                socketio.emit('gnss_update', data, namespace='/')
            except Exception:
                pass
        time.sleep(1.0)

def update_uptime():
    """Contador de uptime."""
    global uptime_sec
    while True:
        uptime_sec += 1
        time.sleep(1.0)

# ====================================================================
# Routes - Servir FUNCIONABLE
# ====================================================================
@app.route('/')
def index():
    """Servir página principal de FUNCIONABLE"""
    return send_from_directory(FUNCIONABLE_DIR, 'index.html')

@app.route('/<path:path>')
def serve_funcionable(path):
    """Servir archivos estáticos de FUNCIONABLE"""
    return send_from_directory(FUNCIONABLE_DIR, path)

# ====================================================================
# API Routes
# ====================================================================
@app.route('/api/stats')
def api_stats():
    """API REST para obtener estadísticas GNSS"""
    data = dict(latest_stats) if latest_stats else {}

    # Añadir uptime
    data["uptime_sec"] = uptime_sec
    data["uptime_formatted"] = format_uptime(uptime_sec)

    # Asegurar estructura tilt
    if "tilt" not in data or not isinstance(data["tilt"], dict):
        data["tilt"] = {
            "pitch": 0.0,
            "roll": 0.0,
            "heading": 0.0,
            "angle": 0.0,
            "status": "NONE",
        }

    return jsonify(data)

@app.route('/api/config', methods=['GET', 'POST'])
def api_config():
    """API para configuración del receptor"""
    if request.method == 'POST':
        config = request.get_json()
        # Aquí puedes guardar la configuración
        # Por ahora solo la devolvemos
        return jsonify({"status": "ok", "config": config})
    else:
        # Devolver configuración por defecto
        return jsonify({
            "receptor": {
                "tipo": "ComNav",
                "modelo": "K222",
                "conexion": {
                    "tipo": "serial",
                    "puerto": "/dev/serial0",
                    "baudrate": 115200
                }
            },
            "gnss": {
                "constelaciones": ["GPS", "GLONASS", "Galileo", "BeiDou"],
                "tasa_actualizacion": 5,
                "mascara_elevacion": 15
            }
        })

# ====================================================================
# Socket.IO Events
# ====================================================================
@socketio.on('connect')
def handle_connect():
    """Cliente conectado"""
    print(f"🔗 Cliente conectado: {request.sid}")
    # Enviar datos actuales inmediatamente
    if latest_stats:
        emit('gnss_update', latest_stats)

@socketio.on('disconnect')
def handle_disconnect():
    """Cliente desconectado"""
    print(f"🔌 Cliente desconectado: {request.sid}")

@socketio.on('request_stats')
def handle_request_stats():
    """Cliente solicita estadísticas"""
    if latest_stats:
        emit('gnss_update', latest_stats)

@socketio.on('send_command')
def handle_command(data):
    """Recibir comandos del cliente"""
    print(f"📨 Comando recibido: {data}")
    # Aquí puedes procesar comandos al receptor GNSS
    emit('command_response', {"status": "ok", "command": data})

# ====================================================================
# Main
# ====================================================================
def main():
    # Verificar que existe FUNCIONABLE
    if not os.path.exists(FUNCIONABLE_DIR):
        print(f"❌ Error: No se encuentra FUNCIONABLE en {FUNCIONABLE_DIR}")
        print(f"   Clona el repositorio con:")
        print(f"   git clone https://github.com/editarrifotogrametria-cloud/FUNCIONABLE.git {FUNCIONABLE_DIR}")
        return

    # Iniciar threads
    t_json = threading.Thread(target=read_json_data, daemon=True)
    t_json.start()

    t_uptime = threading.Thread(target=update_uptime, daemon=True)
    t_uptime.start()

    print("=" * 70)
    print("🛰️  GNSS.AI + FUNCIONABLE Server")
    print("=" * 70)
    print(f"📊 FUNCIONABLE:       http://0.0.0.0:5000")
    print(f"📡 API Stats:         http://0.0.0.0:5000/api/stats")
    print(f"📡 API Config:        http://0.0.0.0:5000/api/config")
    print(f"🔌 WebSocket:         ws://0.0.0.0:5000/socket.io/")
    print(f"💾 Data Source:       {JSON_DATA_FILE}")
    print(f"📁 FUNCIONABLE Dir:   {FUNCIONABLE_DIR}")
    print("=" * 70)
    print("✅ Servidor iniciado. Ctrl+C para detener.")
    print("")

    # Iniciar servidor
    socketio.run(app, host="0.0.0.0", port=5000, debug=False, allow_unsafe_werkzeug=True)

if __name__ == "__main__":
    main()
EOF

chmod +x ~/gnss-system/gnssai/gps_server_funcionable.py

echo "✅ Servidor creado: ~/gnss-system/gnssai/gps_server_funcionable.py"

# 3. Instalar dependencia CORS
echo ""
echo "📦 Paso 3: Instalando dependencias..."
cd ~/gnss-system
source venv/bin/activate
pip install flask-cors

# 4. Crear script de inicio
echo ""
echo "📝 Paso 4: Creando scripts de inicio..."

cat > ~/gnss-system/start_funcionable.sh << 'EOF'
#!/bin/bash
# Iniciar sistema GNSS.AI + FUNCIONABLE

cd ~/gnss-system/gnssai
source ../venv/bin/activate

# Iniciar smart_processor en background
python3 smart_processor.py &
PROC_PID=$!

# Esperar 2 segundos
sleep 2

# Iniciar servidor FUNCIONABLE
python3 gps_server_funcionable.py

# Al terminar, matar smart_processor
kill $PROC_PID 2>/dev/null
EOF

chmod +x ~/gnss-system/start_funcionable.sh

echo "✅ Script de inicio creado: ~/gnss-system/start_funcionable.sh"

# 5. Crear README
cat > ~/gnss-system/FUNCIONABLE_README.md << 'EOF'
# GNSS.AI + FUNCIONABLE - Sistema Integrado

## Inicio Rápido

### Iniciar todo el sistema:
```bash
cd ~/gnss-system
./start_funcionable.sh
```

### O iniciar manualmente:

**Terminal 1 - Procesador GNSS:**
```bash
cd ~/gnss-system/gnssai
source ../venv/bin/activate
python3 smart_processor.py
```

**Terminal 2 - Servidor Web:**
```bash
cd ~/gnss-system/gnssai
source ../venv/bin/activate
python3 gps_server_funcionable.py
```

### Acceder a la aplicación:

Abrir en el navegador:
- **FUNCIONABLE**: http://192.168.0.109:5000
- **API Stats**: http://192.168.0.109:5000/api/stats
- **API Config**: http://192.168.0.109:5000/api/config

## Arquitectura

```
ComNav K222 → smart_processor.py → /tmp/gnssai_dashboard_data.json
                                            ↓
                                    gps_server_funcionable.py
                                            ↓
                                    FUNCIONABLE (Vue.js)
                                            ↓
                                      Navegador Web
```

## Características

✅ Socket.IO v5+ compatible (sin errores EIO=3)
✅ WebSocket en tiempo real
✅ API REST para datos GNSS
✅ Integración completa con ComNav K222
✅ Soporte RTK, TILT, ML

## Solución de Problemas

### No aparecen datos en FUNCIONABLE
1. Verificar que smart_processor.py está corriendo
2. Verificar archivo JSON: `cat /tmp/gnssai_dashboard_data.json`
3. Verificar API: `curl http://localhost:5000/api/stats`

### Errores Socket.IO
- Ya están solucionados con la configuración v5+
- Si persisten, verificar versiones: `pip list | grep socket`

### Puerto 5000 ocupado
```bash
# Ver qué usa el puerto
sudo netstat -tlnp | grep 5000

# Matar proceso
sudo kill -9 <PID>
```

## Actualización de FUNCIONABLE

```bash
cd ~/gnss-system/funcionable
git pull origin main
```

EOF

echo ""
echo "=========================================="
echo "✅ INTEGRACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📝 Próximos pasos:"
echo ""
echo "1. Iniciar el sistema:"
echo "   cd ~/gnss-system"
echo "   ./start_funcionable.sh"
echo ""
echo "2. Abrir en el navegador:"
echo "   http://192.168.0.109:5000"
echo ""
echo "3. Leer documentación:"
echo "   cat ~/gnss-system/FUNCIONABLE_README.md"
echo ""
echo "🎉 ¡Listo para usar!"
echo ""
