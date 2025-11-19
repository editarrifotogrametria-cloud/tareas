#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GPS Server - Professional Web Interface
Serves multiple GPS interfaces:
- /dashboard - Real-time GNSS dashboard with ML and Tilt
- /collector - Point collection interface (Emlid Flow style)
- /api/stats - JSON API for GPS data
"""

import os
import json
import time
import threading
from datetime import datetime
from flask import Flask, jsonify, send_file, send_from_directory, request
from flask_socketio import SocketIO

# ====================================================================
# Configuration
# ====================================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
TEMPLATE_DIR = os.path.join(BASE_DIR, "templates")
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

# ====================================================================
# Global State
# ====================================================================
latest_stats = {}
uptime_sec = 0

# ====================================================================
# Flask App Setup
# ====================================================================
app = Flask(__name__)
app.config['SECRET_KEY'] = 'gps-collector-secret-key'
socketio = SocketIO(app, cors_allowed_origins="*")

# ====================================================================
# Utility Functions
# ====================================================================
def safe_read_json(path):
    """Safely read JSON file."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

# ====================================================================
# Background Threads
# ====================================================================
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

# ====================================================================
# Routes
# ====================================================================

@app.route("/")
def index():
    """Landing page with links to different interfaces."""
    html = """
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>GPS Server - Home</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }
            .container {
                max-width: 1200px;
                width: 100%;
            }
            .header {
                text-align: center;
                color: white;
                margin-bottom: 40px;
            }
            .header h1 {
                font-size: 48px;
                margin-bottom: 12px;
            }
            .header p {
                font-size: 18px;
                opacity: 0.9;
            }
            .cards {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 24px;
            }
            .card {
                background: white;
                border-radius: 12px;
                padding: 32px;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                transition: transform 0.3s, box-shadow 0.3s;
                cursor: pointer;
                text-decoration: none;
                color: inherit;
                display: block;
            }
            .card:hover {
                transform: translateY(-8px);
                box-shadow: 0 30px 80px rgba(0, 0, 0, 0.4);
            }
            .card-icon {
                font-size: 48px;
                margin-bottom: 16px;
            }
            .card h2 {
                font-size: 22px;
                margin-bottom: 12px;
                color: #333;
            }
            .card p {
                color: #666;
                line-height: 1.6;
                font-size: 14px;
            }
            .badge {
                display: inline-block;
                background: #667eea;
                color: white;
                padding: 4px 12px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 600;
                margin-top: 12px;
            }
            .badge-featured {
                background: #4CAF50;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🛰️ GPS Server</h1>
                <p>Interfaces profesionales para recolección y monitoreo GPS</p>
            </div>
            <div class="cards">
                <a href="/funcionable" class="card">
                    <div class="card-icon">⭐</div>
                    <h2>GNSS Point Collector</h2>
                    <p>Aplicación web profesional de Comnav para captura de puntos GNSS con RTK, NTRIP, y gestión de proyectos completa.</p>
                    <span class="badge badge-featured">FUNCIONABLE</span>
                </a>
                <a href="/comnav" class="card">
                    <div class="card-icon">⚙️</div>
                    <h2>ComNav Control</h2>
                    <p>Control completo del módulo ComNav K222 con comandos, configuración INS/TILT, y monitoreo en tiempo real.</p>
                    <span class="badge">CONTROL</span>
                </a>
                <a href="/professional" class="card">
                    <div class="card-icon">🛰️</div>
                    <h2>GPS Professional</h2>
                    <p>Interfaz completa con Proyectos, DATUM, Tomar Puntos, Replantear, PPP, TILT, y Cámara con EXIF. Todo en uno.</p>
                    <span class="badge">PROFESIONAL</span>
                </a>
                <a href="/collector" class="card">
                    <div class="card-icon">📍</div>
                    <h2>Point Collector</h2>
                    <p>Interfaz simple estilo Emlid Flow para recolección rápida de puntos GPS RTK.</p>
                    <span class="badge">SIMPLE</span>
                </a>
                <a href="/dashboard" class="card">
                    <div class="card-icon">📊</div>
                    <h2>Dashboard</h2>
                    <p>Dashboard técnico con visualización de datos GNSS, Machine Learning, y estadísticas.</p>
                    <span class="badge">TÉCNICO</span>
                </a>
            </div>
        </div>
    </body>
    </html>
    """
    return html

@app.route("/collector")
def collector():
    """Serve the GPS Point Collector interface."""
    try:
        file_path = os.path.join(BASE_DIR, "gps_collector.html")
        if os.path.exists(file_path):
            return send_file(file_path)
        else:
            # Redirect to professional interface if old file doesn't exist
            return send_file(os.path.join(BASE_DIR, "gps_professional.html"))
    except Exception as e:
        return f"Error: {str(e)}", 500

