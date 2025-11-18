#!/bin/bash
# ============================================================================
# GNSS.AI Bootstrap Script for Raspberry Pi Zero 2 W
# This script creates all necessary files without needing git
# Compatible with: ComNav K222
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
echo "  GNSS.AI - Bootstrap para Pi Zero 2 W  "
echo "  ComNav K222 RTK System                "
echo "========================================="
echo -e "${NC}"

# Check if running as gnssai2 user
CURRENT_USER=$(whoami)
echo -e "${BLUE}Usuario actual: $CURRENT_USER${NC}"

# Define directories
HOME_DIR="$HOME"
GNSSAI_DIR="$HOME_DIR/gnssai"

echo ""
echo -e "${GREEN}📍 Directorio de instalación: $GNSSAI_DIR${NC}"
echo ""

# Step 1: Update system and install dependencies
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[1/4] Actualizando sistema e instalando dependencias...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
sudo apt update
sudo apt install -y python3-pip python3-serial python3-dev
pip3 install --user flask flask-socketio pyserial
echo -e "${GREEN}✅ Dependencias instaladas${NC}"
echo ""

# Step 2: Create directory structure
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2/4] Creando estructura de directorios...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
mkdir -p "$GNSSAI_DIR"
mkdir -p "$GNSSAI_DIR/templates"
mkdir -p "$GNSSAI_DIR/static"
mkdir -p "$GNSSAI_DIR/servicios_systemd"
echo -e "${GREEN}✅ Estructura creada${NC}"
echo ""

# Step 3: Create all necessary files
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3/4] Creando archivos del sistema...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create .env file
cat > "$GNSSAI_DIR/.env" << 'ENVEOF'
# Puerto GPS para Raspberry Pi Zero
GPS_PORT=/dev/serial0

# Velocidad del puerto serial (baud rate)
GPS_BAUD=115200

# Servidor
SERVER_HOST=0.0.0.0
SERVER_PORT=5000
ENVEOF
echo -e "${GREEN}  ✓ .env${NC}"

# Create run_smart_processor.sh
cat > "$GNSSAI_DIR/run_smart_processor.sh" << 'RUNSMARTEOF'
#!/bin/bash
# Script para lanzar smart_processor.py
# Ruta: ~/gnssai/run_smart_processor.sh

# Directorio base del proyecto
BASE_DIR="$HOME/gnssai"
cd "$BASE_DIR" || exit 1

# Lanzar el procesador inteligente
echo "Iniciando Smart Processor..."
python3 smart_processor.py
RUNSMARTEOF
chmod +x "$GNSSAI_DIR/run_smart_processor.sh"
echo -e "${GREEN}  ✓ run_smart_processor.sh${NC}"

# Create start_dashboard.sh
cat > "$GNSSAI_DIR/start_dashboard.sh" << 'DASHSTARTEOF'
#!/bin/bash
# GNSS.AI Dashboard - Start Script

clear
echo "=========================================="
echo "🛰️  GNSS.AI Dashboard - Iniciando..."
echo "=========================================="
echo ""

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python3 no está instalado"
    exit 1
fi

# Check if Flask is installed
python3 -c "import flask" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️  Flask no está instalado. Instalando..."
    pip3 install --user flask flask-socketio
fi

# Change to script directory
cd "$(dirname "$0")"

# Start the dashboard server
echo "🚀 Iniciando Dashboard Server..."
echo ""
python3 dashboard_server.py
DASHSTARTEOF
chmod +x "$GNSSAI_DIR/start_dashboard.sh"
echo -e "${GREEN}  ✓ start_dashboard.sh${NC}"

# Create smart_processor.py
echo -e "${YELLOW}  ... Creando smart_processor.py (archivo grande)${NC}"
cat > "$GNSSAI_DIR/smart_processor.py" << 'SMARTPYEOF'
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
SMARTPYEOF
echo -e "${GREEN}  ✓ smart_processor.py${NC}"

