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

    # ---------------------- TILT (ComNav GPNAV/GPYBM) ---------------------- #
    def parse_tilt_sentence(self, line: str):
        """
        PARSEO DE TILT para módulos ComNav K222/K803/K823 con INS/IMU.

        Soporta:
        - $GPNAV: Mensaje ComNav con posición, velocidad, heading, pitch, roll
        - $GPYBM: Mensaje ComNav con heading y pitch (modo dual-antenna o INS)
        - $PSTI,030: Formato estándar INS (ejemplo genérico)

        Formatos típicos:
        $GPNAV,time,lat,lat_dir,lon,lon_dir,quality,sats,hdop,alt,geoid,dgps_age,dgps_id,heading,pitch,roll,vel_n,vel_e,vel_d*checksum
        $GPYBM,time,heading,heading_type,pitch,pitch_type*checksum
        """
        if not line.startswith("$"):
            return

        # ComNav GPNAV (posición + actitud completa)
        if "GPNAV" in line or "GNAV" in line:
            parts = line.split(",")
            try:
                # El formato puede variar, pero típicamente:
                # heading está en campo 13, pitch en 14, roll en 15
                if len(parts) >= 16:
                    heading = float(parts[13]) if parts[13] else 0.0
                    pitch = float(parts[14]) if parts[14] else 0.0
                    roll_field = parts[15].split("*")[0] if "*" in parts[15] else parts[15]
                    roll = float(roll_field) if roll_field else 0.0

                    self.tilt["heading"] = heading
                    self.tilt["pitch"] = pitch
                    self.tilt["roll"] = roll
                    self.tilt["angle"] = (abs(roll) ** 2 + abs(pitch) ** 2) ** 0.5
                    self.tilt["status"] = "GPNAV"
                    return
            except (ValueError, IndexError):
                pass

        # ComNav GPYBM (heading + pitch en modo dual-antenna o INS)
        if "GPYBM" in line or "PYBM" in line:
            parts = line.split(",")
            try:
                # Formato: $GPYBM,time,heading,T/M,pitch,M,...*checksum
                if len(parts) >= 5:
                    heading = float(parts[2]) if parts[2] else 0.0
                    pitch_field = parts[4].split("*")[0] if "*" in parts[4] else parts[4]
                    pitch = float(pitch_field) if pitch_field else 0.0

                    self.tilt["heading"] = heading
                    self.tilt["pitch"] = pitch
                    # GPYBM no reporta roll, mantener valor anterior
                    self.tilt["angle"] = (abs(self.tilt["roll"]) ** 2 + abs(pitch) ** 2) ** 0.5
                    self.tilt["status"] = "GPYBM"
                    return
            except (ValueError, IndexError):
                pass

        # Formato estándar PSTI INS (ejemplo genérico)
        if line.startswith("$PSTI,030"):
            parts = line.split(",")
            try:
                roll = float(parts[2])
                pitch = float(parts[3])
                heading = float(parts[4])

                self.tilt["roll"] = roll
                self.tilt["pitch"] = pitch
                self.tilt["heading"] = heading
                self.tilt["angle"] = (abs(roll) ** 2 + abs(pitch) ** 2) ** 0.5
                self.tilt["status"] = "PSTI"
            except (ValueError, IndexError):
                pass

        # Mensaje GPTRA (ComNav dual-antenna attitude)
        if "GPTRA" in line or "PTRA" in line:
            parts = line.split(",")
            try:
                # Formato: $GPTRA,time,heading,heading_status,...
                if len(parts) >= 3:
                    heading = float(parts[2]) if parts[2] else 0.0
                    self.tilt["heading"] = heading
                    self.tilt["status"] = "GPTRA"
            except (ValueError, IndexError):
                pass

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
