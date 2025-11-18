#!/bin/bash
# ============================================================================
# SCRIPT COMPLETO PARA CREAR ARCHIVOS GNSS.AI EN PI ZERO
# Ejecuta este script directamente en tu Raspberry Pi Zero
# ============================================================================
#
# USO:
#   1. Copia este script a tu Pi Zero (puedes usar scp o copiar/pegar)
#   2. Dale permisos de ejecución: chmod +x CREAR_ARCHIVOS_PI_ZERO.sh
#   3. Ejecuta: ./CREAR_ARCHIVOS_PI_ZERO.sh
#
# ============================================================================

set -e  # Salir si hay error

echo "============================================="
echo "  Creando archivos GNSS.AI en Pi Zero"
echo "============================================="
echo ""

# Paso 1: Crear estructura de directorios
echo "📁 Creando estructura de directorios..."
mkdir -p ~/gnssai
mkdir -p ~/gnssai/templates
mkdir -p ~/gnssai/static/css
mkdir -p ~/gnssai/static/js
echo "✅ Directorios creados"
echo ""

# Paso 2: Crear gps_server.py
echo "📝 Creando gps_server.py..."
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

chmod +x ~/gnssai/gps_server.py
echo "✅ gps_server.py creado"
echo ""

# Paso 3: Crear smart_processor.py
echo "📝 Creando smart_processor.py..."
cat > ~/gnssai/smart_processor.py << 'ENDOFFILE'
#!/usr/bin/env python3
"""
GNSS.AI Smart Processor v3.3
- Procesa NMEA desde K222/K902/K922
- Envía TODO por FIFO (/tmp/gnssai_smart) para Bluetooth
- Actualiza JSON para dashboard (/tmp/gnssai_dashboard_data.json)
- Integra ML (si el clasificador está disponible)
- Esqueleto para TILT (pitch/roll/heading) listo para K222/K922
"""

import os
import time
import json
import signal
import errno

from datetime import datetime
import serial  # pyserial

# ML opcional (probamos 2 nombres de módulo)
ML_AVAILABLE = False
GNSSClassifier = None
try:
    from gnss_ml_classifier import GNSS_ML_Classifier as GNSSClassifier
    ML_AVAILABLE = True
except ImportError:
    try:
        from ml_classifier import GNSS_ML_Classifier as GNSSClassifier
        ML_AVAILABLE = True
    except ImportError:
        print("⚠️  ML Classifier no disponible, continuaré sin ML.")
        ML_AVAILABLE = False


