# Comandos para Crear Archivos en la Raspberry Pi Zero

Esta guía te muestra cómo crear los archivos necesarios directamente en la Pi Zero sin necesidad de clonar el repositorio completo.

## 🚀 Opción 1: Instalación Automática (RECOMENDADO)

Si ya tienes el repositorio clonado en `~/tareas`:

```bash
cd ~/tareas
chmod +x install_pi_zero.sh
./install_pi_zero.sh
```

## 📝 Opción 2: Creación Manual de Archivos

Si prefieres crear los archivos manualmente, sigue estos pasos:

### Paso 1: Crear estructura de directorios

```bash
cd ~
mkdir -p gnssai
mkdir -p gnssai/templates
mkdir -p gnssai/static/css
mkdir -p gnssai/static/js
```

### Paso 2: Crear archivo gps_server.py

```bash
cat > ~/gnssai/gps_server.py << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GPS Server - Professional Web Interface
Compatible con ComNav K222
"""

import os
import json
import time
import threading
from datetime import datetime
from flask import Flask, jsonify, send_file, send_from_directory, request
from flask_socketio import SocketIO

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
TEMPLATE_DIR = os.path.join(BASE_DIR, "templates")
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

# Global State
latest_stats = {}
uptime_sec = 0

# Flask App Setup
app = Flask(__name__)
app.config['SECRET_KEY'] = 'gps-collector-secret-key'
socketio = SocketIO(app, cors_allowed_origins="*")

def safe_read_json(path):
    """Safely read JSON file."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def read_json_data():
    """Read GPS data from JSON file periodically."""
    global latest_stats
    while True:
        data = safe_read_json(JSON_DATA_FILE)
        if data:
            latest_stats = data
            try:
                socketio.emit("stats", data, namespace="/gnss")
            except Exception:
                pass
        time.sleep(1.0)

def update_uptime():
    """Update server uptime counter."""
    global uptime_sec
    while True:
        uptime_sec += 1
        time.sleep(1.0)

# Routes
@app.route("/")
def index():
    """Serve the main interface."""
    try:
        return send_file(os.path.join(TEMPLATE_DIR, "index.html"))
    except Exception as e:
        return f"Error: {str(e)}", 500

@app.route("/api/stats")
def api_stats():
    """API endpoint for GPS statistics."""
    data = dict(latest_stats) if latest_stats else {}
    data["uptime_sec"] = uptime_sec

    # Ensure tilt block exists
    if "tilt" not in data or not isinstance(data["tilt"], dict):
        data["tilt"] = {
            "pitch": 0.0,
            "roll": 0.0,
            "heading": 0.0,
            "angle": 0.0,
            "status": "NONE",
        }

    return jsonify(data)

@app.route("/api/comnav/command", methods=["POST"])
def comnav_command():
    """Send command to ComNav K222 device."""
    try:
        import serial
        data = request.get_json()
        command = data.get("command", "")

        if not command:
            return jsonify({"status": "error", "message": "No command provided"}), 400

        # Get GPS port from environment or use default
        gps_port = os.getenv('GPS_PORT', '/dev/serial0')

        # Open serial connection
        with serial.Serial(gps_port, 115200, timeout=2) as ser:
            # Send command to ComNav device
            cmd_str = f"{command}\r\n"
            ser.write(cmd_str.encode())

            # Wait for response
            time.sleep(0.5)
            response = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')

        return jsonify({
            "status": "success",
            "command": command,
            "response": response,
            "port": gps_port
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route("/static/<path:filename>")
def static_files(filename):
    """Serve static files."""
    return send_from_directory(STATIC_DIR, filename)

# WebSocket Events
@socketio.on("connect", namespace="/gnss")
def handle_connect():
    """Handle WebSocket connection."""
    print("🔗 Client connected to /gnss")
    if latest_stats:
        socketio.emit("stats", latest_stats, namespace="/gnss")

@socketio.on("disconnect", namespace="/gnss")
def handle_disconnect():
    """Handle WebSocket disconnection."""
    print("🔌 Client disconnected from /gnss")

def main():
    """Start the GPS server."""
    os.makedirs(STATIC_DIR, exist_ok=True)
    os.makedirs(TEMPLATE_DIR, exist_ok=True)

    # Start background threads
    t_json = threading.Thread(target=read_json_data, daemon=True)
    t_json.start()

    t_uptime = threading.Thread(target=update_uptime, daemon=True)
    t_uptime.start()

    # Print startup information
    print("=" * 70)
    print("🛰️  GPS Server - GNSS.AI ComNav K222")
    print("=" * 70)
    print(f"🏠 Home:              http://0.0.0.0:5000")
    print(f"📡 API:               http://0.0.0.0:5000/api/stats")
    print(f"🎛️  ComNav Commands:   http://0.0.0.0:5000/api/comnav/command")
    print(f"💾 Data Source:       {JSON_DATA_FILE}")
    print("=" * 70)
    print("✅ Server running. Press Ctrl+C to stop.")
    print("")

    # Run the server
    socketio.run(
        app,
        host="0.0.0.0",
        port=5000,
        debug=False,
        allow_unsafe_werkzeug=True
    )

if __name__ == "__main__":
    main()
ENDOFFILE
```

### Paso 3: Crear archivo smart_processor.py

