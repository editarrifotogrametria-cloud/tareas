# 🛰️ Instrucciones para Pi Zero 2W + ComNav K222

## Problema Detectado

Los errores `400 BAD REQUEST` en Socket.IO ocurren porque:
- El cliente del navegador usa Socket.IO v3 (Engine.IO v3 - `EIO=3`)
- El servidor Flask-SocketIO tiene una versión más moderna
- Son incompatibles entre sí

## Solución Completa

### Paso 1: Instalar Dependencias Correctas

En tu **Raspberry Pi Zero 2W**, ejecuta:

```bash
cd ~/tareas

# Dar permisos de ejecución al script
chmod +x install_dependencies.sh

# Ejecutar instalador
./install_dependencies.sh
```

**IMPORTANTE**: El script te preguntará si quieres instalar dependencias ML (numpy, pandas, scikit-learn). En Pi Zero 2W esto puede tomar **30-60 minutos**. Si solo quieres capturar puntos geodésicos, responde **N** (No).

### Paso 2: Cerrar Sesión y Volver a Entrar

Para que los permisos del puerto serial funcionen:

```bash
# Cerrar sesión SSH
exit

# Volver a conectar
ssh pi@tu-raspberry-pi.local
# O con IP: ssh pi@192.168.0.109
```

### Paso 3: Usar el Dashboard Actualizado

Hay **dos opciones**:

#### Opción A: Reemplazar el dashboard_server.py (Recomendado)

```bash
cd ~/tareas

# Hacer backup del anterior
mv dashboard_server.py dashboard_server_old.py

# Usar la nueva versión
cp dashboard_server_v3.2.py dashboard_server.py
```

#### Opción B: Ejecutar directamente la nueva versión

```bash
cd ~/tareas
python3 dashboard_server_v3.2.py
```

### Paso 4: Iniciar el Sistema Completo

Necesitas **3 terminales SSH** (o usa `tmux`/`screen`):

**Terminal 1 - Procesador NMEA:**
```bash
cd ~/tareas
python3 smart_processor.py
```

Deberías ver:
```
🛰️  GNSS.AI Smart Processor v3.3
✅ UART abierto
🚀 Procesando NMEA...
```

**Terminal 2 - Dashboard Web:**
```bash
cd ~/tareas
python3 dashboard_server.py  # O dashboard_server_v3.2.py
```

Deberías ver:
```
🛰️  GNSS.AI Dashboard Server v3.2
📊 Dashboard: http://0.0.0.0:5000
✅ Servidor iniciado.
```

**Terminal 3 - Bluetooth SPP (Opcional):**
```bash
cd ~/tareas
python3 bluetooth_spp_server.py
```

### Paso 5: Abrir el Dashboard

Desde tu computadora o móvil, abre en el navegador:

```
http://192.168.0.109:5000
```

(Reemplaza `192.168.0.109` con la IP de tu Pi Zero)

**Deberías ver:**
- ✅ Estado "ONLINE" en verde
- Datos de posición actualizándose cada segundo
- NO más errores 400 en la consola del navegador

---

## Verificar que Funciona

### 1. Verificar Puerto Serial

```bash
ls -l /dev/serial0
# Debería mostrar: lrwxrwxrwx ... /dev/serial0 -> ttyAMA0

# Ver datos NMEA en tiempo real
sudo cat /dev/serial0
# Deberías ver líneas como:
# $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
# $GPGSV,3,1,11,03,03,111,00,04,15,270,00,06,01,010,00,13,06,292,00*74
```

Si NO ves datos NMEA:
- Verifica el cableado del K222 al Pi Zero
- Asegúrate que el módulo K222 está alimentado correctamente
- Revisa que el baudrate sea 115200 (comando AT al módulo)

### 2. Verificar Dashboard

```bash
# Verificar que el servidor está escuchando
sudo netstat -tlnp | grep 5000
# Debería mostrar: tcp 0 0 0.0.0.0:5000 LISTEN python3

# Probar API REST
curl http://localhost:5000/api/stats
# Debería devolver JSON con datos GNSS
```

### 3. Verificar Archivo JSON

```bash
# Ver datos en tiempo real
watch -n 1 cat /tmp/gnssai_dashboard_data.json

# O ver una sola vez con formato
cat /tmp/gnssai_dashboard_data.json | python3 -m json.tool
```

---

## Uso con `tmux` (Recomendado para Producción)

Para no necesitar 3 terminales SSH:

```bash
# Instalar tmux
sudo apt-get install -y tmux

# Crear sesión
tmux new -s gnssai

# Terminal 1 (ya estás ahí)
cd ~/tareas && python3 smart_processor.py

# Crear nueva ventana: Ctrl+B luego C
cd ~/tareas && python3 dashboard_server.py

# Crear otra ventana: Ctrl+B luego C
cd ~/tareas && python3 bluetooth_spp_server.py

# Moverte entre ventanas: Ctrl+B luego número (0, 1, 2)

# Desconectarte sin matar procesos: Ctrl+B luego D

# Volver a conectar más tarde:
tmux attach -t gnssai
```