class SmartProcessor:
    def __init__(self, port=None):
        # Configuración básica
        # Permite especificar puerto: COM3 (Windows), /dev/ttyUSB2 (Linux), etc.
        self.uart_port = port or os.getenv('GPS_PORT', '/dev/serial0')
        self.uart_baud = 115200
        self.fifo_path = "/tmp/gnssai_smart"
        self.json_path = "/tmp/gnssai_dashboard_data.json"

        # Estado
        self.uart = None
        self.fifo_fd = None
        self.running = True
        self.output_counter = 0

        # Estadísticas GNSS
        self.stats = {
            "satellites": 0,
            "quality": 0,
            "hdop": 0.0,
            "nmea_sent": 0,
            "rtcm_sent": 0,
            "ml_corrections": 0,
            "format_switches": 0,
            "ml_los": 0,
            "ml_multipath": 0,
            "ml_nlos": 0,
            "avg_confidence": 0.0,
        }

        # Posición
        self.position = {
            "lat": 0.0,
            "lon": 0.0,
            "alt": 0.0,
        }

        # Satélites (para ML / skyplot)
        self.satellites_detail = {}

        # TILT (esqueleto – se ajusta cuando se conozca la sentencia real)
        self.tilt = {
            "pitch": 0.0,    # +adelante / -atrás
            "roll": 0.0,     # +derecha / -izquierda
            "heading": 0.0,  # rumbo/azimut del módulo
            "angle": 0.0,    # ángulo total de inclinación
            "status": "NONE",
        }

        # ML
        self.ml_enabled = ML_AVAILABLE
        self.classifier = None
        if self.ml_enabled and GNSSClassifier is not None:
            try:
                print("🧠 Inicializando clasificador ML...")
                self.classifier = GNSSClassifier(model="hybrid")
                print("   ✅ ML listo.")
            except Exception as e:
                print(f"⚠️  Error iniciando ML: {e}")
                self.ml_enabled = False

        # Signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)

    # ---------------------- Señales ---------------------- #
    def signal_handler(self, signum, frame):
        print("\n⚠️  Señal recibida, deteniendo SmartProcessor...")
        self.running = False

    # ---------------------- FIFO ---------------------- #
    def _open_fifo_for_write(self):
        """Intenta abrir el FIFO en modo escritura no bloqueante."""
        if self.fifo_fd is not None:
            return

        try:
            self.fifo_fd = os.open(self.fifo_path, os.O_WRONLY | os.O_NONBLOCK)
            print(f"   🔁 FIFO ahora abierto para escritura (fd={self.fifo_fd})")
        except OSError as e:
            if e.errno in (errno.ENXIO, errno.ENOENT):
                # ENXIO => aún no hay lector
                # ENOENT => FIFO no existe (lo creamos en setup_fifo)
                self.fifo_fd = None
            else:
                print(f"   ⚠️  Error abriendo FIFO: {e}")
                self.fifo_fd = None

    def setup_fifo(self):
        """Prepara el FIFO /tmp/gnssai_smart SIN borrarlo si ya existe."""
        print(f"📂 FIFO objetivo: {self.fifo_path}")

        if not os.path.exists(self.fifo_path):
            try:
                os.mkfifo(self.fifo_path, 0o666)
                print("   ✅ FIFO creado (modo 666)")
            except FileExistsError:
                print("   ℹ️ FIFO ya existía.")
        else:
            print("   ℹ️ FIFO ya existía, reutilizando.")

        # Intentar ajustar permisos
        try:
            os.chmod(self.fifo_path, 0o666)
        except PermissionError:
            # Lo normal es que el bt-gps-spp (root) sea el owner
            pass

        self._open_fifo_for_write()
        if self.fifo_fd is None:
            print("   ⚠️  FIFO sin lector todavía (ENXIO). Reintentaré más adelante.")

    # ---------------------- UART ---------------------- #
    def connect_uart(self):
        print(f"🔌 UART {self.uart_port} @ {self.uart_baud}...")
        self.uart = serial.Serial(
            self.uart_port,
            self.uart_baud,
            timeout=1
        )
        print("   ✅ UART abierto")

    # ---------------------- Salida + JSON ---------------------- #
    def write_output(self, data: str):
        """Escribe NMEA al FIFO y actualiza JSON cada cierto número de mensajes."""
        if not data:
            return

        if isinstance(data, bytes):
            data = data.decode("ascii", errors="ignore")

        # 1) Intentar abrir FIFO si aún no está listo
        if self.fifo_fd is None:
            self._open_fifo_for_write()

        # 2) Enviar al FIFO
        if self.fifo_fd is not None:
            try:
                os.write(self.fifo_fd, data.encode("utf-8"))
            except OSError as e:
                if e.errno in (errno.EPIPE, errno.ENXIO):
                    print("   ⚠️  Lector FIFO desconectado (EPIPE/ENXIO), se reabrirá más adelante.")
                    try:
                        os.close(self.fifo_fd)
                    except Exception:
                        pass
                    self.fifo_fd = None
                else:
                    print(f"   ⚠️  Error escribiendo FIFO: {e}")

        # 3) Contador de NMEA
        self.output_counter += 1
        self.stats["nmea_sent"] = self.output_counter

        # 4) Actualizar JSON cada 20 frases
        if self.output_counter % 20 == 0:
            self.update_dashboard_json()

    def update_dashboard_json(self):
        """Genera /tmp/gnssai_dashboard_data.json para el dashboard."""
        quality = self.stats["quality"]
        if quality == 4:
            rtk_status = "RTK_FIXED"
        elif quality == 5:
            rtk_status = "RTK_FLOAT"
        elif quality == 2:
            rtk_status = "DGPS"
        elif quality == 1:
            rtk_status = "GPS"
        else:
            rtk_status = "NO_FIX"

        # Stats ML desde el clasificador (si existe)
        if self.ml_enabled and self.classifier:
            try:
                ml_stats = self.classifier.get_stats()
                self.stats["ml_los"] = ml_stats.get("los_count", 0)
                self.stats["ml_multipath"] = ml_stats.get("multipath_count", 0)
                self.stats["ml_nlos"] = ml_stats.get("nlos_count", 0)
                self.stats["avg_confidence"] = ml_stats.get("avg_confidence", 0.0) * 100.0
            except Exception:
                pass

        # Snapshot de satélites (por si quieres skyplot futuro)
        satellites_view = self.get_satellite_snapshot()

        dashboard_data = {
            "position": {
                "lat": self.position["lat"],
                "lon": self.position["lon"],
                "alt": self.position["alt"],
            },
            "satellites": self.stats["satellites"],
            "satellites_detail": satellites_view,
            "satellites_view": satellites_view,
            "quality": quality,
            "hdop": self.stats["hdop"],
            "nmea_sent": self.stats["nmea_sent"],
            "rtcm_sent": self.stats["rtcm_sent"],
            "ml_corrections": self.stats["ml_corrections"],
            "format_switches": self.stats["format_switches"],
            "los_sats": self.stats["ml_los"],
            "multipath_sats": self.stats["ml_multipath"],
            "nlos_sats": self.stats["ml_nlos"],
            "avg_confidence": self.stats["avg_confidence"],
            "estimated_accuracy": self.estimate_accuracy(quality, self.stats["hdop"]),
            "rtk_status": rtk_status,
            "format": "NMEA",
            "last_update": time.time(),
            "tilt": {
                "pitch": self.tilt["pitch"],
                "roll": self.tilt["roll"],
                "heading": self.tilt["heading"],
                "angle": self.tilt["angle"],
                "status": self.tilt["status"],
            },
        }

        try:
            with open(self.json_path, "w") as f:
                json.dump(dashboard_data, f, indent=2)
        except Exception as e:
            print(f"⚠️  Error escribiendo JSON: {e}")

    @staticmethod
    def estimate_accuracy(quality, hdop):
        """Estimación burda de precisión (cm)."""
        if quality == 4:
            return 2.0
        elif quality == 5:
            return 20.0
        elif quality == 2:
            return 50.0
        elif quality == 1:
            return min(hdop * 100, 1000) if hdop < 10 else 1000
        else:
            return 0.0

    # ---------------------- Parseo NMEA básicos ---------------------- #
    def parse_nmea_gga(self, line: str):
        """Parsea GGA para posición, sats, calidad, HDOP."""
        try:
            parts = line.split(",")
            if len(parts) < 15:
                return

            # Lat/Lon
            if parts[2] and parts[4]:
                lat = self.parse_coordinate(parts[2], parts[3])
                lon = self.parse_coordinate(parts[4], parts[5])
                self.position["lat"] = lat
                self.position["lon"] = lon

            # Altura
            if parts[9]:
                self.position["alt"] = float(parts[9])

            # Quality
            if parts[6]:
                self.stats["quality"] = int(parts[6])

            # Satélites
            if parts[7]:
                self.stats["satellites"] = int(parts[7])

            # HDOP
            if parts[8]:
                self.stats["hdop"] = float(parts[8])

        except (ValueError, IndexError):
            pass

    @staticmethod
    def parse_coordinate(coord: str, direction: str) -> float:
        """Convierte DDMM.MMMM o DDDMM.MMMM a decimal."""
        try:
            if not coord or not direction:
                return 0.0
            dot_pos = coord.index(".")
            degrees = float(coord[: dot_pos - 2])
            minutes = float(coord[dot_pos - 2 :])
            decimal = degrees + (minutes / 60.0)
            if direction in ("S", "W"):
                decimal = -decimal
            return decimal
        except Exception:
            return 0.0

    # ---------------------- Satélites/GSV para ML ---------------------- #
    @staticmethod
    def guess_constellation(line: str) -> str:
        talker = line[1:3].upper()
        return {
            "GP": "GPS",
            "GL": "GLONASS",
            "GA": "Galileo",
            "GB": "BeiDou",
            "BD": "BeiDou",
            "GN": "Multi GNSS",
        }.get(talker, "GNSS")

    @staticmethod
    def classify_satellite(elevation: float, snr: float) -> str:
        if snr >= 38 and elevation >= 15:
            return "los"
        if snr >= 25:
            return "multipath"
        return "nlos"

    def parse_nmea_gsv(self, line: str):
        parts = line.split(",")
        if len(parts) < 4:
            return

        constellation = self.guess_constellation(line)
        now = time.time()

        try:
            sats_in_view = int(parts[3]) if parts[3] else 0
            if sats_in_view:
                self.stats["satellites"] = max(self.stats["satellites"], sats_in_view)
        except (ValueError, IndexError):
            pass

        for idx in range(4):
            base = 4 + idx * 4
            if base + 3 >= len(parts):
                break
            raw_prn = parts[base]
            if not raw_prn:
                continue
            prn = raw_prn.split("*")[0]
            if not prn:
                continue

            try:
                elevation = float(parts[base + 1]) if parts[base + 1] else 0.0
            except (ValueError, IndexError):
                elevation = 0.0
            try:
                azimuth = float(parts[base + 2]) if parts[base + 2] else 0.0
            except (ValueError, IndexError):
                azimuth = 0.0
            try:
                snr_field = parts[base + 3] if len(parts) > base + 3 else ""
                snr = float(snr_field.split("*")[0]) if snr_field else 0.0
            except ValueError:
                snr = 0.0

            status = self.classify_satellite(elevation, snr)
            self.satellites_detail[prn] = {
                "prn": prn,
                "constellation": constellation,
                "elevation": elevation,
                "azimuth": azimuth,
                "snr": snr,
                "status": status,
                "timestamp": now,
            }

    def get_satellite_snapshot(self):
        now = time.time()
        los = multipath = nlos = 0
        snapshot = []
        stale = []

        for prn, sat in self.satellites_detail.items():
            if now - sat.get("timestamp", 0) > 60:
                stale.append(prn)
                continue
            status = sat.get("status", "los")
            if status == "los":
                los += 1
            elif status == "multipath":
                multipath += 1
            else:
                nlos += 1
            snapshot.append({k: v for k, v in sat.items() if k != "timestamp"})

        for prn in stale:
            self.satellites_detail.pop(prn, None)

        if not self.ml_enabled:
            self.stats["ml_los"] = los
            self.stats["ml_multipath"] = multipath
            self.stats["ml_nlos"] = nlos

        def sort_key(item):
            try:
                return int(str(item.get("prn", 0)))
            except (ValueError, TypeError):
                return 0

        snapshot.sort(key=sort_key)
        return snapshot

    # ---------------------- TILT (esqueleto) ---------------------- #
    def parse_tilt_sentence(self, line: str):
        """
        PARSEO DE TILT (ESQUELETO):

        Aquí debes adaptar el formato a la sentencia REAL que emita tu K222/K922.
        Ejemplos típicos en módulos GNSS+INS:
          - Sentencias propietarias tipo $PSTI,030,ROLL,PITCH,HEADING,...
          - O mensajes ASCII de INS/ATTITUDE.

        PASOS:
        1. En el Pi:   sudo cat /dev/serial0 | grep -i 'sti'   (o 'tilt' / 'ins')
        2. Identifica la sentencia que lleve roll/pitch/heading.
        3. Ajusta el parsing abajo.
        """
        if not line.startswith("$"):
            return

        # EJEMPLO FICTICIO: $PSTI,030,roll,pitch,heading,tilt_flag,...
        if line.startswith("$PSTI,030"):
            parts = line.split(",")
            try:
                roll = float(parts[2])
                pitch = float(parts[3])
                heading = float(parts[4])
            except (ValueError, IndexError):
                return

            self.tilt["roll"] = roll
            self.tilt["pitch"] = pitch
            self.tilt["heading"] = heading
            self.tilt["angle"] = (abs(roll) ** 2 + abs(pitch) ** 2) ** 0.5
            self.tilt["status"] = "OK"

    # ---------------------- Loop de procesado ---------------------- #
    def process_nmea_line(self, line: str):
        line = line.strip()
        if not line or not line.startswith("$"):
            return

        # Chequeo checksum NMEA
        if "*" in line:
            try:
                data, checksum = line.rsplit("*", 1)
                calc = 0
                for ch in data[1:]:
                    calc ^= ord(ch)
                if f"{calc:02X}" != checksum.upper():
                    return
            except Exception:
                pass

        # GGA
        if "GGA" in line:
            self.parse_nmea_gga(line)

        # GSV => satélites + ML
        if "GSV" in line:
            self.parse_nmea_gsv(line)
            if self.ml_enabled and self.classifier:
                try:
                    result = self.classifier.process_gsv(line)
                    if result:
                        self.stats["ml_corrections"] += 1
                except Exception:
                    pass

        # TILT
        self.parse_tilt_sentence(line)

        # Enviar NMEA a FIFO
        self.write_output(line + "\r\n")

    def run(self):
        print("============================================================")
        print("🛰️  GNSS.AI Smart Processor v3.3 (TILT + ML + sats)")
        print("============================================================")

        self.setup_fifo()
        self.connect_uart()

        print("🚀 Procesando NMEA desde UART y enviando a FIFO+JSON...")
        last_stats = time.time()

        try:
            while self.running:
                if self.uart.in_waiting:
                    raw = self.uart.readline()
                    try:
                        line = raw.decode("ascii", errors="ignore")
                        self.process_nmea_line(line)
                    except Exception:
                        pass

                now = time.time()
                if now - last_stats > 30:
                    print(
                        f"📊 Sats={self.stats['satellites']} "
                        f"Q={self.stats['quality']} "
                        f"HDOP={self.stats['hdop']} "
                        f"NMEA_out={self.stats['nmea_sent']} "
                        f"TILT={self.tilt['angle']:.1f}° "
                        f"ML: LOS={self.stats['ml_los']} "
                        f"MP={self.stats['ml_multipath']} "
                        f"NLOS={self.stats['ml_nlos']}"
                    )
                    last_stats = now

                time.sleep(0.001)
        except KeyboardInterrupt:
            print("\n🛑 CTRL+C recibido, saliendo...")
        finally:
            self.cleanup()

    def cleanup(self):
        """Limpiar recursos al detener."""
        print("\n🧹 Limpiando recursos...")
        try:
            if self.uart and self.uart.is_open:
                self.uart.close()
                print("   ✅ UART cerrado")
        except Exception:
            pass

        if self.fifo_fd is not None:
            try:
                os.close(self.fifo_fd)
                print("   ✅ FIFO cerrado")
            except Exception:
                pass

        print("👋 SmartProcessor detenido.")


