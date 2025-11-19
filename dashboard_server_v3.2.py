#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GNSS.AI Dashboard Server v3.2 - ACTUALIZADO PARA PI ZERO 2W
- Lee /tmp/gnssai_dashboard_data.json
- Sirve un dashboard HTML responsivo (index.html)
- API REST /api/stats
- Socket.IO v5+ compatible (sin polling EIO=3)
"""

import os
import json
import time
import threading
from datetime import datetime

from flask import Flask, jsonify, render_template, send_from_directory
from flask_socketio import SocketIO, emit

# --------------------------------------------------------------------
# Rutas base
# --------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_DIR = os.path.join(BASE_DIR, "templates")
STATIC_DIR = os.path.join(BASE_DIR, "static")
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"

# --------------------------------------------------------------------
# Plantilla HTML ACTUALIZADA (sin Socket.IO v3, usa fetch polling)
# --------------------------------------------------------------------
DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <title>GNSS.AI Dashboard - K222</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <style>
        :root {
            --bg: #050816;
            --bg-card: #0f172a;
            --bg-card-soft: #020617;
            --accent: #22c55e;
            --accent-soft: #4ade80;
            --danger: #ef4444;
            --warning: #f97316;
            --text: #e5e7eb;
            --muted: #9ca3af;
            --border: #1f2937;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: radial-gradient(circle at top, #1e293b 0, #020617 55%, #000 100%);
            color: var(--text);
            min-height: 100vh;
            padding: 12px;
        }

        .app-shell {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .title-block h1 {
            font-size: 1.4rem;
            letter-spacing: 0.04em;
        }

        .title-block span {
            font-size: 0.75rem;
            color: var(--muted);
        }

        .status-pill {
            padding: 4px 10px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 0.75rem;
            background: rgba(34, 197, 94, 0.12);
            border: 1px solid rgba(34, 197, 94, 0.5);
        }
        .status-pill.offline {
            background: rgba(239, 68, 68, 0.12);
            border: 1px solid rgba(239, 68, 68, 0.5);
        }
        .status-dot {
            width: 6px;
            height: 6px;
            border-radius: 999px;
            background: var(--accent);
            box-shadow: 0 0 8px rgba(34, 197, 94, 0.6);
        }
        .status-dot.offline {
            background: var(--danger);
            box-shadow: 0 0 8px rgba(239, 68, 68, 0.6);
        }

        main {
            display: grid;
            grid-template-columns: minmax(0, 1.4fr) minmax(0, 1.1fr);
            gap: 10px;
        }

        @media (max-width: 850px) {
            main {
                grid-template-columns: minmax(0, 1fr);
            }
        }

        .card {
            background: radial-gradient(circle at top left, #1f2937 0, #020617 60%);
            border-radius: 12px;
            padding: 10px;
            border: 1px solid rgba(15, 23, 42, 0.9);
            box-shadow: 0 12px 25px rgba(15, 23, 42, 0.6);
        }

        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }

        .card-header h2 {
            font-size: 0.95rem;
            text-transform: uppercase;
            letter-spacing: 0.12em;
            color: var(--muted);
        }

        .badge {
            font-size: 0.7rem;
            padding: 2px 8px;
            border-radius: 999px;
            border: 1px solid var(--border);
            color: var(--muted);
        }

        .card-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 6px;
        }

        .stat-chip {
            padding: 6px 8px;
            border-radius: 8px;
            background: rgba(15, 23, 42, 0.9);
            border: 1px solid #111827;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .stat-label {
            font-size: 0.7rem;
            color: var(--muted);
        }

        .stat-value {
            font-size: 0.9rem;
        }

        .stat-value.em {
            font-size: 1.05rem;
        }

        .stat-sub {
            font-size: 0.7rem;
            color: var(--muted);
        }

        .quality-tag {
            font-size: 0.75rem;
            padding: 2px 8px;
            border-radius: 999px;
            border: 1px solid var(--border);
        }

        .quality-fixed {
            color: var(--accent-soft);
            border-color: rgba(34, 197, 94, 0.6);
            background: rgba(22, 163, 74, 0.15);
        }
        .quality-float {
            color: #38bdf8;
            border-color: rgba(56, 189, 248, 0.6);
            background: rgba(15, 23, 42, 0.9);
        }
        .quality-dgps,
        .quality-gps {
            color: var(--warning);
            border-color: rgba(249, 115, 22, 0.6);
            background: rgba(30, 64, 175, 0.25);
        }
        .quality-nofix {
            color: var(--danger);
            border-color: rgba(248, 113, 113, 0.6);
            background: rgba(127, 29, 29, 0.25);
        }

        /* Tilt visualization */
        .tilt-wrapper {
            display: grid;
            grid-template-columns: 140px minmax(0, 1fr);
            gap: 8px;
            align-items: center;
        }

        @media (max-width: 600px) {
            .tilt-wrapper {
                grid-template-columns: minmax(0, 1fr);
            }
        }

        .tilt-visual {
            width: 120px;
            height: 120px;
            border-radius: 999px;
            margin: 0 auto;
            border: 3px solid #1f2937;
            position: relative;
            background: radial-gradient(circle at top, #4f46e5 0, #020617 55%);
            box-shadow: 0 0 0 1px rgba(148, 163, 184, 0.3), 0 12px 25px rgba(15, 23, 42, 0.9);
        }

        .tilt-circle {
            position: absolute;
            inset: 10px;
            border-radius: inherit;
            border: 1px dashed rgba(148, 163, 184, 0.4);
        }

        .tilt-rod {
            position: absolute;
            left: 50%;
            top: 14%;
            transform-origin: 50% 80%;
            width: 3px;
            height: 70px;
            border-radius: 999px;
            background: linear-gradient(to bottom, #22c55e, #bef264);
            box-shadow: 0 0 6px rgba(190, 242, 100, 0.8);
        }

        .tilt-antenna {
            position: absolute;
            left: 50%;
            top: 10%;
            transform: translateX(-50%);
            width: 22px;
            height: 22px;
            border-radius: 999px;
            background: radial-gradient(circle at top, #22c55e, #166534);
            box-shadow: 0 0 10px rgba(74, 222, 128, 0.9), 0 0 22px rgba(22, 163, 74, 0.9);
        }

        .tilt-base {
            position: absolute;
            bottom: 10px;
            left: 50%;
            width: 40px;
            height: 8px;
            transform: translateX(-50%);
            border-radius: 999px;
            background: rgba(15, 23, 42, 0.75);
            box-shadow: 0 0 12px rgba(15, 23, 42, 1);
        }

        footer {
            margin-top: 4px;
            font-size: 0.7rem;
            color: var(--muted);
            display: flex;
            justify-content: space-between;
            gap: 4px;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
<div class="app-shell">
    <header>
        <div class="title-block">
            <h1>GNSS.AI <span style="color:#38bdf8;">Dashboard</span></h1>
            <span>ComNav K222 · Raspberry Pi Zero 2W</span>
            <span id="uptime-span">Uptime: --</span>
        </div>
        <div>
            <div class="status-pill" id="status-pill">
                <span class="status-dot" id="status-dot"></span>
                <span id="conn-label">CONECTANDO...</span>
            </div>
        </div>
    </header>

    <main>
        <!-- Columna izquierda: posición + RTK -->
        <section class="card">
            <div class="card-header">
                <h2>Posición / RTK</h2>
                <span class="badge" id="timestamp-span">Actualizando...</span>
            </div>

            <div class="card-grid">
                <div class="stat-chip">
                    <div class="stat-label">Latitud</div>
                    <div class="stat-value em" id="lat-span">--</div>
                    <div class="stat-sub">grados decimales</div>
                </div>
                <div class="stat-chip">
                    <div class="stat-label">Longitud</div>
                    <div class="stat-value em" id="lon-span">--</div>
                    <div class="stat-sub">grados decimales</div>
                </div>
                <div class="stat-chip">
                    <div class="stat-label">Altura elipsoidal</div>
                    <div class="stat-value em" id="alt-span">--</div>
                    <div class="stat-sub">m</div>
                </div>
                <div class="stat-chip">
                    <div class="stat-label">Sats / HDOP</div>
                    <div class="stat-value em">
                        <span id="sats-span">--</span> sats
                    </div>
                    <div class="stat-sub">HDOP <span id="hdop-span">--</span></div>
                </div>
            </div>

            <div style="margin-top: 8px; display:flex; justify-content: space-between; align-items: center; gap: 6px; flex-wrap: wrap;">
                <div id="rtk-chip" class="quality-tag quality-nofix">NO FIX</div>
                <div style="display:flex; gap:6px; flex-wrap:wrap; font-size:0.7rem;">
                    <div class="stat-sub">NMEA: <span id="nmea-span">0</span></div>
                    <div class="stat-sub">RTCM: <span id="rtcm-span">0</span></div>
                </div>
            </div>
        </section>

        <!-- Columna derecha: ML + TILT -->
        <section class="card">
            <div class="card-header">
                <h2>ML + Tilt</h2>
                <span class="badge" id="ml-badge">ML: Standby</span>
            </div>

            <div class="tilt-wrapper">
                <!-- Visual tilt -->
                <div class="tilt-visual">
                    <div class="tilt-circle"></div>
                    <div class="tilt-antenna" id="tilt-antenna"></div>
                    <div class="tilt-rod" id="tilt-rod"></div>
                    <div class="tilt-base"></div>
                </div>

                <!-- Datos tilt + ML -->
                <div style="display:flex; flex-direction:column; gap:6px;">
                    <div class="card-grid">
                        <div class="stat-chip">
                            <div class="stat-label">Ángulo inclinación</div>
                            <div class="stat-value em"><span id="tilt-angle">0</span>°</div>
                        </div>
                        <div class="stat-chip">
                            <div class="stat-label">Heading</div>
                            <div class="stat-value em"><span id="tilt-heading">0</span>°</div>
                        </div>
                        <div class="stat-chip">
                            <div class="stat-label">Pitch / Roll</div>
                            <div class="stat-value">
                                <span id="tilt-pitch">0</span>° / <span id="tilt-roll">0</span>°
                            </div>
                        </div>
                        <div class="stat-chip">
                            <div class="stat-label">LOS / MP / NLOS</div>
                            <div class="stat-value">
                                <span id="los-span">0</span> / <span id="mp-span">0</span> / <span id="nlos-span">0</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer>
        <span id="format-span">Formato: NMEA</span>
        <span id="acc-span">Precisión: -- cm</span>
    </footer>
</div>

<script>
// Funciones de formato
const fmt = (value, digits=3) => {
    if (value === null || value === undefined || isNaN(value)) return "--";
    return Number(value).toFixed(digits);
};

const qualityLabel = (q) => {
    if (q === 4 || q === "4") return "RTK FIXED";
    if (q === 5 || q === "5") return "RTK FLOAT";
    if (q === 2 || q === "2") return "DGPS";
    if (q === 1 || q === "1") return "GPS";
    return "NO FIX";
};

const qualityClass = (q) => {
    if (q === 4 || q === "4") return "quality-tag quality-fixed";
    if (q === 5 || q === "5") return "quality-tag quality-float";
    if (q === 2 || q === "2" || q === 1 || q === "1") return "quality-tag quality-gps";
    return "quality-tag quality-nofix";
};

const formatUptime = (seconds) => {
    if (seconds == null) return "--";
    seconds = Math.floor(seconds);
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return `${h.toString().padStart(2,"0")}:${m.toString().padStart(2,"0")}:${s.toString().padStart(2,"0")}`;
};

// Actualizar UI con datos
function updateUI(data) {
    if (!data) return;

    // Posición
    const pos = data.position || {};
    document.getElementById("lat-span").textContent = fmt(pos.lat, 7);
    document.getElementById("lon-span").textContent = fmt(pos.lon, 7);
    document.getElementById("alt-span").textContent = fmt(pos.alt, 3);

    document.getElementById("sats-span").textContent = data.satellites ?? "--";
    document.getElementById("hdop-span").textContent = fmt(data.hdop, 2);
    document.getElementById("nmea-span").textContent = data.nmea_sent ?? 0;
    document.getElementById("rtcm-span").textContent = data.rtcm_sent ?? 0;

    // RTK Status
    const q = data.quality;
    const rtkStatus = data.rtk_status || qualityLabel(q);
    const rtkChip = document.getElementById("rtk-chip");
    rtkChip.textContent = rtkStatus;
    rtkChip.className = qualityClass(q);

    // ML
    document.getElementById("los-span").textContent = data.los_sats ?? 0;
    document.getElementById("mp-span").textContent = data.multipath_sats ?? 0;
    document.getElementById("nlos-span").textContent = data.nlos_sats ?? 0;

    const mlCor = data.ml_corrections ?? 0;
    const mlBadge = document.getElementById("ml-badge");
    if (mlCor > 0) {
        mlBadge.textContent = `ML: ${mlCor} correcciones`;
    } else {
        mlBadge.textContent = "ML: Standby";
    }

    // Formato/precisión
    document.getElementById("format-span").textContent = "Formato: " + (data.format || "NMEA");
    const acc = data.estimated_accuracy ?? 0;
    document.getElementById("acc-span").textContent = "Precisión: " + fmt(acc, 1) + " cm";

    // Uptime
    const uptime = data.uptime_sec ?? null;
    document.getElementById("uptime-span").textContent = "Uptime: " + formatUptime(uptime);

    // Timestamp
    const lastUpdate = data.last_update;
    if (lastUpdate) {
        try {
            const dt = new Date(lastUpdate * 1000);
            const isoTime = dt.toISOString().split("T")[1].split(".")[0];
            document.getElementById("timestamp-span").textContent = isoTime + " UTC";
        } catch (e) {
            document.getElementById("timestamp-span").textContent = "--";
        }
    }

    // Tilt
    const tilt = data.tilt || {};
    const pitch = tilt.pitch ?? 0;
    const roll = tilt.roll ?? 0;
    const heading = tilt.heading ?? 0;
    const angle = tilt.angle ?? 0;

    document.getElementById("tilt-pitch").textContent = fmt(pitch, 1);
    document.getElementById("tilt-roll").textContent = fmt(roll, 1);
    document.getElementById("tilt-heading").textContent = fmt(heading, 1);
    document.getElementById("tilt-angle").textContent = fmt(angle, 1);

    // Animación tilt
    const tiltRod = document.getElementById("tilt-rod");
    const tiltAntena = document.getElementById("tilt-antenna");
    const clampedAngle = Math.max(0, Math.min(30, Math.abs(angle)));
    const scaleY = 1 + (clampedAngle / 60.0);

    tiltRod.style.transform = `translate(-50%, 0) rotate(${roll}deg) scaleY(${scaleY})`;
    tiltAntena.style.transform = `translateX(-50%) translateY(${-clampedAngle / 4}px)`;

    // Estado de conexión
    setConnectionStatus(true);
}

// Estado de conexión
function setConnectionStatus(online) {
    const pill = document.getElementById("status-pill");
    const dot = document.getElementById("status-dot");
    const label = document.getElementById("conn-label");

    if (online) {
        pill.classList.remove("offline");
        dot.classList.remove("offline");
        label.textContent = "ONLINE";
    } else {
        pill.classList.add("offline");
        dot.classList.add("offline");
        label.textContent = "OFFLINE";
    }
}

// Polling con fetch (sin Socket.IO)
async function pollStats() {
    try {
        const resp = await fetch("/api/stats");
        if (!resp.ok) throw new Error("HTTP " + resp.status);
        const data = await resp.json();
        updateUI(data);
    } catch (err) {
        console.warn("Error obteniendo /api/stats:", err);
        setConnectionStatus(false);
    } finally {
        setTimeout(pollStats, 1000);
    }
}

// Iniciar al cargar
document.addEventListener("DOMContentLoaded", () => {
    console.log("🛰️  GNSS.AI Dashboard iniciado (Pi Zero 2W)");
    pollStats();
});
</script>
</body>
</html>
"""