---

## Automatizar con Servicios systemd

Para que el sistema inicie automáticamente al encender la Pi:

### 1. Crear servicio para smart_processor

```bash
sudo nano /etc/systemd/system/gnssai-processor.service
```

Contenido:
```ini
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 2. Crear servicio para dashboard

```bash
sudo nano /etc/systemd/system/gnssai-dashboard.service
```

Contenido:
```ini
[Unit]
Description=GNSS.AI Dashboard Server
After=network.target gnssai-processor.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/tareas
ExecStart=/usr/bin/python3 /home/pi/tareas/dashboard_server.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 3. Activar servicios

```bash
# Recargar systemd
sudo systemctl daemon-reload

# Habilitar servicios
sudo systemctl enable gnssai-processor.service
sudo systemctl enable gnssai-dashboard.service

# Iniciar servicios
sudo systemctl start gnssai-processor.service
sudo systemctl start gnssai-dashboard.service

# Ver estado
sudo systemctl status gnssai-processor.service
sudo systemctl status gnssai-dashboard.service

# Ver logs
sudo journalctl -u gnssai-processor.service -f
sudo journalctl -u gnssai-dashboard.service -f
```

---

## Solución de Problemas Comunes

### Error: "Permission denied: '/dev/serial0'"

```bash
# Añadir usuario al grupo dialout
sudo usermod -a -G dialout $USER

# IMPORTANTE: Cerrar sesión y volver a entrar
exit
# Reconectar SSH
```

### Error: "ModuleNotFoundError: No module named 'serial'"

```bash
pip3 install --user pyserial
```

### Error: "ModuleNotFoundError: No module named 'flask'"

```bash
pip3 install --user Flask flask-socketio
```

### Dashboard muestra datos viejos o "--"

1. Verificar que `smart_processor.py` está corriendo:
```bash
ps aux | grep smart_processor
```

2. Verificar que está generando el archivo JSON:
```bash
ls -lh /tmp/gnssai_dashboard_data.json
cat /tmp/gnssai_dashboard_data.json
```

3. Si el archivo no existe o está vacío, revisar errores del procesador:
```bash
python3 smart_processor.py
# Ver mensajes de error
```

### K222 no envía datos NMEA

1. Verificar cableado:
```
K222 TX  → Pi GPIO 15 (RXD)
K222 RX  → Pi GPIO 14 (TXD)
K222 GND → Pi GND
K222 VCC → Pi 5V (verificar que el módulo soporta 5V)
```

2. Verificar puerto serial habilitado:
```bash
# Editar config
sudo nano /boot/config.txt

# Debe contener:
enable_uart=1

# Reiniciar
sudo reboot
```

3. Configurar baudrate del K222 (si es necesario):
- Algunos módulos K222 vienen configurados a 9600 bps
- Usar el software del fabricante para cambiar a 115200 bps
- O modificar `smart_processor.py` línea 39: `self.uart_baud = 9600`

---

## Rendimiento en Pi Zero 2W

La Raspberry Pi Zero 2W tiene CPU de 4 núcleos a 1 GHz, suficiente para GNSS.AI sin ML:

- ✅ `smart_processor.py`: ~5% CPU
- ✅ `dashboard_server.py`: ~3% CPU
- ✅ `bluetooth_spp_server.py`: ~2% CPU
- ⚠️ ML (numpy/sklearn): Puede consumir 50-100% CPU si se activa

**Recomendación**: Para Pi Zero 2W, mantén el ML desactivado. Si lo necesitas, usa una Pi 3 o Pi 4.

---

## Contacto y Soporte

Si tienes problemas:

1. Verifica los logs con `journalctl` (si usas systemd)
2. Ejecuta manualmente los scripts para ver errores directos
3. Comparte los mensajes de error completos
4. Indica el modelo exacto del módulo GNSS (K222, K902, K922)

**Hardware Probado:**
- ✅ Raspberry Pi Zero 2W
- ✅ ComNav K222
- ✅ SinoGNSS K902/K922

---

## Próximos Pasos

Una vez funcionando:

1. **Calibrar TILT** (si tu K222 tiene IMU):
   - El módulo debe calibrarse en campo
   - Mantener el bastón vertical y girar 360°
   - Ver datos de pitch/roll en el dashboard

2. **Configurar RTK**:
   - Necesitas una base RTK o servicio NTRIP
   - Enviar correcciones RTCM3 al K222
   - Ver calidad RTK FIXED (precisión 1-2 cm)

3. **Conectar Apps Móviles**:
   - Usar `bluetooth_spp_server.py`
   - Conectar SW Maps o Mobile Topographer
   - Recibir NMEA en tiempo real vía Bluetooth

---

**¡Listo! Ahora tienes un sistema GNSS.AI profesional en tu Pi Zero 2W!** 🎉
