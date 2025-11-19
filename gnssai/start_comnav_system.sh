#!/bin/bash
# Start ComNav K222 GNSS System
# Complete system with TILT/INS support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/gnssai_logs"

# Create log directory
mkdir -p "$LOG_DIR"

echo "============================================================"
echo "🛰️  Starting ComNav K222 GNSS System"
echo "============================================================"

# Check if processes are already running
if pgrep -f "smart_processor.py" > /dev/null; then
    echo "⚠️  smart_processor.py already running. Stopping it first..."
    pkill -f "smart_processor.py"
    sleep 2
fi

if pgrep -f "gps_server.py" > /dev/null; then
    echo "⚠️  gps_server.py already running. Stopping it first..."
    pkill -f "gps_server.py"
    sleep 2
fi

# Start smart processor (NMEA reader with TILT parsing)
echo "📡 Starting Smart Processor..."
cd "$SCRIPT_DIR"
python3 smart_processor.py > "$LOG_DIR/smart_processor.log" 2>&1 &
PROC_PID=$!
echo "   ✅ Smart Processor started (PID: $PROC_PID)"
sleep 2

# Start GPS server (Web interface and API)
echo "🌐 Starting GPS Server..."
python3 gps_server.py > "$LOG_DIR/gps_server.log" 2>&1 &
SERVER_PID=$!
echo "   ✅ GPS Server started (PID: $SERVER_PID)"
sleep 3

# Print access information
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "============================================================"
echo "✅ ComNav K222 System Started Successfully!"
echo "============================================================"
echo ""
echo "🌐 Web Interfaces:"
echo "   - ComNav Control:  http://$IP:5000/comnav  ⭐ NUEVO"
echo "   - Professional:    http://$IP:5000/professional"
echo "   - Collector:       http://$IP:5000/collector"
echo "   - Dashboard:       http://$IP:5000/dashboard"
echo ""
echo "📡 APIs:"
echo "   - GPS Data:        http://$IP:5000/api/stats"
echo "   - ComNav Commands: http://$IP:5000/api/comnav/command"
echo ""
echo "📝 Logs:"
echo "   - Processor: $LOG_DIR/smart_processor.log"
echo "   - Server:    $LOG_DIR/gps_server.log"
echo ""
echo "💡 Para detener el sistema:"
echo "   pkill -f smart_processor.py"
echo "   pkill -f gps_server.py"
echo ""
echo "============================================================"
echo "📖 Consulta COMNAV_SETUP.md para comandos y configuración"
echo "============================================================"