# --------------------------------------------------------------------
# Estado global
# --------------------------------------------------------------------
latest_stats = {}
uptime_sec = 0

# --------------------------------------------------------------------
# Flask + SocketIO (CONFIGURACIÓN ACTUALIZADA)
# --------------------------------------------------------------------
app = Flask(__name__, template_folder=TEMPLATE_DIR, static_folder=STATIC_DIR)
app.config['SECRET_KEY'] = 'gnssai-secret-2024'

# SocketIO con configuración compatible moderna
socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode='threading',
    logger=False,
    engineio_logger=False,
    ping_timeout=60,
    ping_interval=25
)

# --------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------
def ensure_template():
    """Crea templates/index.html si no existe."""
    os.makedirs(TEMPLATE_DIR, exist_ok=True)
    path = os.path.join(TEMPLATE_DIR, "index.html")
    if not os.path.exists(path):
        with open(path, "w", encoding="utf-8") as f:
            f.write(DASHBOARD_HTML)

def safe_read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

# --------------------------------------------------------------------
# Threads de backend
# --------------------------------------------------------------------
def read_json_data():
    """Lee periódicamente /tmp/gnssai_dashboard_data.json y actualiza latest_stats."""
    global latest_stats
    while True:
        data = safe_read_json(JSON_DATA_FILE)
        if data:
            latest_stats = data
        time.sleep(1.0)