if __name__ == "__main__":
    proc = SmartProcessor()
    proc.run()
ENDOFFILE

chmod +x ~/gnssai/smart_processor.py
echo "✅ smart_processor.py creado"
echo ""

# Paso 4: Crear archivo .env
echo "📝 Creando .env..."
cat > ~/gnssai/.env << 'ENDOFFILE'
# Puerto GPS para ComNav K222
GPS_PORT=/dev/serial0

# Velocidad del puerto serial (baud rate)
GPS_BAUD=115200

# Servidor
SERVER_HOST=0.0.0.0
SERVER_PORT=5000
ENDOFFILE

echo "✅ .env creado"
echo ""

# Paso 5: Crear scripts de inicio
echo "📝 Creando start_gps_professional.sh..."
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
echo "✅ start_gps_professional.sh creado"
echo ""

echo "📝 Creando start_processor.sh..."
cat > ~/gnssai/start_processor.sh << 'ENDOFFILE'
#!/bin/bash
# Start GNSS Smart Processor

echo "🧠 Iniciando GNSS Smart Processor..."
cd ~/gnssai

# Kill any existing instances
pkill -f smart_processor.py 2>/dev/null

# Set GPS port
export GPS_PORT=/dev/serial0

# Start processor
python3 smart_processor.py
ENDOFFILE