```bash
# Copiar desde el repo
cp ~/tareas/gnssai/smart_processor.py ~/gnssai/smart_processor.py
```

O si no tienes el repo:

```bash
cp ~/tareas/smart_processor.py ~/gnssai/smart_processor.py
```

### Paso 4: Crear scripts de inicio

```bash
cat > ~/gnssai/start_gps_professional.sh << 'ENDOFFILE'
#!/bin/bash
# Start GPS Professional Server

echo "🛰️  Iniciando GPS Professional Server..."
cd ~/gnssai

# Kill any existing instances
pkill -f gps_server.py 2>/dev/null

# Set GPS port
export GPS_PORT=/dev/serial0

# Start server
python3 gps_server.py
ENDOFFILE

chmod +x ~/gnssai/start_gps_professional.sh
```

```bash
cat > ~/gnssai/start_processor.sh << 'ENDOFFILE'
#!/bin/bash
# Start GNSS Smart Processor

echo "🧠 Iniciando GNSS Smart Processor..."
cd ~/gnssai

# Kill any existing instances
pkill -f smart_processor.py 2>/dev/null

# Start processor
python3 smart_processor.py
ENDOFFILE

chmod +x ~/gnssai/start_processor.sh
```

### Paso 5: Copiar archivos estáticos

Si tienes el repositorio:

```bash
cp -r ~/tareas/gnssai/static/* ~/gnssai/static/
cp -r ~/tareas/gnssai/templates/* ~/gnssai/templates/
```

Si NO tienes el repositorio, necesitarás los archivos del commit del repo. La forma más fácil es clonar el repo:

```bash
cd ~
git clone https://github.com/editarrifotogrametria-cloud/tareas.git
cd tareas
git checkout 9cce28f -- gnssai/
cp -r gnssai/static/* ~/gnssai/static/
cp -r gnssai/templates/* ~/gnssai/templates/
```

### Paso 6: Instalar dependencias

```bash
sudo apt update
sudo apt install -y python3-pip python3-serial
pip3 install --user flask flask-socketio pyserial
```

### Paso 7: Configurar puerto serial

```bash
# Agregar usuario al grupo dialout
sudo usermod -a -G dialout $USER

# Habilitar UART
echo "enable_uart=1" | sudo tee -a /boot/config.txt

# Deshabilitar consola serial
sudo sed -i 's/console=serial0,115200 //' /boot/cmdline.txt
sudo sed -i 's/console=ttyAMA0,115200 //' /boot/cmdline.txt

# Reiniciar
sudo reboot
```

### Paso 8: Iniciar el sistema

Después del reinicio:

```bash
cd ~/gnssai
./start_gps_professional.sh
```

En otra terminal (o en segundo plano):

```bash
cd ~/gnssai
./start_processor.sh &
```

## 🌐 Acceder a la Interfaz

Desde cualquier navegador en la misma red:

```
http://gnssai2.local:5000
```

O usando la IP:

```
http://192.168.x.x:5000
```

## 📡 Comandos ComNav Disponibles

Una vez en la interfaz web, podrás enviar estos comandos:

- `SAVECONFIG` - Guardar configuración
- `FRESET` - Reset a fábrica
- Y más comandos personalizados

## 🔍 Verificar que Todo Funciona

```bash
# Ver datos GPS en crudo
cat /dev/serial0

# Verificar servicios
ps aux | grep python3

# Ver logs del servidor
# (si lo ejecutaste manualmente, verás los logs en la terminal)
```

## 🔄 Crear Servicios Systemd (Opcional)

Para que se inicie automáticamente al encender la Pi:

```bash
# GPS Professional
sudo tee /etc/systemd/system/gps-professional.service > /dev/null << EOF
[Unit]
Description=GPS Professional Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/gnssai
ExecStart=/usr/bin/python3 $HOME/gnssai/gps_server.py
Restart=always
RestartSec=10
Environment="GPS_PORT=/dev/serial0"

[Install]
WantedBy=multi-user.target
EOF

# Habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable gps-professional
sudo systemctl start gps-professional
```

```bash
# GNSS Processor
sudo tee /etc/systemd/system/gnss-processor.service > /dev/null << EOF
[Unit]
Description=GNSS Smart Processor
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/gnssai
ExecStart=/usr/bin/python3 $HOME/gnssai/smart_processor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable gnss-processor
sudo systemctl start gnss-processor
```

## 📊 Ver Logs de los Servicios

```bash
# GPS Professional
journalctl -u gps-professional -f

# GNSS Processor
journalctl -u gnss-processor -f
```

## 🎯 Resumen de Archivos Creados

```
~/gnssai/
├── gps_server.py                    # Servidor web con API ComNav
├── smart_processor.py               # Procesador de datos GNSS
├── start_gps_professional.sh        # Script para iniciar servidor
├── start_processor.sh               # Script para iniciar procesador
├── templates/
│   └── index.html                  # Interfaz web (copiar del repo)
└── static/
    ├── css/
    │   ├── chunk-vendors.d93e9d9a.css
    │   └── index.8349ed33.css
    └── js/
        ├── chunk-common.22a6f926.js
        ├── chunk-vendors.31517009.js
        └── index.0bca27f0.js
```

---

**Nota**: Los archivos estáticos (HTML, CSS, JS) deben copiarse del repositorio ya que son muy grandes para crearlos manualmente.
