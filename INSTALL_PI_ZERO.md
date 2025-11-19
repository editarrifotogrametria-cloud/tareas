# 🚀 Instalación en Raspberry Pi Zero

## Guía Completa de Instalación

Esta guía te ayudará a instalar todo el sistema GPS con FUNCIONABLE y TILT avanzado en tu Raspberry Pi Zero.

---

## 📋 Método 1: Instalación Rápida (Recomendado)

### Conectarse a la Pi Zero

```bash
ssh pi@raspberrypi.local
# o
ssh pi@<IP_DE_TU_PI>
# Password por defecto: raspberry
```

### Clonar el Repositorio Completo

```bash
# Ir al directorio home
cd ~

# Clonar el repositorio con el branch correcto
git clone -b claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D \
  https://github.com/editarrifotogrametria-cloud/tareas.git gnss-system

# Entrar al directorio
cd gnss-system

# Verificar que todo está correcto
ls -la
```

Deberías ver:
```
- funcionable/          ← Aplicación FUNCIONABLE completa
- gnssai/              ← Sistema GNSS con TILT
- bootstrap_pi_zero.sh ← Script de instalación
- install_pi_zero.sh
- README, documentación, etc.
```

---

## 📦 Método 2: Instalación Manual Paso a Paso

Si prefieres tener más control:

```bash
# 1. Clonar el repositorio
cd ~
git clone https://github.com/editarrifotogrametria-cloud/tareas.git gnss-system
cd gnss-system

# 2. Cambiar al branch correcto
git checkout claude/setup-gps-pi-zero-01LgJUMddr4CUmQT9vC1Hq9D

# 3. Verificar el estado
git status
git log --oneline -3
```

---

## 🔧 Instalar Dependencias

```bash
cd ~/gnss-system

# Actualizar sistema
sudo apt-get update

# Instalar Python y dependencias
sudo apt-get install -y python3 python3-pip python3-serial

# Instalar librerías Python necesarias
pip3 install flask flask-socketio pyserial

# Opcional: Bluetooth para GPS
sudo apt-get install -y bluez bluez-tools rfkill
```

---

## 🚀 Iniciar el Sistema

### Opción A: Iniciar Servidor GPS (Incluye FUNCIONABLE)

```bash
cd ~/gnss-system/gnssai

# Iniciar el servidor principal (incluye FUNCIONABLE)
python3 gps_server.py
```

Verás algo como:
```
======================================================================
🛰️  GPS Server - Professional Web Interface
======================================================================
🏠 Home:              http://0.0.0.0:5000
⭐ FUNCIONABLE:       http://0.0.0.0:5000/funcionable    ✨ DESTACADO
⚙️ ComNav Control:    http://0.0.0.0:5000/comnav         🎯 TILT
🎯 Professional:      http://0.0.0.0:5000/professional
📍 Collector:         http://0.0.0.0:5000/collector
📊 Dashboard:         http://0.0.0.0:5000/dashboard
======================================================================
```

### Opción B: Sistema Completo con Smart Processor

```bash
cd ~/gnss-system/gnssai

# Terminal 1: Iniciar Smart Processor (procesa datos GPS)
./run_smart_processor.sh

# Terminal 2: Iniciar Servidor Web
python3 gps_server.py
```

---

## 🌐 Acceder a las Aplicaciones

Desde tu computadora o teléfono, abre el navegador y visita:

### 🔍 Encontrar la IP de tu Pi Zero

En la Pi Zero:
```bash
hostname -I
# Ejemplo: 192.168.1.100
```

### 📱 URLs de Acceso

Reemplaza `<PI_IP>` con la IP de tu Pi Zero:

- **🌟 FUNCIONABLE (Principal):**
  `http://<PI_IP>:5000/funcionable`
  Aplicación completa de Comnav para captura de puntos GNSS

- **⚙️ ComNav Control (TILT):**
  `http://<PI_IP>:5000/comnav`
  Control del módulo K222 con INS/TILT avanzado

- **🏠 Página Principal:**
  `http://<PI_IP>:5000`
  Menú con todas las aplicaciones

- **🎯 GPS Professional:**
  `http://<PI_IP>:5000/professional`
  Interfaz completa con proyectos, DATUM, TILT, cámara

- **📍 Point Collector:**
  `http://<PI_IP>:5000/collector`
  Interfaz simple estilo Emlid Flow

- **📊 Dashboard:**
  `http://<PI_IP>:5000/dashboard`
  Dashboard técnico con ML y estadísticas

- **📡 API REST:**
  `http://<PI_IP>:5000/api/stats`
  API JSON con datos GPS en tiempo real

