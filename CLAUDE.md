# CLAUDE.md - GNSS.AI Project Documentation

**Last Updated**: 2025-11-19
**Project**: GNSS.AI - Advanced GNSS/RTK Processing System with ML Signal Classification
**Target Hardware**: SinoGNSS K222/K902/K922 GNSS Modules with RTK & IMU/INS capabilities

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Codebase Structure](#codebase-structure)
4. [Key Components](#key-components)
5. [Data Flow](#data-flow)
6. [Technology Stack](#technology-stack)
7. [Development Workflows](#development-workflows)
8. [Hardware Integration](#hardware-integration)
9. [API & Communication](#api--communication)
10. [Key Conventions](#key-conventions)
11. [Common Development Tasks](#common-development-tasks)
12. [Testing & Debugging](#testing--debugging)

---

## Project Overview

**GNSS.AI** is a sophisticated GNSS (Global Navigation Satellite System) processing system designed for high-precision RTK (Real-Time Kinematic) positioning with integrated machine learning signal classification. The system processes NMEA data from professional GNSS modules, applies ML-based signal quality assessment, and provides real-time monitoring through a web dashboard.

### Core Features

- **Real-time NMEA Processing**: Parses GGA, GSV, and other NMEA sentences from UART
- **ML Signal Classification**: Classifies satellite signals as LOS (Line of Sight), NLOS (Non-Line of Sight), or Multipath
- **RTK Support**: Handles RTK FIXED, RTK FLOAT, DGPS, and standalone GPS modes
- **IMU/INS Integration**: Framework for tilt compensation (K222/K922 modules)
- **Bluetooth SPP Server**: Transmits processed GNSS data via Bluetooth Serial Port Profile
- **Web Dashboard**: Real-time visualization with Socket.IO updates
- **Configuration Panel**: Web-based UI for K922 module configuration
- **Data Collection**: Training data collection for ML model improvement

### Target Use Cases

- Surveying and mapping with RTK precision
- Agricultural automation requiring cm-level accuracy
- Autonomous vehicle navigation
- Research and development for GNSS signal analysis
- Educational projects for GNSS/RTK technology

---

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         HARDWARE LAYER                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  K222/K902/K922 GNSS Module (UART /dev/serial0)          │  │
│  │  - GPS, GLONASS, Galileo, BeiDou, QZSS                   │  │
│  │  - RTK: FIXED/FLOAT (cm-level precision)                 │  │
│  │  - IMU/INS (pitch, roll, heading) on K222/K922           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               ↓ NMEA (115200 baud)
┌─────────────────────────────────────────────────────────────────┐
│                      PROCESSING LAYER                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  smart_processor.py (Core Engine)                         │  │
│  │  - UART reader (/dev/serial0)                            │  │
│  │  - NMEA parser (GGA, GSV, GSA, RMC, etc.)               │  │
│  │  - Position extraction (lat/lon/alt)                     │  │
│  │  - Satellite tracking & metrics                          │  │
│  │  - TILT processing (pitch/roll/heading)                  │  │
│  │  - ML signal classification (optional)                   │  │
│  │  - FIFO writer → /tmp/gnssai_smart                       │  │
│  │  - JSON writer → /tmp/gnssai_dashboard_data.json         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ml_classifier.py (Signal Classification)                │  │
│  │  - Feature extraction (elevation, SNR, azimuth, trends)  │  │
│  │  - Rule-based classification                             │  │
│  │  - ML model support (sklearn RandomForest)               │  │
│  │  - Signal history & confidence scoring                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               ↓ Data Output
┌─────────────────────────────────────────────────────────────────┐
│                      OUTPUT LAYER                               │
│  ┌────────────────────────┐  ┌────────────────────────────┐    │
│  │ bluetooth_spp_server.py│  │  dashboard_server.py       │    │
│  │ - Reads FIFO           │  │  - Flask web server        │    │
│  │ - Bluetooth RFCOMM     │  │  - Socket.IO real-time     │    │
│  │ - SPP UUID: 00001101   │  │  - REST API: /api/stats    │    │
│  │ - Clients: SW Maps,etc │  │  - HTML dashboard UI       │    │
│  └────────────────────────┘  └────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENT LAYER                               │
│  - Mobile apps (Bluetooth SPP)                                  │
│  - Web browsers (HTTP/WebSocket)                                │
│  - Configuration panel (WebSocket)                              │
└─────────────────────────────────────────────────────────────────┘
```

### Component Interaction

1. **GNSS Module** → UART serial → **smart_processor.py**
2. **smart_processor.py** → FIFO → **bluetooth_spp_server.py** → Bluetooth clients
3. **smart_processor.py** → JSON file → **dashboard_server.py** → Web clients
4. **smart_processor.py** ↔ **ml_classifier.py** (optional ML processing)
5. **Configuration Panel** → WebSocket → Backend (future implementation)

---

## Codebase Structure

```
tareas/
├── CLAUDE.md                          # This file - AI assistant documentation
│
├── Core Python Modules
│   ├── smart_processor.py             # Main NMEA processing engine (18.9 KB)
│   ├── smart_processor_backup.py      # Backup version (10.3 KB)
│   ├── smart_processor.py.backup      # Minimal backup (876 B)
│   ├── ml_classifier.py               # ML signal classification (16.4 KB)
│   ├── bluetooth_spp_server.py        # Bluetooth SPP server (3.7 KB)
│   ├── dashboard_server.py            # Web dashboard server (25.8 KB)
│   ├── gnssai_collector.py            # ML training data collector (5.8 KB)
│   └── gnssai_trainer.py              # ML model trainer (5.3 KB)
│
├── Web Interface
│   ├── index.guia.html                # K922 configuration panel (10.5 KB)
│   ├── app.js                         # Panel JavaScript logic (13.1 KB)
│   ├── styles.css                     # Panel styles (6.7 KB)
│   └── static/                        # Frontend assets (CSS/JS compiled)
│       ├── staticcsschunk-vendors.d93e9d9a.css.txt
│       ├── staticcssindex.8349ed33.css.txt
│       ├── staticjschunk-common.22a6f926.js.txt
│       ├── staticjschunk-vendors.31517009.js.txt
│       └── staticjsindex.0bca27f0.js.txt
│
├── Documentation (PDFs)
│   ├── SinoGNSS_K922_GNSS_Module_Specification_v1.4.pdf  (827 KB)
│   ├── ComNav OEM Board Reference Manual_V1.8 (1).pdf    (2.7 MB)
│   ├── ComNav OEM Board Reference Manual_V1.8 (1).docx   (9.2 MB)
│   └── 华圳物联（K922）规格书V1.0.pdf                       (2.0 MB)
│
├── Metadata
│   ├── ARE                            # Project marker file
│   ├── APP FUNCIONA                   # Status marker file
│   └── shh                            # Empty placeholder
│
└── Version Control
    └── .git/                          # Git repository
```

### File Categories

- **Core Processing**: `smart_processor.py`, `ml_classifier.py`
- **Network Services**: `bluetooth_spp_server.py`, `dashboard_server.py`
- **ML Pipeline**: `gnssai_collector.py`, `gnssai_trainer.py`, `ml_classifier.py`
- **Configuration UI**: `index.guia.html`, `app.js`, `styles.css`
- **Documentation**: PDF specs for K922/K902/K222 modules

---

## Key Components

### 1. smart_processor.py (Main Processing Engine)

**Purpose**: Core GNSS data processor that reads UART, parses NMEA, applies ML classification, and outputs to FIFO/JSON.

**Key Classes**:
- `SmartProcessor`: Main processor class

**Key Methods**:
- `connect_uart()`: Opens `/dev/serial0` at 115200 baud
- `parse_nmea_gga()`: Extracts position (lat/lon/alt), quality, satellites, HDOP
- `parse_nmea_gsv()`: Extracts satellite details (PRN, elevation, azimuth, SNR)
- `parse_tilt_sentence()`: Placeholder for IMU/INS data (K222/K922)
- `write_output()`: Writes to FIFO for Bluetooth transmission
- `update_dashboard_json()`: Generates `/tmp/gnssai_dashboard_data.json`
- `get_satellite_snapshot()`: Provides current satellite view with classifications

**Important Features**:
- FIFO handling with non-blocking I/O and ENXIO recovery
- Checksum validation for NMEA sentences
- ML integration (optional, graceful degradation)
- RTK quality mapping: 4=FIXED, 5=FLOAT, 2=DGPS, 1=GPS, 0=NO_FIX
- 30-second status logging
- Signal handler for clean shutdown (SIGINT/SIGTERM)

**Configuration**:
```python
self.uart_port = "/dev/serial0"      # UART device
self.uart_baud = 115200              # Baud rate
self.fifo_path = "/tmp/gnssai_smart" # Bluetooth FIFO
self.json_path = "/tmp/gnssai_dashboard_data.json"  # Dashboard data
```

**TILT Integration Note**:
The TILT parsing is currently a skeleton. To enable:
1. Run `sudo cat /dev/serial0 | grep -i 'sti'` on Raspberry Pi
2. Identify the actual TILT sentence format (e.g., `$PSTI,030,roll,pitch,heading`)
3. Update `parse_tilt_sentence()` method accordingly

### 2. ml_classifier.py (ML Signal Classification)

**Purpose**: Classifies GNSS satellite signals to identify signal quality issues.

**Key Classes**:
- `SignalClassifier`: Main ML classifier

**Classification Types**:
- **LOS (Line of Sight)**: Clean, direct signal (SNR ≥35, elevation ≥20°)
- **NLOS (Non-Line of Sight)**: Obstructed signal (SNR <25, elevation <15°)
- **Multipath**: Signal with reflections (SNR 25-35, elevation ≥10°)

**Key Methods**:
- `extract_features()`: Creates feature vectors from satellite data
- `classify_by_rules()`: Rule-based classification (current implementation)
- `classify_with_ml()`: ML model classification (placeholder for sklearn models)
- `classify_signals()`: Main classification entry point
- `get_stats()`: Returns classification statistics

**Features Extracted**:
1. Elevation (degrees)
2. SNR (Signal-to-Noise Ratio, dBHz)
3. Azimuth (degrees)
4. Time of day
5. SNR quality (normalized 0-1)
6. Elevation quality (normalized 0-1)
7. SNR trend (historical)
8. Elevation trend (historical)

**Thresholds** (configurable):
```python
'snr_los_min': 35              # Minimum SNR for LOS
'snr_nlos_max': 25             # Maximum SNR for NLOS
'elevation_los_min': 20        # Minimum elevation for LOS
'elevation_nlos_max': 15       # Maximum elevation for NLOS
```

**Statistics Tracked**:
- Total classifications
- LOS/NLOS/Multipath counts
- Average confidence scores

### 3. bluetooth_spp_server.py (Bluetooth Output)

**Purpose**: Reads NMEA data from FIFO and transmits via Bluetooth SPP to mobile devices.

**Key Classes**:
- `BluetoothSPPServer`: Bluetooth RFCOMM server

**Protocol**:
- Service UUID: `00001101-0000-1000-8000-00805F9B34FB` (SPP standard)
- Service Name: `GNSS-AI`
- Profile: Serial Port Profile

**Operation Flow**:
1. Wait for `/tmp/gnssai_smart` FIFO to exist
2. Advertise Bluetooth service
3. Accept client connections
4. Read from FIFO with 0.1s timeout (non-blocking)
5. Transmit data to connected Bluetooth client
6. Handle disconnections and reconnections gracefully

**Dependencies**: `pybluez` library

### 4. dashboard_server.py (Web Dashboard)

**Purpose**: Flask-based web server providing real-time GNSS dashboard with Socket.IO updates.

**Key Features**:
- REST API endpoint: `GET /api/stats` (JSON data)
- WebSocket namespace: `/gnss` (real-time updates)
- HTML dashboard with responsive UI
- Auto-refresh every 1 second
- Embedded HTML template (no external dependencies)

**Dashboard Displays**:
- Position: Latitude, Longitude, Altitude
- RTK Status: FIXED/FLOAT/DGPS/GPS/NO_FIX with color coding
- Satellites: Count, HDOP
- ML Classifications: LOS/Multipath/NLOS counts, confidence
- TILT: Pitch, Roll, Heading, Angle with visual representation
- Counters: NMEA sent, RTCM sent, format switches, ML corrections
- Uptime tracker

**Visual Features**:
- Dark theme optimized for field use
- 3D tilt visualization with animated antenna
- Real-time status badges
- Responsive grid layout (mobile-friendly)

**Data Source**: Reads `/tmp/gnssai_dashboard_data.json` every 1 second

**Server Configuration**:
- Host: `0.0.0.0` (all interfaces)
- Port: `5000`
- Templates: Generated dynamically from embedded HTML

### 5. gnssai_collector.py (ML Data Collection)

**Purpose**: Collects training data from GNSS module for ML model training.

**Key Classes**:
- `SimpleGNSSCollector`: Data collection utility

**Output Format**: CSV with columns:
- timestamp, prn, constellation, elevation, azimuth, snr, quality, hdop, environment

**Usage**:
```bash
python3 gnssai_collector.py [duration_seconds] [environment]
# Example: python3 gnssai_collector.py 300 urban
```

**Environment Labels**:
- `urban`: City with buildings (multipath/NLOS expected)
- `open`: Open sky (LOS expected)
- `forest`: Tree canopy (NLOS expected)
- `indoor`: Indoor/tunnel (severe NLOS)

**Collection Strategy**:
- Saves epochs every 5 seconds
- Tracks all visible satellites from GSV messages
- Records quality and HDOP from GGA messages
- Creates session files: `session_YYYYMMDD_HHMMSS.csv`

### 6. gnssai_trainer.py (ML Model Training)

**Purpose**: Trains Random Forest classifier on collected GNSS data.

**Key Classes**:
- `GNSSMLTrainer`: Model training pipeline

**Pipeline Steps**:
1. `load_data()`: Combines all session CSV files
2. `label_data()`: Auto-labels based on SNR/elevation rules
3. `prepare_features()`: Creates feature matrix
4. `train()`: Trains RandomForestClassifier (100 trees)
5. `save_model()`: Saves to `ml_models/gnssai_classifier.joblib`

**Model Details**:
- Algorithm: Random Forest (sklearn)
- Features: elevation, snr, hdop
- Train/test split: 80/20 with stratification
- Outputs: Classification report, feature importance

**Output Files**:
- `ml_models/gnssai_classifier.joblib`: Trained model
- `ml_models/model_metadata.json`: Training metadata

### 7. Configuration Panel (app.js + index.guia.html)

**Purpose**: Web-based UI for configuring K922 GNSS module settings.

**Key Features**:
- WebSocket connection to backend
- Tab-based navigation: Status, Connection, GNSS, NMEA, IMU, Config
- JSON export/import for configuration profiles
- Real-time status updates

**Configuration Sections**:

1. **Connection**: Serial/TCP transport, baudrate selection
2. **GNSS**: Constellation selection, RTK mode, correction input
3. **NMEA**: Talker ID, rate, message selection
4. **IMU/INS**: Enable/disable, rate, fusion priority
5. **RTCM**: Base station messages for corrections

**WebSocket Protocol**:
```javascript
// Messages sent to backend
{ type: "getK922Status" }
{ type: "applyK922Config", payload: {...} }

// Messages from backend
{ type: "k922Status", payload: {...} }
```

**Note**: Backend WebSocket server not yet implemented. Panel generates JSON for manual backend integration.

---

## Data Flow

### Main Processing Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. UART INPUT                                                   │
│    /dev/serial0 (115200 baud)                                   │
│    ↓                                                             │
│    NMEA sentences: $GPGGA, $GPGSV, $GLGSV, $GAGSV, etc.        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. PARSING (smart_processor.py)                                 │
│    • Checksum validation                                        │
│    • GGA → position, quality, satellites, HDOP                  │
│    • GSV → satellite details (PRN, elev, azim, SNR)            │
│    • TILT → pitch, roll, heading (if available)                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. ML CLASSIFICATION (ml_classifier.py) [OPTIONAL]              │
│    • Extract features: elevation, SNR, azimuth, trends          │
│    • Classify: LOS / NLOS / Multipath                           │
│    • Calculate confidence scores                                │
│    • Update statistics                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. OUTPUT GENERATION                                            │
│    A. FIFO: /tmp/gnssai_smart                                   │
│       • Raw/processed NMEA sentences                            │
│       • Non-blocking write with ENXIO handling                  │
│    B. JSON: /tmp/gnssai_dashboard_data.json                     │
│       • Position, satellites, quality, ML stats, tilt           │
│       • Updated every 20 NMEA sentences                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. DISTRIBUTION                                                 │
│    A. Bluetooth (bluetooth_spp_server.py)                       │
│       • Reads from FIFO                                         │
│       • Transmits to SPP clients (SW Maps, etc.)                │
│    B. Web Dashboard (dashboard_server.py)                       │
│       • Reads JSON file                                         │
│       • Serves via HTTP + Socket.IO                             │
│       • Real-time browser updates (1Hz)                         │
└─────────────────────────────────────────────────────────────────┘
```

### Inter-Process Communication

1. **FIFO (Named Pipe)**:
   - Path: `/tmp/gnssai_smart`
   - Writer: `smart_processor.py`
   - Reader: `bluetooth_spp_server.py`
   - Mode: Non-blocking, auto-reconnect on ENXIO

2. **JSON File**:
   - Path: `/tmp/gnssai_dashboard_data.json`
   - Writer: `smart_processor.py` (every 20 sentences)
   - Reader: `dashboard_server.py` (every 1 second)
   - Format: Complete state snapshot

3. **WebSocket (Future)**:
   - Configuration panel → Backend server
   - Protocol: JSON messages with `type` field

---

## Technology Stack

### Languages
- **Python 3**: Core processing, ML, servers (Python 3.7+)
- **JavaScript**: Web UI, configuration panel (ES6+)
- **HTML5/CSS3**: Dashboard and configuration interfaces

### Python Libraries

**Core Dependencies**:
```
pyserial       # UART communication
pybluez        # Bluetooth SPP server
flask          # Web server
flask-socketio # Real-time WebSocket
```

**ML Dependencies** (optional):
```
numpy          # Numerical operations
pandas         # Data handling (trainer)
scikit-learn   # ML models (trainer)
joblib         # Model serialization (trainer)
```

**System Integration**:
- `signal`: Clean shutdown handling
- `os`, `errno`: FIFO and file operations
- `threading`: Background tasks (dashboard)
- `select`: Non-blocking FIFO reads

### Web Technologies
- **Flask**: Lightweight WSGI web framework
- **Socket.IO**: Bidirectional real-time communication
- **Vanilla JavaScript**: No framework dependencies for config panel
- **CSS Grid/Flexbox**: Responsive layouts

### Hardware Interfaces
- **UART Serial**: 115200 baud, 8N1
- **Bluetooth RFCOMM**: SPP profile (UUID: 00001101)

### Development Tools
- **Git**: Version control
- **systemd** (recommended): Service management for production

---

## Development Workflows

### Setting Up Development Environment

1. **Clone Repository**:
```bash
git clone <repository-url>
cd tareas
```

2. **Install Python Dependencies**:
```bash
# Core dependencies
pip3 install pyserial pybluez flask flask-socketio

# Optional ML dependencies
pip3 install numpy pandas scikit-learn joblib
```

3. **Verify UART Access**:
```bash
# Check UART device
ls -l /dev/serial0

# Test raw NMEA output
sudo cat /dev/serial0

# Add user to dialout group (if needed)
sudo usermod -a -G dialout $USER
```

4. **Enable Bluetooth** (if using SPP server):
```bash
sudo systemctl start bluetooth
sudo systemctl enable bluetooth

# Make device discoverable
sudo bluetoothctl
> power on
> discoverable on
```

### Running the System

**Option 1: Manual Start (Development)**

```bash
# Terminal 1: Start main processor
python3 smart_processor.py

# Terminal 2: Start Bluetooth server
python3 bluetooth_spp_server.py

# Terminal 3: Start web dashboard
python3 dashboard_server.py
```

**Option 2: Production with systemd**

Create service files in `/etc/systemd/system/`:

```ini
# gnssai-processor.service
[Unit]
Description=GNSS.AI Smart Processor
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/tareas
ExecStart=/usr/bin/python3 /home/pi/tareas/smart_processor.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable gnssai-processor.service
sudo systemctl start gnssai-processor.service
sudo systemctl status gnssai-processor.service
```

### ML Workflow

**1. Collect Training Data**:
```bash
# Collect 5 minutes of data in urban environment
python3 gnssai_collector.py 300 urban

# Collect in different environments
python3 gnssai_collector.py 600 open_sky
python3 gnssai_collector.py 300 forest
```

**2. Train Model**:
```bash
# Train on collected data
python3 gnssai_trainer.py

# Output: ml_models/gnssai_classifier.joblib
```

**3. Deploy Model**:
- Model loading is automatic in `ml_classifier.py`
- If trained model exists, it can be integrated into classification pipeline

**4. Evaluate Performance**:
- Check classification reports from trainer output
- Monitor dashboard ML statistics during operation
- Adjust thresholds in `ml_classifier.py` if needed

### Configuration Workflow

**Using the Configuration Panel**:

1. Open `index.guia.html` in browser
2. Connect to WebSocket backend (when implemented)
3. Modify settings in UI tabs
4. Export configuration as JSON
5. Apply configuration to module

**Manual Configuration** (current method):

1. Generate JSON from panel
2. Translate JSON to K922 AT commands manually
3. Send commands via UART or web interface

### Version Control

**Branch Strategy** (recommended):
- `main`: Stable production code
- `develop`: Integration branch
- `feature/*`: New features
- `bugfix/*`: Bug fixes

**Current Branch**:
```bash
git branch
# * claude/claude-md-mi67snote97rjpmm-01Wd1zLL1Tuk7eysVbqxNXQC
```

**Commit Practices**:
- Use descriptive commit messages
- Reference issues/PRs when applicable
- Keep commits atomic and focused

---

## Hardware Integration

### Supported GNSS Modules

1. **SinoGNSS K922** (Primary target)
   - Multi-constellation: GPS, GLONASS, Galileo, BeiDou, QZSS
   - RTK: FIXED/FLOAT support
   - IMU/INS: Pitch, roll, heading
   - UART: 115200 baud default
   - Documentation: `SinoGNSS_K922_GNSS_Module_Specification_v1.4.pdf`

2. **SinoGNSS K222**
   - Similar to K922 with IMU support
   - TILT compensation for pole/rover applications

3. **ComNav K902** (Compatible)
   - OEM board version
   - Documentation: `ComNav OEM Board Reference Manual_V1.8 (1).pdf`

### UART Configuration

**Raspberry Pi** (typical setup):
- Device: `/dev/serial0` (GPIO 14/15)
- Baudrate: 115200 bps
- Format: 8N1 (8 data bits, no parity, 1 stop bit)

**Wiring**:
```
GNSS Module          Raspberry Pi
-----------          ------------
GNSS_TXD1 (TX) ----> GPIO 15 (RXD)
GNSS_RXD1 (RX) <---- GPIO 14 (TXD)
GND            ----> GND
VCC            ----> 3.3V or 5V (check module spec)
```

**Enable Serial on Raspberry Pi**:
```bash
sudo raspi-config
# Interface Options > Serial Port
# Login shell: No
# Serial hardware: Yes

# Edit /boot/config.txt
echo "enable_uart=1" | sudo tee -a /boot/config.txt

# Reboot
sudo reboot
```

### NMEA Sentence Reference

**Parsed Sentences**:

- **GGA**: Position fix data
  - Fields: time, lat, lon, quality, satellites, HDOP, altitude
  - Quality values: 0=invalid, 1=GPS, 2=DGPS, 4=RTK_FIXED, 5=RTK_FLOAT

- **GSV**: Satellites in view
  - Fields: PRN, elevation, azimuth, SNR (C/N0)
  - Provides data for ML classification

- **GSA**: DOP and active satellites (future)
- **RMC**: Recommended minimum (future)
- **VTG**: Velocity/track (future)

**TILT Sentences** (module-specific):
- **K922/K222**: Proprietary sentences (e.g., `$PSTI,030,...`)
- **Format**: To be determined from actual module output
- **Data**: Pitch, roll, heading, tilt angle, status flags

### RTK Configuration

**Correction Input**:
- Format: RTCM3 (messages 1004, 1005, 1006, 1074, 1084, 1094, 1124)
- Delivery: UART, TCP/NTRIP client, or radio modem
- Base station: Must be within 10-30 km for optimal RTK

**Expected Performance**:
- RTK FIXED: 1-2 cm horizontal, 2-3 cm vertical
- RTK FLOAT: 10-30 cm horizontal
- DGPS: 30-100 cm
- Standalone: 2-5 m

---

## API & Communication

### REST API (dashboard_server.py)

**Base URL**: `http://localhost:5000`

#### GET /api/stats

Returns current GNSS system status.

**Response** (JSON):
```json
{
  "position": {
    "lat": 40.7128,
    "lon": -74.0060,
    "alt": 10.5
  },
  "satellites": 18,
  "satellites_detail": [...],
  "quality": 4,
  "hdop": 0.8,
  "nmea_sent": 1234,
  "rtcm_sent": 56,
  "ml_corrections": 23,
  "format_switches": 2,
  "los_sats": 12,
  "multipath_sats": 4,
  "nlos_sats": 2,
  "avg_confidence": 85.3,
  "estimated_accuracy": 2.0,
  "rtk_status": "RTK_FIXED",
  "format": "NMEA",
  "last_update": 1700000000.123,
  "uptime_sec": 3600,
  "tilt": {
    "pitch": 1.2,
    "roll": -0.5,
    "heading": 87.3,
    "angle": 1.3,
    "status": "VALID"
  }
}
```

### WebSocket API (dashboard_server.py)

**Namespace**: `/gnss`

**Events**:
- `connect`: Client connected
- `disconnect`: Client disconnected
- `stats`: Emitted every 1 second with same data as `/api/stats`

**Example Client**:
```javascript
const socket = io('http://localhost:5000/gnss');
socket.on('stats', (data) => {
  console.log('Position:', data.position);
  console.log('RTK Status:', data.rtk_status);
});
```

### FIFO Protocol

**Path**: `/tmp/gnssai_smart`

**Format**: Raw NMEA sentences, one per line, terminated with `\r\n`

**Access Pattern**:
- Writer: Single writer (smart_processor.py)
- Reader: Single reader (bluetooth_spp_server.py)
- Blocking behavior: Non-blocking writes, blocking reads with timeout

**ENXIO Handling**: Writer handles ENXIO (no reader) gracefully and reconnects.

### Bluetooth SPP

**Service Info**:
- Name: `GNSS-AI`
- UUID: `00001101-0000-1000-8000-00805F9B34FB`
- Profile: Serial Port Profile (SPP)

**Data Format**: NMEA sentences (same as FIFO)

**Compatible Apps**:
- SW Maps (surveying)
- Mobile Topographer
- Lefebure NTRIP Client
- Generic Bluetooth terminal apps

### Configuration WebSocket (Future)

**URL**: `ws://localhost:8090` (planned)

**Message Types**:
```javascript
// Client → Server
{ type: "getK922Status" }
{ type: "applyK922Config", payload: {...} }

// Server → Client
{ type: "k922Status", payload: {...} }
{ type: "configApplied", success: true, message: "..." }
```

---

## Key Conventions

### Python Code Style

**PEP 8 Compliance**:
- 4 spaces for indentation (no tabs)
- Max line length: ~80-100 characters (flexible for readability)
- Module docstrings: Triple-quoted at top
- Function docstrings: Describe purpose, args, returns

**Naming Conventions**:
- Classes: `PascalCase` (e.g., `SmartProcessor`, `SignalClassifier`)
- Functions/methods: `snake_case` (e.g., `parse_nmea_gga`, `update_stats`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `FIFO_PATH`, `SERVER_UUID`)
- Private methods: Prefix with `_` (e.g., `_open_fifo_for_write`)

**Error Handling**:
- Use try-except for I/O operations
- Graceful degradation (e.g., ML optional, FIFO reconnect)
- Log errors with emoji indicators: ❌ (error), ⚠️ (warning), ✅ (success)

**Logging Style**:
```python
print("🛰️  GNSS.AI Smart Processor v3.3")
print("✅ UART opened")
print("⚠️  ML Classifier not available, continuing without ML")
print("❌ Error opening FIFO: {e}")
```

### JavaScript Code Style

**ES6+ Features**:
- Use `const` and `let` (no `var`)
- Arrow functions for callbacks
- Template literals for strings

**Function Conventions**:
- camelCase for functions (e.g., `connectBackend`, `updateStatusFromBackend`)
- Async operations with callbacks or promises

**Error Handling**:
- Try-catch for JSON parsing
- Alert user on critical errors
- Log to console for debugging

### File Naming

**Python Modules**: `lowercase_with_underscores.py`
- Example: `smart_processor.py`, `ml_classifier.py`

**Web Files**: `lowercase_with_underscores` or descriptive names
- Example: `index.guia.html`, `app.js`, `styles.css`

**Data Files**: Descriptive with timestamps
- Example: `session_20231115_143022.csv`

### Data File Locations

**Temporary Runtime Data**:
- `/tmp/gnssai_smart` - FIFO for Bluetooth
- `/tmp/gnssai_dashboard_data.json` - Dashboard state

**ML Training Data**:
- `ml_training_data/` - Training CSV files
- `ml_models/` - Trained models and metadata

**Configuration**:
- Hardcoded in Python modules (future: config files)

### Version Numbering

**Format**: `vX.Y` (e.g., `v3.3`)
- X: Major version (breaking changes)
- Y: Minor version (features, bug fixes)

**Current Versions**:
- smart_processor.py: v3.3
- dashboard_server.py: v3.1

---

## Common Development Tasks

### Task 1: Add New NMEA Sentence Support

1. **Identify sentence type** (e.g., RMC for velocity)
2. **Add parser method** in `smart_processor.py`:
```python
def parse_nmea_rmc(self, line: str):
    parts = line.split(",")
    # Extract fields
    # Update self.stats or self.position
```
3. **Call parser** in `process_nmea_line()`:
```python
if "RMC" in line:
    self.parse_nmea_rmc(line)
```
4. **Update dashboard JSON** in `update_dashboard_json()` to include new fields
5. **Test** with real or simulated NMEA data

### Task 2: Modify ML Classification Thresholds

1. **Edit** `ml_classifier.py`
2. **Update thresholds** in `SignalClassifier.__init__()`:
```python
self.thresholds = {
    'snr_los_min': 38,  # Changed from 35
    # ...
}
```
3. **Test** with live data and monitor dashboard statistics
4. **Iterate** based on false positive/negative rates

### Task 3: Add New Dashboard Metric

1. **Compute metric** in `smart_processor.py`
2. **Add to JSON** in `update_dashboard_json()`:
```python
dashboard_data["new_metric"] = self.calculate_new_metric()
```
3. **Update HTML** in `dashboard_server.py` (embedded template):
```html
<div class="stat-chip">
  <div class="stat-label">New Metric</div>
  <div class="stat-value" id="new-metric-span">--</div>
</div>
```
4. **Update JavaScript** to populate element:
```javascript
document.getElementById("new-metric-span").textContent = data.new_metric;
```

### Task 4: Implement TILT Parsing

1. **Identify sentence format** on actual hardware:
```bash
sudo cat /dev/serial0 | grep -i "psti\|tilt\|ins"
```
2. **Update** `parse_tilt_sentence()` in `smart_processor.py`:
```python
if line.startswith("$PSTI,030"):
    parts = line.split(",")
    self.tilt["roll"] = float(parts[2])
    self.tilt["pitch"] = float(parts[3])
    self.tilt["heading"] = float(parts[4])
    self.tilt["status"] = "OK"
```
3. **Test** and verify dashboard tilt visualization updates

### Task 5: Add New Configuration Panel Tab

1. **Update HTML** in `index.guia.html`:
```html
<button class="nav-btn" data-panel="newtab">New Feature</button>
<section class="panel" id="panel-newtab">
  <!-- Controls here -->
</section>
```
2. **Add to panels object** in `app.js`:
```javascript
const panels = {
  // ...
  newtab: document.getElementById("panel-newtab")
};
```
3. **Update** `collectConfig()` and `applyConfigToUI()` in `app.js`

### Task 6: Deploy to Raspberry Pi

1. **Transfer files**:
```bash
scp -r tareas/ pi@raspberrypi.local:/home/pi/
```
2. **Install dependencies** on Pi:
```bash
ssh pi@raspberrypi.local
cd /home/pi/tareas
pip3 install -r requirements.txt  # Create requirements.txt first
```
3. **Test manually**:
```bash
python3 smart_processor.py
```
4. **Create systemd service** (see Development Workflows section)
5. **Enable and start service**:
```bash
sudo systemctl enable gnssai-processor
sudo systemctl start gnssai-processor
```

### Task 7: Debug FIFO Issues

**Check FIFO exists**:
```bash
ls -l /tmp/gnssai_smart
# Should show: prw-rw-rw- (p = pipe)
```

**Test FIFO manually**:
```bash
# Terminal 1 (reader)
cat /tmp/gnssai_smart

# Terminal 2 (writer)
echo "test" > /tmp/gnssai_smart
```

**Monitor processor output**:
```bash
python3 smart_processor.py 2>&1 | tee debug.log
```

**Common issues**:
- ENXIO: No reader connected (expected initially)
- EPIPE: Reader disconnected (handled with reconnect)
- Permission denied: Check file permissions (`chmod 666`)

---

## Testing & Debugging

### Manual Testing

**Test UART Input**:
```bash
# View raw NMEA stream
sudo cat /dev/serial0

# Filter for specific sentences
sudo cat /dev/serial0 | grep GGA
```

**Test Smart Processor**:
```bash
# Run with verbose output
python3 smart_processor.py

# Expected output:
# 🛰️  GNSS.AI Smart Processor v3.3
# ✅ UART opened
# 🚀 Processing NMEA...
# 📊 Sats=18 Q=4 HDOP=0.8 NMEA_out=1234 ...
```

**Test Dashboard**:
```bash
# Start server
python3 dashboard_server.py

# Open browser
firefox http://localhost:5000

# Check API
curl http://localhost:5000/api/stats | jq
```

**Test Bluetooth**:
```bash
# Start SPP server
python3 bluetooth_spp_server.py

# On Android device:
# 1. Pair with Raspberry Pi
# 2. Open Bluetooth terminal app
# 3. Connect to "GNSS-AI" service
# 4. Should see NMEA sentences streaming
```

### Simulating NMEA Data

**Create test NMEA file** (`test_nmea.txt`):
```
$GPGGA,123519,4807.038,N,01131.000,E,4,08,0.9,545.4,M,46.9,M,,*42
$GPGSV,3,1,11,03,03,111,00,04,15,270,00,06,01,010,00,13,06,292,00*74
$GPGSV,3,2,11,14,25,170,00,16,57,208,39,18,67,296,40,19,40,246,00*74
```

**Replay to virtual serial port**:
```bash
# Option 1: socat (create virtual port)
sudo socat -d -d pty,raw,echo=0 pty,raw,echo=0
# Note the PTY paths (e.g., /dev/pts/3 and /dev/pts/4)

# Terminal 1: Feed data
cat test_nmea.txt > /dev/pts/3

# Terminal 2: Run processor (modify uart_port in code)
python3 smart_processor.py
```

### Debugging Tips

**Enable Python debugging**:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Check process status**:
```bash
ps aux | grep python
pgrep -fa smart_processor
```

**Monitor system resources**:
```bash
top -p $(pgrep -f smart_processor)
htop
```

**Analyze JSON output**:
```bash
watch -n 1 "cat /tmp/gnssai_dashboard_data.json | jq '.position'"
```

**Bluetooth debugging**:
```bash
# Check Bluetooth status
sudo systemctl status bluetooth

# View Bluetooth logs
journalctl -u bluetooth -f

# Scan for devices
sudo bluetoothctl
> scan on
```

**Network debugging (dashboard)**:
```bash
# Check port listening
sudo netstat -tlnp | grep 5000
sudo ss -tlnp | grep 5000

# Test from remote machine
curl http://<raspberry-pi-ip>:5000/api/stats
```

### Common Issues & Solutions

**Issue**: `ModuleNotFoundError: No module named 'serial'`
- **Solution**: `pip3 install pyserial`

**Issue**: `Permission denied: '/dev/serial0'`
- **Solution**: `sudo usermod -a -G dialout $USER` (logout/login required)

**Issue**: FIFO writes failing with ENXIO
- **Solution**: Expected when no reader. Start `bluetooth_spp_server.py`

**Issue**: Dashboard shows old data
- **Solution**: Check `smart_processor.py` is running and updating JSON

**Issue**: ML classifier not working
- **Solution**: ML is optional. Check for "⚠️ ML Classifier not available" message. Install numpy if needed.

**Issue**: Bluetooth pairing fails
- **Solution**: Make Raspberry Pi discoverable: `sudo bluetoothctl → discoverable on`

**Issue**: No satellites visible
- **Solution**:
  - Check antenna connection
  - Ensure clear sky view
  - Wait 2-5 minutes for cold start
  - Verify UART is receiving data: `sudo cat /dev/serial0`

---

## AI Assistant Guidelines

### When Working with This Codebase

1. **Understand the Architecture**: Review the architecture diagram and data flow before making changes

2. **Maintain Backward Compatibility**: This system may be deployed in field conditions. Breaking changes should be clearly documented.

3. **Test with Real Hardware in Mind**:
   - UART interfaces can be finicky
   - Bluetooth connections may drop
   - File I/O should handle errors gracefully

4. **Preserve Emoji Logging**: The emoji-based logging is intentional for quick visual scanning in terminal logs.

5. **ML is Optional**: Never make ML a hard dependency. The system should work without it.

6. **FIFO Handling is Critical**: Non-blocking writes with ENXIO recovery are essential for reliability.

7. **Dashboard Should Be Self-Contained**: The embedded HTML in `dashboard_server.py` makes deployment simpler.

8. **Document Hardware Dependencies**: Any changes related to UART, Bluetooth, or GNSS modules should update the Hardware Integration section.

### Code Modification Patterns

**Adding a New Feature**:
1. Update `smart_processor.py` for data processing
2. Update `update_dashboard_json()` for JSON output
3. Update `dashboard_server.py` HTML template for UI
4. Update this CLAUDE.md documentation

**Bug Fix Pattern**:
1. Identify root cause with verbose logging
2. Add defensive error handling
3. Test with edge cases
4. Document fix in commit message

**Performance Optimization**:
1. Profile with actual UART data rates (115200 baud ≈ 11 KB/s)
2. NMEA rate is typically 1-10 Hz, not CPU-intensive
3. Optimize JSON writes (currently every 20 sentences is good)
4. Avoid blocking operations in main loop

### Questions to Ask Before Modifying

- **Does this change affect real-time processing?** (Main loop latency is critical)
- **Will this work with intermittent Bluetooth connections?** (Field use cases)
- **Does this require additional hardware?** (Document in Hardware Integration)
- **Is the error handling robust?** (UART, FIFO, Bluetooth can all fail)
- **Does the dashboard still work without JavaScript?** (No, but minimize JS dependencies)

---

## Future Enhancements (Roadmap)

### Short-term (Next Features)
- [ ] Implement TILT parsing for K922/K222 modules
- [ ] Add RMC sentence parsing (velocity, course)
- [ ] Configuration file support (YAML/JSON)
- [ ] WebSocket backend for configuration panel
- [ ] Systemd service templates

### Medium-term (ML & Features)
- [ ] Train and deploy Random Forest ML model
- [ ] Real-time CN0 (Carrier-to-Noise) tracking
- [ ] Satellite elevation/azimuth skyplot in dashboard
- [ ] RTCM3 parser and correction handling
- [ ] NTRIP client integration

### Long-term (Advanced Features)
- [ ] Multi-frequency (L1/L2/L5) support
- [ ] Dual-antenna heading (when hardware supports)
- [ ] Custom message filtering/routing
- [ ] Historical data logging and replay
- [ ] Cloud integration for correction services
- [ ] Mobile app (React Native/Flutter)

---

## Additional Resources

### External Documentation
- NMEA 0183 Standard: https://www.nmea.org/content/STANDARDS/NMEA_0183_Standard
- RTCM 3.x Standards: https://rtcm.myshopify.com/
- Bluetooth SPP: https://www.bluetooth.com/specifications/specs/serial-port-profile-1-1/
- PySerial Documentation: https://pyserial.readthedocs.io/

### Hardware Datasheets
- SinoGNSS K922: See `SinoGNSS_K922_GNSS_Module_Specification_v1.4.pdf`
- ComNav K902: See `ComNav OEM Board Reference Manual_V1.8 (1).pdf`

### Related Projects
- RTKLIB: Open-source RTK library (C)
- u-blox u-center: GNSS configuration tool (Windows)
- SW Maps: Mobile GIS with GNSS support

---

## Contact & Contribution

### Repository
- **Location**: `editarrifotogrametria-cloud/tareas`
- **Branch**: `claude/claude-md-mi67snote97rjpmm-01Wd1zLL1Tuk7eysVbqxNXQC`

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make changes with clear commit messages
4. Test with real hardware if possible
5. Update CLAUDE.md documentation
6. Submit pull request

### Issue Reporting
When reporting issues, include:
- Hardware: GNSS module model, Raspberry Pi version
- Software: Python version, OS version
- Logs: Console output from affected component
- NMEA samples: If relevant to parsing issues

---

## Glossary

**Terms & Acronyms**:

- **GNSS**: Global Navigation Satellite System (GPS, GLONASS, Galileo, BeiDou, etc.)
- **RTK**: Real-Time Kinematic (high-precision GNSS with cm-level accuracy)
- **NMEA**: National Marine Electronics Association (standard for GPS data)
- **GGA**: Fix information sentence (position, quality, satellites)
- **GSV**: Satellites in view sentence (PRN, elevation, azimuth, SNR)
- **HDOP**: Horizontal Dilution of Precision (lower is better, <2 is good)
- **SNR/CN0**: Signal-to-Noise Ratio / Carrier-to-Noise Density Ratio (dBHz)
- **LOS**: Line of Sight (direct satellite signal)
- **NLOS**: Non-Line of Sight (obstructed signal)
- **Multipath**: Signal reflections causing positioning errors
- **SPP**: Serial Port Profile (Bluetooth)
- **FIFO**: First-In-First-Out (named pipe for IPC)
- **IMU**: Inertial Measurement Unit (accelerometer + gyroscope)
- **INS**: Inertial Navigation System (IMU + sensor fusion)
- **UART**: Universal Asynchronous Receiver-Transmitter (serial communication)

**Quality Values** (from NMEA GGA):
- 0: Invalid/No fix
- 1: GPS fix (standalone)
- 2: DGPS fix (differential)
- 4: RTK fixed (cm-level)
- 5: RTK float (dm-level)
- 6: Estimated/dead reckoning

---

**End of CLAUDE.md**

*For questions or clarifications about this documentation, please refer to the actual source code or submit an issue.*
