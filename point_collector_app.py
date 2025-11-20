#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GNSS.AI Point Collector App
Aplicación web profesional para toma de puntos RTK con K222
Optimizada para uso móvil (PWA)
"""

import os
import json
import time
import sqlite3
from datetime import datetime
from pathlib import Path
from flask import Flask, jsonify, render_template, request, send_file
from flask_socketio import SocketIO
import threading

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

BASE_DIR = Path(__file__).parent
TEMPLATE_DIR = BASE_DIR / "templates"
STATIC_DIR = BASE_DIR / "static"
DATA_DIR = BASE_DIR / "point_data"
DB_PATH = DATA_DIR / "points.db"
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

DATA_DIR.mkdir(exist_ok=True)
TEMPLATE_DIR.mkdir(exist_ok=True)
STATIC_DIR.mkdir(exist_ok=True)

# ============================================================================
# BASE DE DATOS
# ============================================================================

class PointDatabase:
    """Gestor de base de datos para puntos RTK"""

    def __init__(self, db_path):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        """Inicializar base de datos"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS points (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    point_id TEXT UNIQUE NOT NULL,
                    name TEXT,
                    description TEXT,
                    latitude REAL NOT NULL,
                    longitude REAL NOT NULL,
                    altitude REAL NOT NULL,
                    quality INTEGER,
                    rtk_status TEXT,
                    hdop REAL,
                    satellites INTEGER,
                    estimated_accuracy REAL,
                    timestamp INTEGER NOT NULL,
                    date_str TEXT NOT NULL,
                    time_str TEXT NOT NULL
                )
            """)
            conn.commit()

    def add_point(self, point_data):
        """Agregar punto a la base de datos"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO points (
                    point_id, name, description, latitude, longitude, altitude,
                    quality, rtk_status, hdop, satellites, estimated_accuracy,
                    timestamp, date_str, time_str
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                point_data['point_id'],
                point_data.get('name', ''),
                point_data.get('description', ''),
                point_data['latitude'],
                point_data['longitude'],
                point_data['altitude'],
                point_data.get('quality', 0),
                point_data.get('rtk_status', 'UNKNOWN'),
                point_data.get('hdop', 0.0),
                point_data.get('satellites', 0),
                point_data.get('estimated_accuracy', 0.0),
                point_data['timestamp'],
                point_data['date_str'],
                point_data['time_str']
            ))
            conn.commit()

    def get_all_points(self):
        """Obtener todos los puntos"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM points ORDER BY timestamp DESC
            """)
            return [dict(row) for row in cursor.fetchall()]

    def get_point(self, point_id):
        """Obtener un punto específico"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT * FROM points WHERE point_id = ?
            """, (point_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def delete_point(self, point_id):
        """Eliminar un punto"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM points WHERE point_id = ?", (point_id,))
            conn.commit()

    def delete_all_points(self):
        """Eliminar todos los puntos"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM points")
            conn.commit()

    def export_csv(self, filepath):
        """Exportar puntos a CSV"""
        import csv
        points = self.get_all_points()

        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            if not points:
                return

            writer = csv.DictWriter(f, fieldnames=points[0].keys())
            writer.writeheader()
            writer.writerows(points)

    def get_stats(self):
        """Obtener estadísticas de puntos"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN quality = 4 THEN 1 ELSE 0 END) as rtk_fixed,
                    SUM(CASE WHEN quality = 5 THEN 1 ELSE 0 END) as rtk_float,
                    AVG(estimated_accuracy) as avg_accuracy
                FROM points
            """)
            row = cursor.fetchone()
            return {
                'total': row[0] or 0,
                'rtk_fixed': row[1] or 0,
                'rtk_float': row[2] or 0,
                'avg_accuracy': round(row[3], 2) if row[3] else 0.0
            }

# ============================================================================
# FLASK APP
# ============================================================================

app = Flask(__name__, template_folder=str(TEMPLATE_DIR), static_folder=str(STATIC_DIR))
app.config['SECRET_KEY'] = 'gnssai-point-collector-2024'
socketio = SocketIO(app, cors_allowed_origins="*")

db = PointDatabase(DB_PATH)
latest_gnss_data = {}

# ============================================================================
# RUTAS API
# ============================================================================

@app.route('/')
def index():
    """Página principal"""
    return render_template('point_collector.html')

@app.route('/api/current-position')
def current_position():
    """Obtener posición actual del GNSS"""
    return jsonify(latest_gnss_data)

