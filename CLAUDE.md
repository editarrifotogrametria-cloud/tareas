# CLAUDE.md - GNSS.AI Project Documentation

**Last Updated:** 2025-11-20
**Project:** GNSS.AI RTK Positioning System with Machine Learning

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Codebase Structure](#codebase-structure)
4. [Core Components](#core-components)
5. [Data Flow](#data-flow)
6. [Development Workflows](#development-workflows)
7. [Key Conventions](#key-conventions)
8. [Configuration](#configuration)
9. [Testing & Debugging](#testing--debugging)
10. [Common Tasks](#common-tasks)
11. [Troubleshooting](#troubleshooting)

---

## Project Overview

GNSS.AI is a sophisticated GNSS/RTK positioning system designed for high-precision positioning applications. The system integrates:

- **GNSS/RTK Processing**: Supports K222/K902/K922 GNSS modules with RTK capabilities
- **Machine Learning**: Real-time satellite signal classification (LOS/Multipath/NLOS)
- **Tilt Compensation**: INS/IMU integration for tilt-compensated measurements
- **Bluetooth Connectivity**: SPP server for wireless NMEA data transmission
- **Web Dashboard**: Real-time visualization of positioning data and statistics
- **ML Training Pipeline**: Data collection and model training for signal classification

### Target Hardware
- **GNSS Modules**: K222, K902, K922 (SinoGNSS/ComNav)
- **Platform**: Raspberry Pi or similar Linux SBC
- **Interface**: UART (typically `/dev/serial0` at 115200 baud)
- **Connectivity**: Bluetooth SPP, HTTP/WebSocket

---

## Architecture

The system follows a multi-process architecture with IPC via FIFO and shared JSON files:

```
┌─────────────────────────────────────────────────────────────┐
│                    GNSS Module (K222/K902/K922)             │
│                    UART: /dev/serial0 @ 115200              │
└────────────────────────────┬────────────────────────────────┘
                             │ NMEA/RTCM
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              smart_processor.py (Main Process)              │
│  • Reads UART NMEA data                                     │
│  • Parses GGA, GSV, TILT sentences                          │
│  • ML signal classification                                 │
│  • Writes to FIFO → Bluetooth                               │
│  • Updates JSON → Dashboard                                 │
└──────────────┬─────────────────────┬────────────────────────┘
               │                     │
               │ FIFO                │ JSON
               │ /tmp/gnssai_smart   │ /tmp/gnssai_dashboard_data.json
               ▼                     ▼
┌──────────────────────────┐  ┌─────────────────────────────┐
│  bluetooth_spp_server.py │  │   dashboard_server.py       │
│  • Reads from FIFO       │  │   • Flask web server        │
│  • Bluetooth SPP         │  │   • Reads JSON (1Hz)        │
│  • Transmits to clients  │  │   • Serves dashboard        │
└──────────────────────────┘  │   • REST API + SocketIO     │
                              └─────────────────────────────┘
                                        │
                                        ▼ HTTP/WebSocket
                              ┌─────────────────────────────┐
                              │   Web Browser Dashboard      │
                              │   • Real-time stats          │
                              │   • Position/RTK display     │
                              │   • ML visualization         │
                              │   • Tilt indicators          │
                              └─────────────────────────────┘
```

---

## Codebase Structure

```
tareas/
├── Core Processing
│   ├── smart_processor.py           # Main NMEA processor (v3.3)
│   ├── smart_processor_backup.py    # Backup version
│   └── smart_processor.py.backup    # Old backup
│
├── Web Dashboard
│   ├── dashboard_server.py          # Flask server (v3.1)
│   └── templates/                   # Auto-generated HTML templates
│       └── index.html               # Dashboard UI
│
├── Bluetooth
│   └── bluetooth_spp_server.py      # SPP server for NMEA transmission
│
├── Machine Learning
│   ├── ml_classifier.py             # Signal classifier (LOS/NLOS/Multipath)
│   ├── gnssai_trainer.py            # ML model training pipeline
│   └── gnssai_collector.py          # Training data collection
│
├── Configuration UI
│   ├── app.js                       # K922 config panel (WebSocket client)
│   ├── index.guia.html              # Configuration UI
│   └── styles.css                   # UI styling
│
├── Static Assets
│   ├── staticcsschunk-vendors.*.css.txt
│   ├── staticcssindex.*.css.txt
│   ├── staticjschunk-common.*.js.txt
│   ├── staticjschunk-vendors.*.js.txt
│   └── staticjsindex.*.js.txt
│
├── Documentation
│   ├── ComNav OEM Board Reference Manual_V1.8 (1).pdf
│   ├── ComNav OEM Board Reference Manual_V1.8 (1).docx
│   ├── SinoGNSS_K922_GNSS_Module_Specification_v1.4.pdf
│   └── 华圳物联（K922）规格书V1.0.pdf
│
└── Flags/Markers
    ├── ARE                          # Marker file
    ├── APP FUNCIONA                 # Status marker
    └── shh                          # Empty marker
```

---

## Core Components

### 1. Smart Processor (`smart_processor.py`)

**Purpose**: Main GNSS data processor
**Version**: 3.3
**Process**: Long-running daemon

**Key Responsibilities:**
- Read NMEA sentences from UART (`/dev/serial0` @ 115200)
- Parse GGA (position, quality, HDOP, satellites)
- Parse GSV (satellite details: PRN, elevation, azimuth, SNR)
- Parse TILT sentences (pitch, roll, heading) - skeleton implementation
- ML classification of satellite signals
- Write NMEA to FIFO (`/tmp/gnssai_smart`) for Bluetooth
- Update dashboard JSON (`/tmp/gnssai_dashboard_data.json`) every 20 NMEA sentences

**Key Classes:**
```python
class SmartProcessor:
    def __init__(self)
    def setup_fifo(self)                 # Create/open FIFO
    def connect_uart(self)               # Open UART connection
    def parse_nmea_gga(self, line)       # Parse GGA sentences
    def parse_nmea_gsv(self, line)       # Parse GSV sentences
    def parse_tilt_sentence(self, line)  # Parse TILT (skeleton)
    def process_nmea_line(self, line)    # Main processing logic
    def write_output(self, data)         # Write to FIFO
    def update_dashboard_json(self)      # Update JSON for dashboard
    def run(self)                        # Main loop
```

**Important Notes:**
- FIFO opens in non-blocking mode (`O_NONBLOCK`) to handle missing readers
- FIFO automatically reopens if reader disconnects (EPIPE/ENXIO)
- ML classifier is optional - gracefully degrades if unavailable
- TILT parsing is a skeleton - needs customization for actual module sentences

**Key File Locations:**
- UART: `/dev/serial0`
- FIFO: `/tmp/gnssai_smart`
- JSON: `/tmp/gnssai_dashboard_data.json`

### 2. Dashboard Server (`dashboard_server.py`)

**Purpose**: Web-based visualization dashboard
**Version**: 3.1
**Framework**: Flask + Flask-SocketIO

**Endpoints:**
- `GET /` - Main dashboard HTML
- `GET /api/stats` - JSON stats API
- `GET /static/<filename>` - Static files
- WebSocket `/gnss` - Real-time updates

**Key Features:**
- Polls JSON file every 1 second
- Emits stats via SocketIO to connected clients
- Serves embedded HTML dashboard (auto-generated in `templates/`)
- Tracks uptime counter
- Displays position, RTK status, satellites, ML stats, tilt

**Dashboard Data Structure:**
```python
{
    "position": {"lat": float, "lon": float, "alt": float},
    "satellites": int,
    "satellites_detail": [...],  # Array of satellite objects
    "quality": int,              # 0=no fix, 1=GPS, 2=DGPS, 4=RTK_FIXED, 5=RTK_FLOAT
    "hdop": float,
    "nmea_sent": int,
    "rtcm_sent": int,
    "ml_corrections": int,
    "format_switches": int,
    "los_sats": int,
    "multipath_sats": int,
    "nlos_sats": int,
    "avg_confidence": float,     # 0-100
    "estimated_accuracy": float, # cm
    "rtk_status": str,           # "RTK_FIXED", "RTK_FLOAT", etc.
    "format": str,               # "NMEA" or "RTCM"
    "last_update": float,        # Unix timestamp
    "tilt": {
        "pitch": float,
        "roll": float,
        "heading": float,
        "angle": float,          # Total tilt angle
        "status": str            # "OK", "CALIBRATING", "NONE", "OFF"
    }
}
```

**Running:**
```bash
python3 dashboard_server.py
# Access at http://0.0.0.0:5000
```

### 3. Bluetooth SPP Server (`bluetooth_spp_server.py`)

**Purpose**: Bluetooth Serial Port Profile server for NMEA transmission
**Protocol**: RFCOMM (SPP)
**UUID**: `00001101-0000-1000-8000-00805F9B34FB`

**Key Features:**
- Advertises as "GNSS-AI" Bluetooth service
- Reads from FIFO (`/tmp/gnssai_smart`) using `select()` with timeout
- Transmits raw NMEA data to connected Bluetooth clients
- Handles client disconnections gracefully
- Waits for FIFO to exist before starting

**Running:**
```bash
# Requires Bluetooth hardware and pybluez
sudo python3 bluetooth_spp_server.py
```

### 4. ML Classifier (`ml_classifier.py`)

**Purpose**: Real-time satellite signal classification
**Models**: Rule-based + hybrid (ML placeholder)

**Signal Classes:**
- **LOS (Line of Sight)**: Direct signal, high quality (SNR ≥35, elevation ≥20°)
- **NLOS (Non-Line of Sight)**: Blocked signal (SNR <25, elevation <15°)
- **MULTIPATH**: Reflected signal (SNR 25-35, moderate elevation)

**Key Classes:**
```python
class SignalClassifier:
    def __init__(self, model_type="hybrid")
    def extract_features(self, satellite_data)     # Feature engineering
    def classify_by_rules(self, features)          # Rule-based classification
    def classify_with_ml(self, features)           # ML classification (placeholder)
    def classify_signals(self, satellite_data)     # Main classification entry point
    def get_stats(self)                            # Get classification statistics
```

**Features Extracted:**
- Elevation (0-90°)
- SNR (Signal-to-Noise Ratio)
- Azimuth (0-360°)
- Time of day
- Normalized quality metrics
- Historical trends (SNR/elevation)

**Integration:**
The classifier is imported by `smart_processor.py`:
```python
from ml_classifier import GNSS_ML_Classifier as GNSSClassifier
```

### 5. ML Training Pipeline

#### Data Collector (`gnssai_collector.py`)
**Purpose**: Collect training data from GNSS modules

**Usage:**
```bash
# Collect for 5 minutes in urban environment
python3 gnssai_collector.py 300 urban

# Collect for 1 hour in open sky
python3 gnssai_collector.py 3600 open_sky
```

**Output**: CSV files in `ml_training_data/session_YYYYMMDD_HHMMSS.csv`

**CSV Format:**
```
timestamp, prn, constellation, elevation, azimuth, snr, quality, hdop, environment
```

#### Model Trainer (`gnssai_trainer.py`)
**Purpose**: Train ML models from collected data

**Usage:**
```bash
python3 gnssai_trainer.py
```

**Pipeline:**
1. Load all session CSV files from `ml_training_data/`
2. Auto-label data based on heuristic rules
3. Train RandomForest classifier
4. Evaluate on test set
5. Save model to `ml_models/gnssai_classifier.joblib`

**Output:**
- Model: `ml_models/gnssai_classifier.joblib`
- Metadata: `ml_models/model_metadata.json`

### 6. Configuration UI (`app.js` + `index.guia.html`)

**Purpose**: WebSocket-based configuration panel for K922 modules
**Protocol**: WebSocket
**Target Device**: K922 (single COM1 port)

**Features:**
- Connect to backend WebSocket server
- Configure GNSS constellations (GPS, BDS, GLONASS, Galileo, QZSS, SBAS)
- Set RTK mode (standalone, rover, base)
- Configure NMEA output (talker, rate, messages)
- Configure RTCM messages
- IMU/INS fusion settings
- Export/import JSON configurations

**WebSocket Messages:**
```javascript
// Client → Server
{type: "hello", source: "gnssai-k922-com1-panel"}
{type: "getK922Status"}
{type: "applyK922Config", payload: {...}}

// Server → Client
{type: "k922Status", payload: {...}}
```

---

## Data Flow

### NMEA Processing Flow

```
1. UART → smart_processor.py reads line
2. smart_processor.py validates NMEA checksum
3. Parse sentence type:
   - GGA → extract position, quality, HDOP, sats
   - GSV → extract satellite details (PRN, elev, az, SNR)
   - TILT → extract pitch/roll/heading (skeleton)
4. ML classifier processes GSV data
5. Write NMEA to FIFO (/tmp/gnssai_smart) → bluetooth_spp_server.py
6. Every 20 sentences → update JSON (/tmp/gnssai_dashboard_data.json)
7. dashboard_server.py reads JSON every 1s
8. Dashboard updates via SocketIO to browser
```

### Bluetooth Data Flow

```
1. smart_processor.py writes NMEA → FIFO (/tmp/gnssai_smart)
2. bluetooth_spp_server.py reads from FIFO
3. bluetooth_spp_server.py transmits via Bluetooth SPP
4. Client device receives NMEA stream
```

### Dashboard Update Flow

```
1. smart_processor.py updates /tmp/gnssai_dashboard_data.json
2. dashboard_server.py polls JSON file (1Hz)
3. dashboard_server.py emits stats via SocketIO
4. Browser receives update and refreshes UI
5. Dashboard displays: position, RTK status, satellites, ML stats, tilt
```

---

## Development Workflows

### Starting the System

**Full Stack (3 processes):**

```bash
# Terminal 1: Smart Processor
python3 smart_processor.py

# Terminal 2: Dashboard Server
python3 dashboard_server.py

# Terminal 3: Bluetooth Server (optional, requires sudo)
sudo python3 bluetooth_spp_server.py
```

**Access:**
- Dashboard: http://localhost:5000
- API: http://localhost:5000/api/stats

### Development Mode

**Testing Without Hardware:**
Use a NMEA simulator or log file:
```bash
# Replay NMEA log to /dev/serial0
cat nmea_log.txt > /dev/serial0

# Or create a virtual serial port pair
socat -d -d pty,raw,echo=0 pty,raw,echo=0
# Use one end as /dev/serial0, write NMEA to the other
```

**Testing Components Individually:**

```bash
# Test ML classifier
python3 ml_classifier.py
# Runs built-in test with sample satellite data

# Test dashboard without processor
# Manually create /tmp/gnssai_dashboard_data.json
echo '{"position":{"lat":40.0,"lon":-105.0,"alt":1600},...}' > /tmp/gnssai_dashboard_data.json
python3 dashboard_server.py
```

### Adding New Features

**Adding New NMEA Sentence Parsers:**

1. Add parser method to `SmartProcessor` class:
```python
def parse_nmea_xxx(self, line: str):
    """Parse XXX sentence."""
    parts = line.split(",")
    # Parse fields
    # Update self.stats or self.position
```

2. Call from `process_nmea_line()`:
```python
def process_nmea_line(self, line: str):
    # ... existing code ...
    if "XXX" in line:
        self.parse_nmea_xxx(line)
```

**Adding New Dashboard Metrics:**

1. Update `update_dashboard_json()` in `smart_processor.py`:
```python
dashboard_data = {
    # ... existing fields ...
    "new_metric": self.calculate_new_metric(),
}
```

2. Update dashboard HTML in `dashboard_server.py` (embedded `DASHBOARD_HTML` string)
3. Add UI elements and update JavaScript `updateUI()` function

**Adding New ML Features:**

1. Add feature extraction in `ml_classifier.py`:
```python
def extract_features(self, satellite_data):
    # ... existing features ...
    new_feature = calculate_new_feature(data)
    feature_vector.append(new_feature)
```

2. Update thresholds and classification rules
3. Retrain model with `gnssai_trainer.py`

---

## Key Conventions

### Code Style

**Python:**
- PEP 8 style guide
- UTF-8 encoding (`# -*- coding: utf-8 -*-`)
- Docstrings for all classes and public methods
- Type hints where helpful (not strictly enforced)
- `snake_case` for functions and variables
- `PascalCase` for class names

**JavaScript:**
- camelCase for variables and functions
- 2-space indentation
- Modern ES6+ syntax
- Const/let (no var)

### Naming Conventions

**Files:**
- Python modules: `snake_case.py`
- Backup files: `_backup.py` or `.backup` suffix
- Static assets: descriptive names with hashes

**Variables:**
- Position data: `lat`, `lon`, `alt` (altitude)
- Signal quality: `snr` (Signal-to-Noise Ratio), `cn0` (Carrier-to-Noise)
- Satellite identifiers: `prn` (Pseudo-Random Noise number)
- GNSS quality: `quality` (0=no fix, 1=GPS, 2=DGPS, 4=RTK_FIXED, 5=RTK_FLOAT)

### File Paths

**Always use absolute paths for:**
- UART: `/dev/serial0`
- FIFO: `/tmp/gnssai_smart`
- JSON: `/tmp/gnssai_dashboard_data.json`
- Templates: `os.path.join(BASE_DIR, "templates")`
- Models: `ml_models/gnssai_classifier.joblib`

**Always use relative paths for:**
- Import statements
- Data directories: `ml_training_data/`, `ml_models/`

### Error Handling

**FIFO Operations:**
```python
try:
    fd = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK)
except OSError as e:
    if e.errno in (errno.ENXIO, errno.ENOENT):
        # Expected: no reader yet
        pass
    else:
        # Unexpected error
        raise
```

**NMEA Parsing:**
```python
try:
    # Parse logic
except (ValueError, IndexError):
    # Silently skip malformed sentences
    pass
```

**ML Operations:**
```python
if self.ml_enabled and self.classifier:
    try:
        result = self.classifier.process_gsv(line)
    except Exception:
        # Don't crash on ML errors
        pass
```

### Logging

**Console Output:**
- Use emoji prefixes for clarity: 🛰️ 📊 ✅ ⚠️ ❌
- Print startup banners with `=` separators
- Print periodic stats (every 30s)
- Use `\r` for inline updates (progress indicators)

**Example:**
```python
print("=" * 60)
print("🛰️  GNSS.AI Smart Processor v3.3")
print("=" * 60)
```

### Configuration

**Hardcoded Defaults:**
- UART port: `/dev/serial0`
- UART baud: `115200`
- FIFO path: `/tmp/gnssai_smart`
- JSON path: `/tmp/gnssai_dashboard_data.json`
- Dashboard port: `5000`
- FIFO mode: `0o666`

**Runtime Configuration:**
- Use JSON files for complex configuration
- Use command-line arguments for simple parameters
- Environment variables not currently used

---

## Configuration

### UART Configuration

Edit `smart_processor.py`:
```python
self.uart_port = "/dev/serial0"  # Change if using different port
self.uart_baud = 115200          # Match module baud rate
```

### ML Configuration

Edit `ml_classifier.py` thresholds:
```python
self.thresholds = {
    'snr_los_min': 35,           # Minimum SNR for LOS
    'snr_nlos_max': 25,          # Maximum SNR for NLOS
    'elevation_los_min': 20,     # Minimum elevation for LOS
    'elevation_nlos_max': 15,    # Maximum elevation for NLOS
    # ...
}
```

### Dashboard Configuration

Edit `dashboard_server.py`:
```python
PORT = 5000                      # Change web server port
JSON_DATA_FILE = "/tmp/gnssai_dashboard_data.json"
```

### Bluetooth Configuration

Edit `bluetooth_spp_server.py`:
```python
SERVER_UUID = "00001101-0000-1000-8000-00805F9B34FB"  # SPP UUID
# Service name in advertise_service():
bluetooth.advertise_service(
    self.server_sock,
    "GNSS-AI",  # Change service name
    ...
)
```

### TILT Sentence Configuration

The TILT parsing in `smart_processor.py` is a **skeleton implementation**. You must customize it for your specific module:

1. Connect to UART and identify TILT sentences:
```bash
sudo cat /dev/serial0 | grep -i 'sti'  # or 'tilt', 'ins', 'attitude'
```

2. Edit `parse_tilt_sentence()` in `smart_processor.py`:
```python
def parse_tilt_sentence(self, line: str):
    # Replace with your module's actual TILT sentence format
    if line.startswith("$PSTI,030"):  # Example
        parts = line.split(",")
        try:
            roll = float(parts[2])
            pitch = float(parts[3])
            heading = float(parts[4])
            # Update self.tilt
        except (ValueError, IndexError):
            return
```

---

## Testing & Debugging

### Unit Testing

**Test ML Classifier:**
```bash
python3 ml_classifier.py
# Expected: classification results for 7 test satellites
```

**Test NMEA Parsing:**
```python
# Add to smart_processor.py:
if __name__ == "__main__":
    proc = SmartProcessor()
    test_gga = "$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47"
    proc.parse_nmea_gga(test_gga)
    print(proc.position)
    print(proc.stats)
```

### Debugging FIFO Issues

**Check FIFO exists:**
```bash
ls -l /tmp/gnssai_smart
# Should show: prw-rw-rw- (pipe)
```

**Test FIFO manually:**
```bash
# Terminal 1: Read from FIFO
cat /tmp/gnssai_smart

# Terminal 2: Write to FIFO
echo "test" > /tmp/gnssai_smart
```

**Common Issues:**
- **ENXIO error**: No reader on FIFO (expected, will retry)
- **EPIPE error**: Reader disconnected (will reopen)
- **Permission denied**: Check FIFO mode (should be 666)

### Debugging Dashboard

**Check JSON file:**
```bash
cat /tmp/gnssai_dashboard_data.json | python3 -m json.tool
# Should be valid JSON
```

**Test API endpoint:**
```bash
curl http://localhost:5000/api/stats | python3 -m json.tool
```

**Browser console:**
- Open DevTools → Console
- Check for WebSocket connection errors
- Verify stats updates in console: `console.log(data)`

### Debugging Bluetooth

**Check Bluetooth status:**
```bash
sudo systemctl status bluetooth
hciconfig hci0 up
hciconfig hci0 piscan  # Make discoverable
```

**Test SPP server:**
```bash
# On phone/client: Scan for "GNSS-AI" service
# Connect and check if NMEA data appears
```

**Common Issues:**
- **No Bluetooth adapter**: Check `hciconfig`
- **Permission denied**: Run with `sudo`
- **pybluez not installed**: `pip3 install pybluez`

### Viewing Logs

**Smart Processor:**
- Prints stats every 30 seconds
- Shows NMEA_out count, satellites, quality, HDOP, ML stats

**Dashboard Server:**
- Shows client connections: `🔗 Cliente conectado a /gnss`
- Shows client disconnections: `🔌 Cliente desconectado de /gnss`

**Bluetooth Server:**
- Shows connections: `✅ Connected from [MAC_ADDRESS]`
- Shows disconnections: `❌ Client disconnected`

---

## Common Tasks

### Collect Training Data

```bash
# 10 minutes in urban canyon
python3 gnssai_collector.py 600 urban

# 30 minutes in open sky
python3 gnssai_collector.py 1800 open_sky

# 1 hour near buildings (multipath)
python3 gnssai_collector.py 3600 multipath
```

### Train ML Model

```bash
# Train from all collected sessions
python3 gnssai_trainer.py

# Check output
ls -lh ml_models/
# Should see: gnssai_classifier.joblib, model_metadata.json
```

### Export Dashboard Data

```bash
# Capture current snapshot
curl http://localhost:5000/api/stats > snapshot.json

# Continuous logging
while true; do
    curl -s http://localhost:5000/api/stats >> gnss_log.jsonl
    sleep 1
done
```

### Monitor NMEA Stream

```bash
# View raw UART data
sudo cat /dev/serial0

# View processed FIFO data
cat /tmp/gnssai_smart

# Filter specific sentences
cat /tmp/gnssai_smart | grep GGA
cat /tmp/gnssai_smart | grep GSV
```

### Backup Configuration

```bash
# Backup Python modules
cp smart_processor.py smart_processor_backup.py

# Backup ML models
tar -czf ml_models_backup.tar.gz ml_models/

# Backup training data
tar -czf ml_data_backup.tar.gz ml_training_data/
```

### Update Dashboard UI

1. Edit embedded HTML in `dashboard_server.py`
2. Find `DASHBOARD_HTML = """<!DOCTYPE html>...`
3. Modify HTML/CSS/JavaScript
4. Restart dashboard server
5. Refresh browser (Ctrl+Shift+R for hard refresh)

### Change NMEA Baud Rate

**On K922 Module:**
```
# Use configuration tool to set baud rate
# Or send ComNav/SinoGNSS command (see manual)
```

**In Code:**
```python
# smart_processor.py
self.uart_baud = 230400  # Change from 115200
```

---

## Troubleshooting

### No NMEA Data Received

**Check UART:**
```bash
ls -l /dev/serial0
# Should exist and be accessible

sudo cat /dev/serial0
# Should show NMEA sentences
```

**Check Module Power:**
- Verify module has power
- Check antenna is connected
- Wait for module to initialize (can take 30-60s)

**Check Baud Rate:**
- Default is often 115200
- Module may be configured differently
- Try common rates: 9600, 38400, 115200, 230400

### Dashboard Shows No Data

**Check smart_processor is running:**
```bash
ps aux | grep smart_processor
```

**Check JSON file exists and updates:**
```bash
watch -n 1 "ls -lh /tmp/gnssai_dashboard_data.json"
# Timestamp should update every ~1s
```

**Check JSON content:**
```bash
cat /tmp/gnssai_dashboard_data.json | python3 -m json.tool
```

**Check dashboard server is running:**
```bash
ps aux | grep dashboard_server
curl http://localhost:5000
```

### Bluetooth Not Connecting

**Check service is running:**
```bash
ps aux | grep bluetooth_spp_server
```

**Check Bluetooth is enabled:**
```bash
sudo systemctl status bluetooth
sudo hciconfig hci0 up
sudo hciconfig hci0 piscan
```

**Check FIFO has data:**
```bash
cat /tmp/gnssai_smart
# Should show NMEA sentences
```

**Restart Bluetooth stack:**
```bash
sudo systemctl restart bluetooth
sudo python3 bluetooth_spp_server.py
```

### ML Classifier Not Working

**Check numpy is installed:**
```bash
python3 -c "import numpy; print(numpy.__version__)"
```

**Check classifier initialization:**
- Look for: `🧠 Inicializando clasificador ML...`
- Look for: `✅ ML listo.`
- If not found: `⚠️ ML Classifier no disponible, continuaré sin ML.`

**Test classifier standalone:**
```bash
python3 ml_classifier.py
# Should output classification results
```

### High CPU Usage

**Expected:**
- `smart_processor.py`: 1-5% (depends on NMEA rate)
- `dashboard_server.py`: <1%
- `bluetooth_spp_server.py`: <1%

**If higher:**
- Check NMEA output rate from module
- Reduce dashboard poll rate
- Disable ML classifier temporarily
- Check for infinite loops in custom code

### Memory Leaks

**Monitor memory:**
```bash
while true; do
    ps aux | grep -E 'smart_processor|dashboard_server|bluetooth_spp'
    sleep 60
done
```

**If memory grows:**
- Check satellite history (`self.satellites_detail`) - should auto-prune stale entries
- Check ML history (`self.signal_history`, `self.classification_history`) - uses `deque` with maxlen
- Restart processes periodically via systemd or cron

### FIFO Blocking Issues

**Symptoms:**
- `smart_processor.py` hangs
- No NMEA output

**Solution:**
- Always use `O_NONBLOCK` flag
- Check `_open_fifo_for_write()` handles `ENXIO` correctly
- Ensure Bluetooth server starts before or after processor (order doesn't matter)

**Test:**
```bash
# Start processor without Bluetooth server
python3 smart_processor.py
# Should print: "FIFO sin lector todavía (ENXIO)"
# Should continue running

# Start Bluetooth server
sudo python3 bluetooth_spp_server.py
# Processor should detect reader: "FIFO ahora abierto para escritura"
```

---

## Additional Notes

### TILT Implementation Status

The TILT (pitch/roll/heading) support is currently a **skeleton implementation**. To fully implement:

1. **Identify TILT sentence format**:
   - Connect module and capture TILT sentences
   - Check module documentation for INS/ATTITUDE message format
   - Common formats: `$PSTI,030,...`, `$PTNL,VHD,...`, proprietary binary

2. **Implement parser**:
   - Update `parse_tilt_sentence()` in `smart_processor.py`
   - Extract pitch, roll, heading, and status flags
   - Calculate total tilt angle: `sqrt(pitch² + roll²)`

3. **Calibration**:
   - Some modules require tilt calibration (360° rotation while vertical)
   - Implement calibration status detection
   - Update `tilt['status']` field: "OK", "CALIBRATING", "NONE"

4. **Dashboard visualization**:
   - Dashboard already has tilt visualization
   - Adjust thresholds if needed (currently ±30° max)

### ML Model Deployment

**Current State:**
- Rule-based classification active
- ML classifier placeholder ready
- Training pipeline functional

**To Deploy ML Model:**
1. Collect diverse training data (urban, open sky, forest, buildings)
2. Run `gnssai_trainer.py` to train RandomForest
3. Update `ml_classifier.py` to load trained model:
```python
def __init__(self, model_type="hybrid"):
    self.model = joblib.load('ml_models/gnssai_classifier.joblib')
```
4. Implement `classify_with_ml()` to use loaded model
5. Test thoroughly before production deployment

### Production Deployment

**Recommended Setup:**

1. **Systemd Services:**
```ini
# /etc/systemd/system/gnssai-processor.service
[Unit]
Description=GNSS.AI Smart Processor
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/gnssai/smart_processor.py
Restart=always
User=pi
WorkingDirectory=/home/pi/gnssai

[Install]
WantedBy=multi-user.target
```

2. **Auto-start on Boot:**
```bash
sudo systemctl enable gnssai-processor
sudo systemctl enable gnssai-dashboard
sudo systemctl enable gnssai-bluetooth
```

3. **Logging:**
```bash
# Journal logs
sudo journalctl -u gnssai-processor -f

# Or redirect to file
ExecStart=/usr/bin/python3 /home/pi/gnssai/smart_processor.py >> /var/log/gnssai.log 2>&1
```

4. **Monitoring:**
- Use systemd watchdog
- Implement health check endpoint in dashboard
- Monitor NMEA data rate
- Alert on RTK fix loss

### Security Considerations

**Current State:**
- Dashboard runs on all interfaces (`0.0.0.0:5000`)
- No authentication on dashboard
- Bluetooth SPP has no pairing enforcement
- No HTTPS

**For Production:**
- Bind dashboard to `127.0.0.1` or use firewall
- Add authentication (basic auth, JWT, etc.)
- Use HTTPS (nginx reverse proxy)
- Enforce Bluetooth pairing
- Validate all NMEA input (checksum already validated)
- Sanitize dashboard JSON output

### Performance Optimization

**Current Performance:**
- NMEA processing: ~1000 sentences/second capable
- Dashboard update: 1 Hz (configurable)
- Bluetooth throughput: ~1 Mbps typical
- ML classification: <1ms per satellite

**Optimization Tips:**
- Reduce dashboard update rate if needed
- Use binary NMEA (UBX, proprietary) instead of ASCII
- Batch JSON writes (currently every 20 sentences)
- Profile with `cProfile` if needed
- Consider Cython for hot paths (unlikely needed)

---

## Contact & Contributing

This is a specialized GNSS/RTK positioning system. When modifying:

1. **Test thoroughly** - GNSS systems are safety-critical
2. **Document changes** - Update this file
3. **Backup before changes** - Use `_backup.py` suffix
4. **Version modules** - Update version strings in headers
5. **Validate NMEA** - Always check checksums
6. **Handle errors gracefully** - System should never crash

---

**End of CLAUDE.md**