@app.route("/professional")
def professional():
    """Serve the Professional GPS interface with all features."""
    try:
        return send_file(os.path.join(BASE_DIR, "gps_professional.html"))
    except Exception as e:
        return f"Error loading professional interface: {str(e)}", 500

@app.route("/comnav")
def comnav_control():
    """Serve the ComNav K222 Control & Monitor interface."""
    try:
        return send_file(os.path.join(BASE_DIR, "comnav_control.html"))
    except Exception as e:
        return f"Error loading ComNav control interface: {str(e)}", 500

@app.route("/dashboard")
def dashboard():
    """Serve the technical dashboard."""
    # Read the embedded HTML from dashboard_server.py
    # For simplicity, we'll create a basic redirect to the collector
    # In production, you'd want to serve the actual dashboard HTML
    try:
        with open(os.path.join(BASE_DIR, "dashboard_server.py"), "r") as f:
            content = f.read()
            # Extract the DASHBOARD_HTML content
            start = content.find('DASHBOARD_HTML = """') + len('DASHBOARD_HTML = """')
            end = content.find('"""', start)
            dashboard_html = content[start:end]
            return dashboard_html
    except Exception as e:
        return f"Error loading dashboard: {str(e)}", 500

@app.route("/api/stats")
def api_stats():
    """API endpoint for GPS statistics."""
    data = dict(latest_stats) if latest_stats else {}

    # Add uptime
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

@app.route("/funcionable")
def funcionable():
    """Serve the FUNCIONABLE GNSS Point Collector."""
    try:
        funcionable_path = os.path.join(os.path.dirname(BASE_DIR), "funcionable", "index.html")
        return send_file(funcionable_path)
    except Exception as e:
        return f"Error loading FUNCIONABLE interface: {str(e)}", 500

@app.route("/funcionable/static/css/<path:filename>")
def funcionable_css(filename):
    """Serve FUNCIONABLE CSS files."""
    funcionable_static = os.path.join(os.path.dirname(BASE_DIR), "funcionable", "static", "css")
    return send_from_directory(funcionable_static, filename)

@app.route("/funcionable/static/js/<path:filename>")
def funcionable_js(filename):
    """Serve FUNCIONABLE JavaScript files."""
    funcionable_static = os.path.join(os.path.dirname(BASE_DIR), "funcionable", "static", "js")
    return send_from_directory(funcionable_static, filename)

@app.route("/funcionable/config.example.json")
def funcionable_config():
    """Serve FUNCIONABLE config example."""
    funcionable_path = os.path.join(os.path.dirname(BASE_DIR), "funcionable")
    return send_from_directory(funcionable_path, "config.example.json")

@app.route("/static/<path:filename>")
def static_files(filename):
    """Serve static files."""
    return send_from_directory(STATIC_DIR, filename)

# ====================================================================
# WebSocket Events
# ====================================================================
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

# ====================================================================
# Main Entry Point
# ====================================================================
def main():
    """Start the GPS server."""
    # Ensure directories exist
    os.makedirs(STATIC_DIR, exist_ok=True)
    os.makedirs(TEMPLATE_DIR, exist_ok=True)

    # Start background threads
    t_json = threading.Thread(target=read_json_data, daemon=True)
    t_json.start()

    t_uptime = threading.Thread(target=update_uptime, daemon=True)
    t_uptime.start()

    # Print startup information
    print("=" * 70)
    print("🛰️  GPS Server - Professional Web Interface")
    print("=" * 70)
    print(f"🏠 Home:              http://0.0.0.0:5000")
    print(f"⭐ FUNCIONABLE:       http://0.0.0.0:5000/funcionable    ✨ DESTACADO")
    print(f"⚙️ ComNav Control:    http://0.0.0.0:5000/comnav         🎯 TILT")
    print(f"🎯 Professional:      http://0.0.0.0:5000/professional")
    print(f"📍 Collector:         http://0.0.0.0:5000/collector")
    print(f"📊 Dashboard:         http://0.0.0.0:5000/dashboard")
    print(f"📡 API:               http://0.0.0.0:5000/api/stats")
    print(f"📡 ComNav API:        http://0.0.0.0:5000/api/comnav/command")
    print(f"💾 Data Source:       {JSON_DATA_FILE}")
    print("=" * 70)
    print("⭐ FUNCIONABLE: Aplicación web profesional Comnav completa")
    print("✨ ComNav Control: K222 con soporte INS/TILT avanzado")
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