---

## 🔄 Configurar Inicio Automático (Opcional)

Para que el sistema inicie automáticamente al encender la Pi:

```bash
cd ~/gnss-system/gnssai

# Copiar servicios systemd
sudo cp servicios_systemd/*.service /etc/systemd/system/

# Habilitar servicios
sudo systemctl enable gnssai-smart.service
sudo systemctl enable gnssai-dashboard.service  # o bt-gps-spp.service

# Iniciar servicios
sudo systemctl start gnssai-smart.service
sudo systemctl start gnssai-dashboard.service

# Verificar estado
sudo systemctl status gnssai-smart.service
```

---

## 📝 Verificar Instalación

### Comprobar Estructura de Archivos

```bash
cd ~/gnss-system
tree -L 2
# o si no tienes tree:
ls -la
ls -la funcionable/
ls -la gnssai/
```

Debes tener:
```
gnss-system/
├── funcionable/
│   ├── index.html
│   ├── config.example.json
│   ├── README.md
│   └── static/
│       ├── css/
│       └── js/
├── gnssai/
│   ├── gps_server.py          ← Servidor principal
│   ├── smart_processor.py     ← Procesador con TILT mejorado
│   ├── comnav_control.html    ← Control K222
│   ├── quick_setup_ins.sh     ← Setup INS rápido
│   └── ...
└── ...
```

### Comprobar que el GPS Está Conectado

```bash
# Ver dispositivos serie
ls -la /dev/serial* /dev/ttyUSB* /dev/ttyAMA* 2>/dev/null

# Ver datos GPS en vivo (Ctrl+C para salir)
sudo cat /dev/serial0
# Deberías ver mensajes NMEA: $GPGGA, $GPRMC, etc.
```

### Probar Comandos ComNav

```bash
cd ~/gnss-system/gnssai

# Enviar comando de prueba
python3 test_comnav_commands.py "log com1 gpgga ontime 1"
```

---

## 🎯 Configurar TILT/INS

Si tienes un módulo ComNav K222/K803/K823 con IMU:

```bash
cd ~/gnss-system/gnssai

# Ejecutar configuración automática de INS
./quick_setup_ins.sh
```

Esto configurará:
- ✅ Modo INS activado (eje tipo 6)
- ✅ Mensajes NMEA a 5 Hz (GGA, RMC, GSV)
- ✅ Mensajes de actitud (GPNAV, GPYBM, GPTRA)
- ✅ Elevación mínima 10°
- ✅ Configuración guardada en el módulo

---

## 🐛 Solución de Problemas

### No veo datos GPS

```bash
# Verificar puerto GPS
echo $GPS_PORT  # Debe mostrar /dev/serial0 o similar

# Si está vacío, configurar:
export GPS_PORT=/dev/serial0

# Verificar permisos
sudo usermod -a -G dialout $USER
# Luego reiniciar sesión
```

### Puerto bloqueado

```bash
# Ver qué proceso usa el puerto
sudo lsof | grep /dev/serial0

# Matar proceso si es necesario
sudo killall python3
```

### Error "Address already in use" en puerto 5000

```bash
# Matar proceso en puerto 5000
sudo lsof -ti:5000 | xargs kill -9

# O cambiar puerto en gps_server.py
# Editar: port=5000 → port=8080
```

### FUNCIONABLE no carga CSS/JS

```bash
# Verificar que los archivos estén completos
ls -lh ~/gnss-system/funcionable/static/css/
ls -lh ~/gnss-system/funcionable/static/js/

# Todos los archivos deben existir:
# - chunk-vendors.css (~600KB)
# - index.css (~19KB)
# - chunk-vendors.js (~1.2MB)
# - chunk-common.js (~257KB)
# - index.js (~137KB)
```

---

## 📚 Documentación Adicional

- **FUNCIONABLE:** `~/gnss-system/funcionable/README.md`
- **Quick Start:** `~/gnss-system/funcionable/QUICKSTART.md`
- **Config GPS:** `~/gnss-system/COMNAV_SETUP.md`
- **Setup Pi:** `~/gnss-system/PI_ZERO_SETUP.md`

---

## 🎉 ¡Listo!

Ahora tienes:
- ✅ FUNCIONABLE completamente integrado
- ✅ Sistema TILT/INS avanzado con velocidades
- ✅ Control ComNav K222
- ✅ Múltiples interfaces GPS
- ✅ API REST para desarrollo

Accede a `http://<PI_IP>:5000` y elige la aplicación que necesites.

**¡Disfruta tu sistema GPS profesional!** 🛰️