@app.route('/api/points', methods=['GET'])
def get_points():
    """Obtener todos los puntos"""
    return jsonify(db.get_all_points())

@app.route('/api/points', methods=['POST'])
def save_point():
    """Guardar un punto nuevo"""
    try:
        data = request.json

        # Validar datos requeridos
        if not all(k in data for k in ['latitude', 'longitude', 'altitude']):
            return jsonify({'error': 'Missing required fields'}), 400

        # Generar ID único
        now = datetime.now()
        point_id = data.get('point_id', f"PT_{now.strftime('%Y%m%d_%H%M%S')}")

        # Preparar datos del punto
        point_data = {
            'point_id': point_id,
            'name': data.get('name', f"Punto {point_id}"),
            'description': data.get('description', ''),
            'latitude': float(data['latitude']),
            'longitude': float(data['longitude']),
            'altitude': float(data['altitude']),
            'quality': int(data.get('quality', 0)),
            'rtk_status': data.get('rtk_status', 'UNKNOWN'),
            'hdop': float(data.get('hdop', 0.0)),
            'satellites': int(data.get('satellites', 0)),
            'estimated_accuracy': float(data.get('estimated_accuracy', 0.0)),
            'timestamp': int(time.time()),
            'date_str': now.strftime('%Y-%m-%d'),
            'time_str': now.strftime('%H:%M:%S')
        }

        db.add_point(point_data)

        # Emitir actualización por WebSocket
        socketio.emit('point_saved', point_data, namespace='/points')

        return jsonify({'success': True, 'point': point_data})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/points/<point_id>', methods=['DELETE'])
def delete_point(point_id):
    """Eliminar un punto"""
    try:
        db.delete_point(point_id)
        socketio.emit('point_deleted', {'point_id': point_id}, namespace='/points')
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/points/delete-all', methods=['POST'])
def delete_all_points():
    """Eliminar todos los puntos"""
    try:
        db.delete_all_points()
        socketio.emit('all_points_deleted', {}, namespace='/points')
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/export/csv')
def export_csv():
    """Exportar puntos a CSV"""
    try:
        csv_path = DATA_DIR / f"points_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        db.export_csv(csv_path)
        return send_file(csv_path, as_attachment=True, download_name='points.csv')
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/export/json')
def export_json():
    """Exportar puntos a JSON"""
    try:
        points = db.get_all_points()
        json_path = DATA_DIR / f"points_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(points, f, indent=2, ensure_ascii=False)

        return send_file(json_path, as_attachment=True, download_name='points.json')
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats')
def get_stats():
    """Obtener estadísticas"""
    return jsonify(db.get_stats())

# ============================================================================
# WEBSOCKET
# ============================================================================

@socketio.on('connect', namespace='/points')
def handle_connect():
    print("📱 Cliente conectado a /points")

@socketio.on('disconnect', namespace='/points')
def handle_disconnect():
    print("📱 Cliente desconectado de /points")

# ============================================================================
# BACKGROUND TASKS
# ============================================================================

def read_gnss_data():
    """Leer datos GNSS del JSON compartido"""
    global latest_gnss_data

    while True:
        try:
            if os.path.exists(JSON_DATA_FILE):
                with open(JSON_DATA_FILE, 'r') as f:
                    data = json.load(f)
                    latest_gnss_data = data

                    # Emitir actualización por WebSocket
                    socketio.emit('gnss_update', data, namespace='/points')
        except Exception as e:
            print(f"⚠️ Error leyendo GNSS data: {e}")

        time.sleep(0.5)  # 2Hz

# ============================================================================
# MAIN
# ============================================================================

def main():
    """Iniciar servidor"""
    print("=" * 70)
    print("📍 GNSS.AI Point Collector - Aplicación de Toma de Puntos RTK")
    print("=" * 70)
    print(f"📊 Base de datos: {DB_PATH}")
    print(f"📁 Directorio de datos: {DATA_DIR}")
    print(f"🌐 Acceso web: http://0.0.0.0:8080")
    print(f"📱 Desde celular: http://<IP_RASPBERRY>:8080")
    print("=" * 70)
    print("✅ Servidor iniciado. Ctrl+C para detener.")
    print("")

    # Iniciar thread de lectura GNSS
    gnss_thread = threading.Thread(target=read_gnss_data, daemon=True)
    gnss_thread.start()

    # Iniciar servidor
    socketio.run(app, host="0.0.0.0", port=8080, debug=False, allow_unsafe_werkzeug=True)

if __name__ == "__main__":
    main()
