#!/usr/bin/env python3
"""
GNSS.AI Smart Processor - VERSIÓN CORREGIDA
- Crea FIFO real en lugar de pseudo-terminal
- Compatible con Bluetooth
"""

import serial
import pynmea2
import time
import os
import sys
import stat
from datetime import datetime
from collections import deque
import threading

# Configuración CORREGIDA
UART_K902 = '/dev/serial0'
BAUDRATE = 115200
VIRTUAL_PORT = '/tmp/gnssai_smart'
BUFFER_SIZE = 100

# Importar ML Classifier
try:
    from ml_classifier import SignalClassifier
    ML_AVAILABLE = True
except Exception as e:
    print(f"⚠️  ML disabled: {e}")
    ML_AVAILABLE = False

class RTCMGenerator:
    """Generate RTCM3 messages (simplificado)"""
    def __init__(self):
        self.sequence_num = 0
    
    def parse_nmea_to_rtcm(self, nmea_data):
        """Placeholder para RTCM"""
        return []

class SmartProcessor:
    """Smart processor que crea FIFO real"""
    
    def __init__(self):
        print("🛰️ GNSS.AI Smart Processor Starting...")
        
        # UART to K902
        self.uart = serial.Serial(UART_K902, BAUDRATE, timeout=0.1)
        print(f"✅ Connected to K902 on {UART_K902}")
        
        # Crear FIFO real - CORREGIDO
        self._create_fifo()
        print(f"✅ Virtual port: {VIRTUAL_PORT}")
        
        # ML Classifier
        if ML_AVAILABLE:
            self.classifier = SignalClassifier()
            self.ml_enabled = True
            print("✅ ML Classifier loaded")
        else:
            self.ml_enabled = False
            print("⚠️  ML Classifier disabled")
        
        # RTCM Generator
        self.rtcm_gen = RTCMGenerator()
        print("✅ RTCM Generator ready")
        
        # State
        self.output_format = 'AUTO'
        self.client_requests = deque(maxlen=10)
        self.satellite_buffer = {}
        self.last_gga = None
        self.last_position = None
        
        # Stats
        self.stats = {
            'nmea_sent': 0,
            'rtcm_sent': 0,
            'ml_corrections': 0,
            'format_switches': 0
        }
    
    def _create_fifo(self):
        """Crear FIFO real en lugar de pseudo-terminal"""
        # Eliminar si existe
        if os.path.exists(VIRTUAL_PORT):
            try:
                if os.path.islink(VIRTUAL_PORT):
                    os.unlink(VIRTUAL_PORT)
                else:
                    os.remove(VIRTUAL_PORT)
            except Exception as e:
                print(f"⚠️  Error removing old FIFO: {e}")
        
        # Crear FIFO real
        try:
            os.mkfifo(VIRTUAL_PORT)
            # Dar permisos amplios
            os.chmod(VIRTUAL_PORT, 0o666)
            print(f"✅ FIFO real creado: {VIRTUAL_PORT}")
        except Exception as e:
            print(f"❌ Error creando FIFO: {e}")
            raise
    
    def write_output(self, data):
        """Escribir al FIFO real"""
        try:
            # Abrir, escribir y cerrar (más robusto)
            with open(VIRTUAL_PORT, 'wb') as fifo:
                fifo.write(data)
                fifo.flush()
        except Exception as e:
            # Ignorar errores temporales
            pass
    
    def detect_format_request(self, data):
        """Detectar formato solicitado por cliente"""
        if data.startswith(b'\xd3') or b'RTCM' in data:
            if self.output_format != 'RTCM':
                self.output_format = 'RTCM'
                self.stats['format_switches'] += 1
                print("📡 Switched to RTCM output mode")
        elif data.startswith(b'$') or b'NMEA' in data:
            if self.output_format != 'NMEA':
                self.output_format = 'NMEA'
                self.stats['format_switches'] += 1
                print("📡 Switched to NMEA output mode")
        return None
    
    def parse_nmea(self, line):
        """Parse NMEA sentence"""
        try:
            return pynmea2.parse(line)
        except pynmea2.ParseError:
            return None
    
    def extract_satellite_data(self, msg):
        """Extraer datos de satélites de GSV"""
        if not isinstance(msg, pynmea2.GSV):
            return
        
        for i in range(4):
            try:
                prn = getattr(msg, f'sv_prn_num_{i+1}')
                elevation = getattr(msg, f'elevation_deg_{i+1}')
                azimuth = getattr(msg, f'azimuth_{i+1}')
                snr = getattr(msg, f'snr_{i+1}')
                
                if prn:
                    self.satellite_buffer[int(prn)] = {
                        'prn': int(prn),
                        'elevation': float(elevation) if elevation else 0,
                        'azimuth': float(azimuth) if azimuth else 0,
                        'snr': float(snr) if snr else 0
                    }
            except (AttributeError, ValueError):
                continue
    
    def process_with_ml(self, data):
        """Procesar con ML si está disponible"""
        if not self.ml_enabled or not self.satellite_buffer:
            return data
        
        try:
            classifications = self.classifier.classify_signals(self.satellite_buffer)
            data['ml_metadata'] = {
                'num_los': sum(1 for c in classifications.values() if c['class'] == 'LOS'),
                'num_multipath': sum(1 for c in classifications.values() if c['class'] == 'MULTIPATH'),
                'num_nlos': sum(1 for c in classifications.values() if c['class'] == 'NLOS'),
                'avg_confidence': sum(c['confidence'] for c in classifications.values()) / len(classifications) if classifications else 0
            }
            self.stats['ml_corrections'] += 1
        except Exception as e:
            print(f"ML error: {e}")
        
        return data
    
    def format_as_nmea(self, data):
        """Formatear como NMEA"""
        output = []
        
        if 'raw_gga' in data:
            output.append(data['raw_gga'])
        
        if 'ml_metadata' in data:
            ml = data['ml_metadata']
            num_sats = len(self.satellite_buffer)
            sentence = f"$PGNAI,{num_sats},{ml['num_los']},{ml['num_multipath']},{ml['num_nlos']}"
            checksum = 0
            for char in sentence[1:]:
                checksum ^= ord(char)
            sentence += f"*{checksum:02X}\r\n"
            output.append(sentence)
        
        return ''.join(output).encode('ascii')
    
    def format_as_rtcm(self, data):
        """Formatear como RTCM"""
        return b''
    
    def run(self):
        """Loop principal"""
        print(f"\n{'='*60}")
        print("🚀 GNSS.AI Smart Processor Active")
        print(f"Mode: {self.output_format}")
        print(f"ML Processing: {'Enabled' if self.ml_enabled else 'Disabled'}")
        print(f"{'='*60}\n")
        
        last_stats_print = time.time()
        
        try:
            while True:
                # Leer de K902
                line = self.uart.readline().decode('ascii', errors='ignore').strip()
                
                if not line or not line.startswith('$'):
                    continue
                
                msg = self.parse_nmea(line)
                
                if msg:
                    # Extraer datos de satélites
                    if isinstance(msg, pynmea2.GSV):
                        self.extract_satellite_data(msg)
                    
                    # Procesar GGA
                    elif isinstance(msg, pynmea2.GGA):
                        data = {
                            'raw_gga': line + '\r\n',
                            'gga': {
                                'latitude': msg.latitude,
                                'longitude': msg.longitude,
                                'altitude': msg.altitude,
                                'quality': msg.gps_qual
                            },
                            'satellites': self.satellite_buffer.copy()
                        }
                        
                        # Procesar con ML
                        data = self.process_with_ml(data)
                        
                        # Guardar posición
                        self.last_position = data['gga']
                        
                        # Output en formato solicitado
                        if self.output_format == 'NMEA' or self.output_format == 'AUTO':
                            output = self.format_as_nmea(data)
                            self.write_output(output)
                            self.stats['nmea_sent'] += 1
                        
                        elif self.output_format == 'RTCM':
                            output = self.format_as_rtcm(data)
                            if output:
                                self.write_output(output)
                                self.stats['rtcm_sent'] += 1
                    
                    # Pasar otras frases en modo NMEA
                    elif self.output_format == 'NMEA' or self.output_format == 'AUTO':
                        self.write_output((line + '\r\n').encode('ascii'))
                
                # Estadísticas cada 30 segundos
                if time.time() - last_stats_print > 30:
                    self.print_stats()
                    last_stats_print = time.time()
                
        except KeyboardInterrupt:
            print("\n🛑 Stopping...")
        finally:
            self.cleanup()
    
    def print_stats(self):
        """Imprimir estadísticas"""
        print(f"\n📊 [{datetime.now().strftime('%H:%M:%S')}] Statistics:")
        print(f"   Format: {self.output_format}")
        print(f"   NMEA sent: {self.stats['nmea_sent']}")
        print(f"   RTCM sent: {self.stats['rtcm_sent']}")
        print(f"   ML corrections: {self.stats['ml_corrections']}")
        print(f"   Format switches: {self.stats['format_switches']}")
        print(f"   Satellites: {len(self.satellite_buffer)}")
    
    def cleanup(self):
        """Limpiar recursos"""
        print("🧹 Cleaning up...")
        if hasattr(self, 'uart'):
            self.uart.close()
        if os.path.exists(VIRTUAL_PORT):
            os.remove(VIRTUAL_PORT)
        print("👋 GNSS.AI Smart Processor stopped")

if __name__ == '__main__':
    processor = SmartProcessor()
    processor.run()