def update_uptime():
    """Contador de uptime en segundos."""
    global uptime_sec
    while True:
        uptime_sec += 1
        time.sleep(1.0)

# --------------------------------------------------------------------
# Rutas HTTP
# --------------------------------------------------------------------
@app.route("/")
def index():
    ensure_template()
    return render_template("index.html")

@app.route("/api/stats")
def api_stats():
    ensure_template()
    data = dict(latest_stats) if latest_stats else {}

    # Inyectar uptime
    data["uptime_sec"] = uptime_sec

    # Asegurar bloque tilt
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

# --------------------------------------------------------------------
# Socket.IO (opcional, ya no se usa en el HTML)
# --------------------------------------------------------------------
@socketio.on("connect", namespace="/gnss")
def handle_connect():
    print("🔗 Cliente conectado a /gnss")
    if latest_stats:
        emit("stats", latest_stats, namespace="/gnss")

@socketio.on("disconnect", namespace="/gnss")
def handle_disconnect():
    print("🔌 Cliente desconectado de /gnss")

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------
def main():
    ensure_template()

    # Lanzar threads
    t_json = threading.Thread(target=read_json_data, daemon=True)
    t_json.start()

    t_up = threading.Thread(target=update_uptime, daemon=True)
    t_up.start()

    print("=" * 60)
    print("🛰️  GNSS.AI Dashboard Server v3.2 (Pi Zero 2W Compatible)")
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