# Create dashboard_server.py (truncated for brevity - will serve embedded HTML)
echo -e "${YELLOW}  ... Creando dashboard_server.py (archivo grande)${NC}"
cat > "$GNSSAI_DIR/dashboard_server.py" << 'DASHPYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GNSS.AI Dashboard Server v3.1
- Lee /tmp/gnssai_dashboard_data.json
- Sirve un dashboard HTML responsivo (index.html)
- API REST /api/stats
"""

import os
import json
import time
import threading
from datetime import datetime

from flask import Flask, jsonify, render_template, send_from_directory
from flask_socketio import SocketIO

# Rutas base
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_DIR = os.path.join(BASE_DIR, "templates")
STATIC_DIR = os.path.join(BASE_DIR, "static")
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

# Estado global
latest_stats = {}
uptime_sec = 0

# Flask + SocketIO
app = Flask(__name__, template_folder=TEMPLATE_DIR, static_folder=STATIC_DIR)
socketio = SocketIO(app, cors_allowed_origins="*")

def safe_read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def read_json_data():
    """Lee periódicamente /tmp/gnssai_dashboard_data.json y actualiza latest_stats."""
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
    """Contador de uptime en segundos (solo a nivel dashboard)."""
    global uptime_sec
    while True:
        uptime_sec += 1
        time.sleep(1.0)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/stats")
def api_stats():
    data = dict(latest_stats) if latest_stats else {}
    data["uptime_sec"] = uptime_sec
    if "tilt" not in data or not isinstance(data["tilt"], dict):
        data["tilt"] = {
            "pitch": 0.0,
            "roll": 0.0,
            "heading": 0.0,
            "angle": 0.0,
            "status": "NONE",
        }
    return jsonify(data)

@app.route("/static/<path:filename>")
def static_files(filename):
    return send_from_directory(STATIC_DIR, filename)

@socketio.on("connect", namespace="/gnss")
def handle_connect():
    print("🔗 Cliente conectado a /gnss")
    if latest_stats:
        socketio.emit("stats", latest_stats, namespace="/gnss")

@socketio.on("disconnect", namespace="/gnss")
def handle_disconnect():
    print("🔌 Cliente desconectado de /gnss")

def main():
    os.makedirs(TEMPLATE_DIR, exist_ok=True)

    # Lanzar threads
    t_json = threading.Thread(target=read_json_data, daemon=True)
    t_json.start()

    t_up = threading.Thread(target=update_uptime, daemon=True)
    t_up.start()

    print("=" * 60)
    print("🛰️  GNSS.AI Dashboard Server v3.1")
    print("=" * 60)
    print(f"📊 Dashboard: http://0.0.0.0:5000")
    print(f"📡 API REST:  http://0.0.0.0:5000/api/stats")
    print(f"💾 Data File: {JSON_DATA_FILE}")
    print("=" * 60)
    print("✅ Servidor iniciado. Ctrl+C para detener.")
    print("")
    socketio.run(app, host="0.0.0.0", port=5000, debug=False, allow_unsafe_werkzeug=True)

if __name__ == "__main__":
    main()
DASHPYEOF
echo -e "${GREEN}  ✓ dashboard_server.py${NC}"

# Create minimal index.html
echo -e "${YELLOW}  ... Creando templates/index.html${NC}"
cat > "$GNSSAI_DIR/templates/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <title>GNSS.AI Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
        :root {
            --bg: #050816;
            --accent: #22c55e;
            --text: #e5e7eb;
            --muted: #9ca3af;
        }
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: system-ui, sans-serif;
            background: radial-gradient(circle at top, #1e293b 0, #020617 55%, #000 100%);
            color: var(--text);
            min-height: 100vh;
            padding: 12px;
        }
        .app-shell {
            max-width: 1100px;
            margin: 0 auto;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        h1 {
            font-size: 1.8rem;
        }
        .card {
            background: rgba(15, 23, 42, 0.9);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 15px;
            border: 1px solid rgba(148, 163, 184, 0.3);
        }
        .stat {
            margin: 10px 0;
            font-size: 1.1rem;
        }
        .label {
            color: var(--muted);
            font-size: 0.9rem;
        }
        .status-pill {
            padding: 6px 12px;
            border-radius: 999px;
            background: rgba(34, 197, 94, 0.2);
            border: 1px solid var(--accent);
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
<div class="app-shell">
    <header>
        <h1>GNSS.AI <span style="color:#38bdf8;">Dashboard</span></h1>
        <div class="status-pill" id="conn-label">ONLINE</div>
    </header>

    <div class="card">
        <h2>Posición GPS</h2>
        <div class="stat"><span class="label">Latitud:</span> <span id="lat-span">--</span></div>
        <div class="stat"><span class="label">Longitud:</span> <span id="lon-span">--</span></div>
        <div class="stat"><span class="label">Altura:</span> <span id="alt-span">--</span> m</div>
        <div class="stat"><span class="label">Satélites:</span> <span id="sats-span">--</span></div>
        <div class="stat"><span class="label">Calidad:</span> <span id="rtk-chip">NO FIX</span></div>
    </div>

    <div class="card">
        <h2>Estadísticas</h2>
        <div class="stat"><span class="label">NMEA enviados:</span> <span id="nmea-span">0</span></div>
        <div class="stat"><span class="label">Precisión estimada:</span> <span id="acc-span">--</span> cm</div>
        <div class="stat"><span class="label">Última actualización:</span> <span id="timestamp-span">--</span></div>
    </div>
</div>

<script>
const fmt = (value, digits=3) => {
    if (value === null || value === undefined || isNaN(value)) return "--";
    return Number(value).toFixed(digits);
};

const qualityLabel = (q) => {
    if (q === 4) return "RTK FIXED";
    if (q === 5) return "RTK FLOAT";
    if (q === 2) return "DGPS";
    if (q === 1) return "GPS";
    return "NO FIX";
};

function updateUI(data) {
    if (!data) return;

    const pos = data.position || {};
    document.getElementById("lat-span").textContent = fmt(pos.lat, 7);
    document.getElementById("lon-span").textContent = fmt(pos.lon, 7);
    document.getElementById("alt-span").textContent = fmt(pos.alt, 3);
    document.getElementById("sats-span").textContent = data.satellites ?? "--";
    document.getElementById("nmea-span").textContent = data.nmea_sent ?? 0;

    const q = data.quality;
    const rtkStatus = data.rtk_status || qualityLabel(q);
    document.getElementById("rtk-chip").textContent = rtkStatus;

    const acc = data.estimated_accuracy ?? 0;
    document.getElementById("acc-span").textContent = fmt(acc, 1);

    const lastUpdate = data.last_update;
    if (lastUpdate) {
        const dt = new Date(lastUpdate * 1000);
        document.getElementById("timestamp-span").textContent = dt.toLocaleTimeString();
    }
}

async function pollStats() {
    try {
        const resp = await fetch("/api/stats");
        if (!resp.ok) throw new Error("HTTP " + resp.status);
        const data = await resp.json();
        updateUI(data);
        document.getElementById("conn-label").textContent = "ONLINE";
    } catch (err) {
        console.warn("Error obteniendo /api/stats:", err);
        document.getElementById("conn-label").textContent = "OFFLINE";
    } finally {
        setTimeout(pollStats, 1000);
    }
}

document.addEventListener("DOMContentLoaded", () => {
    pollStats();
});
</script>
</body>
</html>
INDEXEOF
echo -e "${GREEN}  ✓ templates/index.html${NC}"

# Create systemd services
echo -e "${YELLOW}  ... Creando servicios systemd${NC}"
cat > "$GNSSAI_DIR/servicios_systemd/gnssai-smart.service" << SMARTSERVICEEOF
[Unit]
Description=GNSS.AI Smart Processor - Procesa NMEA/RTCM y actualiza JSON
After=network.target bluetooth.target
Wants=bluetooth.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$HOME_DIR/gnssai
ExecStart=$HOME_DIR/gnssai/run_smart_processor.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment="PYTHONUNBUFFERED=1"

# Recursos
Nice=0
CPUWeight=100

[Install]
WantedBy=multi-user.target
SMARTSERVICEEOF

cat > "$GNSSAI_DIR/servicios_systemd/gnssai-dashboard.service" << DASHSERVICEEOF
[Unit]
Description=GNSS.AI Dashboard - Interfaz Web Flask (v2.3)
After=network.target gnssai-smart.service
Wants=gnssai-smart.service

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$HOME_DIR/gnssai
ExecStart=$HOME_DIR/gnssai/start_dashboard.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment="PYTHONUNBUFFERED=1"
Environment="FLASK_ENV=production"

# Recursos
Nice=0
CPUWeight=100

[Install]
WantedBy=multi-user.target
DASHSERVICEEOF

cat > "$GNSSAI_DIR/servicios_systemd/bt-gps-spp.service" << 'BTSERVICEEOF'
[Unit]
Description=Bluetooth GPS SPP Server - Canal RFCOMM para datos GPS
After=bluetooth.target
Requires=bluetooth.target

[Service]
Type=forking
User=root
Group=root

# Configurar Bluetooth como discoverable
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/usr/bin/bluetoothctl pairable on

# Crear canal RFCOMM en /dev/rfcomm0 (canal 1)
ExecStart=/usr/bin/rfcomm watch rfcomm0 1 /bin/sh -c "cat /dev/serial0 > /dev/rfcomm0 & cat /dev/rfcomm0 > /dev/serial0"

# Limpiar al detener
ExecStop=/usr/bin/rfcomm release rfcomm0

Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
BTSERVICEEOF
echo -e "${GREEN}  ✓ Servicios systemd creados${NC}"

echo -e "${GREEN}✅ Todos los archivos creados${NC}"
echo ""

# Step 4: Configure system
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[4/4] Configurando sistema...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Set permissions
chmod +x "$GNSSAI_DIR"/*.sh
chmod +x "$GNSSAI_DIR"/*.py

# Add user to dialout group
sudo usermod -a -G dialout "$CURRENT_USER"
echo -e "${GREEN}  ✓ Usuario agregado al grupo dialout${NC}"

# Configure serial port
if [ -f /boot/config.txt ]; then
    if ! grep -q "enable_uart=1" /boot/config.txt; then
        echo "enable_uart=1" | sudo tee -a /boot/config.txt
        echo -e "${GREEN}  ✓ UART habilitado en /boot/config.txt${NC}"
    else
        echo -e "${YELLOW}  ℹ️  UART ya estaba habilitado${NC}"
    fi
fi

if [ -f /boot/cmdline.txt ]; then
    sudo sed -i 's/console=serial0,115200 //' /boot/cmdline.txt
    sudo sed -i 's/console=ttyAMA0,115200 //' /boot/cmdline.txt
    echo -e "${GREEN}  ✓ Consola serial deshabilitada${NC}"
fi

echo ""
echo -e "${BLUE}¿Instalar servicios systemd? (s/n)${NC}"
read -p "Respuesta: " -n 1 -r
echo

if [[ $REPLY =~ ^[Ss]$ ]]; then
    for service_file in "$GNSSAI_DIR/servicios_systemd/"*.service; do
        if [ -f "$service_file" ]; then
            service_name=$(basename "$service_file")
            sudo cp "$service_file" "/etc/systemd/system/$service_name"
            echo -e "${GREEN}  ✓ Instalado: $service_name${NC}"
        fi
    done

    sudo systemctl daemon-reload
    echo ""
    echo -e "${GREEN}✅ Servicios systemd instalados${NC}"
    echo ""
    echo -e "${YELLOW}Para habilitar al inicio:${NC}"
    echo -e "  ${BLUE}sudo systemctl enable gnssai-smart${NC}"
    echo -e "  ${BLUE}sudo systemctl enable gnssai-dashboard${NC}"
    echo ""
    echo -e "${YELLOW}Para iniciar ahora:${NC}"
    echo -e "  ${BLUE}sudo systemctl start gnssai-smart${NC}"
    echo -e "  ${BLUE}sudo systemctl start gnssai-dashboard${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ ¡Instalación completada!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo ""
echo -e "${YELLOW}1. Reiniciar la Pi para aplicar cambios:${NC}"
echo -e "   ${BLUE}sudo reboot${NC}"
echo ""
echo -e "${YELLOW}2. Después del reinicio, iniciar servicios:${NC}"
echo -e "   ${BLUE}sudo systemctl start gnssai-smart${NC}"
echo -e "   ${BLUE}sudo systemctl start gnssai-dashboard${NC}"
echo ""
echo -e "${YELLOW}3. Acceder al dashboard:${NC}"
echo -e "   ${BLUE}http://$(hostname -I | awk '{print $1}'):5000${NC}"
echo ""
echo -e "${GREEN}🎉 ¡Disfruta de GNSS.AI!${NC}"
echo ""