chmod +x ~/gnssai/start_processor.sh
echo "✅ start_processor.sh creado"
echo ""

# Paso 6: Crear un index.html básico
echo "📝 Creando templates/index.html básico..."
cat > ~/gnssai/templates/index.html << 'ENDOFFILE'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GNSS.AI - ComNav K222</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
            background: linear-gradient(135deg, #1e3a8a 0%, #0f172a 100%);
            color: #e2e8f0;
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2em;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        .card {
            background: rgba(30, 41, 59, 0.8);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        .card h2 {
            font-size: 1.3em;
            margin-bottom: 15px;
            color: #38bdf8;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        .stat {
            background: rgba(15, 23, 42, 0.6);
            padding: 15px;
            border-radius: 8px;
            border-left: 3px solid #22c55e;
        }
        .stat-label {
            font-size: 0.85em;
            color: #94a3b8;
            margin-bottom: 5px;
        }
        .stat-value {
            font-size: 1.5em;
            font-weight: bold;
            color: #f1f5f9;
        }
        .status {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .status-good { background: #22c55e; color: #000; }
        .status-warning { background: #f59e0b; color: #000; }
        .status-bad { background: #ef4444; color: #fff; }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #64748b;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛰️ GNSS.AI - ComNav K222</h1>

        <div class="card">
            <h2>📍 Posición</h2>
            <div class="grid">
                <div class="stat">
                    <div class="stat-label">Latitud</div>
                    <div class="stat-value" id="lat">--</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Longitud</div>
                    <div class="stat-value" id="lon">--</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Altura</div>
                    <div class="stat-value" id="alt">--</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>📡 Estado GNSS</h2>
            <div class="grid">
                <div class="stat">
                    <div class="stat-label">Satélites</div>
                    <div class="stat-value" id="sats">--</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Calidad</div>
                    <div class="stat-value" id="quality">--</div>
                </div>
                <div class="stat">
                    <div class="stat-label">HDOP</div>
                    <div class="stat-value" id="hdop">--</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Estado RTK</div>
                    <div id="rtk-status" class="status status-bad">NO FIX</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>🎯 Estadísticas</h2>
            <div class="grid">
                <div class="stat">
                    <div class="stat-label">NMEA Enviados</div>
                    <div class="stat-value" id="nmea">0</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Precisión Estimada</div>
                    <div class="stat-value" id="accuracy">-- cm</div>
                </div>
                <div class="stat">
                    <div class="stat-label">Uptime</div>
                    <div class="stat-value" id="uptime">00:00:00</div>
                </div>
            </div>
        </div>

        <div class="footer">
            GNSS.AI Professional v1.0 | <span id="timestamp">Esperando datos...</span>
        </div>
    </div>

    <script>
        const fmt = (val, decimals = 2) => {
            if (val === null || val === undefined || isNaN(val)) return "--";
            return Number(val).toFixed(decimals);
        };

        const formatUptime = (seconds) => {
            if (!seconds) return "00:00:00";
            const h = Math.floor(seconds / 3600).toString().padStart(2, '0');
            const m = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
            const s = (seconds % 60).toString().padStart(2, '0');
            return `${h}:${m}:${s}`;
        };

        const getRTKStatus = (quality) => {
            const q = parseInt(quality);
            if (q === 4) return { text: 'RTK FIXED', class: 'status-good' };
            if (q === 5) return { text: 'RTK FLOAT', class: 'status-warning' };
            if (q === 2) return { text: 'DGPS', class: 'status-warning' };
            if (q === 1) return { text: 'GPS', class: 'status-warning' };
            return { text: 'NO FIX', class: 'status-bad' };
        };

        const updateUI = (data) => {
            if (!data) return;

            // Posición
            const pos = data.position || {};
            document.getElementById('lat').textContent = fmt(pos.lat, 7);
            document.getElementById('lon').textContent = fmt(pos.lon, 7);
            document.getElementById('alt').textContent = fmt(pos.alt, 2) + ' m';

            // Estado
            document.getElementById('sats').textContent = data.satellites || '--';
            document.getElementById('quality').textContent = data.quality || '--';
            document.getElementById('hdop').textContent = fmt(data.hdop, 2);

            // RTK Status
            const rtkStatus = getRTKStatus(data.quality);
            const rtkEl = document.getElementById('rtk-status');
            rtkEl.textContent = rtkStatus.text;
            rtkEl.className = 'status ' + rtkStatus.class;

            // Estadísticas
            document.getElementById('nmea').textContent = data.nmea_sent || 0;
            document.getElementById('accuracy').textContent = fmt(data.estimated_accuracy, 1) + ' cm';
            document.getElementById('uptime').textContent = formatUptime(data.uptime_sec);

            // Timestamp
            if (data.last_update) {
                const date = new Date(data.last_update * 1000);
                document.getElementById('timestamp').textContent =
                    'Última actualización: ' + date.toLocaleTimeString();
            }
        };

        const pollStats = async () => {
            try {
                const resp = await fetch('/api/stats');
                if (resp.ok) {
                    const data = await resp.json();
                    updateUI(data);
                }
            } catch (err) {
                console.error('Error:', err);
            } finally {
                setTimeout(pollStats, 1000);
            }
        };

        document.addEventListener('DOMContentLoaded', () => {
            pollStats();
        });
    </script>
</body>
</html>
ENDOFFILE

echo "✅ index.html creado"
echo ""

echo "============================================="
echo "✅ ARCHIVOS CREADOS EXITOSAMENTE!"
echo "============================================="
echo ""
echo "📂 Estructura creada en: ~/gnssai/"
echo ""
echo "📋 Próximos pasos:"
echo ""
echo "1️⃣  Instalar dependencias Python:"
echo "    sudo apt update"
echo "    sudo apt install -y python3-pip python3-serial"
echo "    pip3 install flask flask-socketio pyserial"
echo ""
echo "2️⃣  Configurar puerto serial:"
echo "    sudo usermod -a -G dialout \$USER"
echo "    echo 'enable_uart=1' | sudo tee -a /boot/config.txt"
echo "    sudo sed -i 's/console=serial0,115200 //' /boot/cmdline.txt"
echo ""
echo "3️⃣  Reiniciar la Pi:"
echo "    sudo reboot"
echo ""
echo "4️⃣  Después del reinicio, iniciar el servidor:"
echo "    cd ~/gnssai"
echo "    ./start_gps_professional.sh"
echo ""
echo "5️⃣  Acceder desde el navegador:"
echo "    http://gnssai2.local:5000"
echo "    o"
echo "    http://\$(hostname -I | awk '{print \$1}'):5000"
echo ""
echo "🎉 ¡Listo para usar!"
echo ""
