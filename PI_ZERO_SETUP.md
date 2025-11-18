# Configuración GNSS.AI en Raspberry Pi Zero 2 W - ComNav K222

Guía completa para configurar el sistema GNSS.AI con ComNav K222 en tu Raspberry Pi Zero 2 W.

## 🎯 Requisitos Previos

- Raspberry Pi Zero 2 W con Raspberry Pi OS instalado
- ComNav K222 conectado al puerto serial (`/dev/serial0`)
- Conexión a Internet para instalación inicial
- Usuario: `gnssai2`

## 📦 Instalación Rápida

Ejecuta estos comandos en tu Pi Zero (conectado como `gnssai2@gnssai2`):

```bash
# 1. Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependencias Python
sudo apt install -y python3-pip python3-serial
pip3 install flask flask-socketio pyserial

# 3. Crear directorio del proyecto
cd ~
mkdir -p gnssai

# 4. Ir al directorio donde tienes los archivos del repo
# (Asumiendo que ya clonaste el repo)
cd ~/tareas

# 5. Copiar archivos del directorio gnssai/ a ~/gnssai/
cp -r gnssai/* ~/gnssai/

# 6. Dar permisos de ejecución a los scripts
chmod +x ~/gnssai/start_*.sh
chmod +x ~/gnssai/config_com3.sh

# 7. Configurar el puerto serial
sudo raspi-config
# Ir a: Interface Options -> Serial Port
# - Login shell over serial: NO
# - Serial port hardware enabled: YES

# 8. Agregar usuario al grupo dialout
sudo usermod -a -G dialout gnssai2

# 9. Reiniciar para aplicar cambios
sudo reboot
```

## 🚀 Iniciar el Sistema

Después del reinicio, inicia el servidor GPS Professional:

```bash
cd ~/gnssai
./start_gps_professional.sh
```

O de forma manual:

```bash
cd ~/gnssai
python3 gps_server.py
```

## 🌐 Acceder a la Interfaz Web

Desde cualquier dispositivo en la misma red WiFi:

- **Home**: http://gnssai2.local:5000
- **GPS Professional**: http://gnssai2.local:5000/professional ⭐ RECOMENDADO
- **Collector**: http://gnssai2.local:5000/collector
- **Dashboard**: http://gnssai2.local:5000/dashboard

O usando la IP directa: `http://192.168.x.x:5000`

## 📡 Comandos ComNav K222 Disponibles

La interfaz web incluye estos comandos para ComNav K222:

- **SAVECONFIG**: Guardar configuración en el GPS
- **FRESET**: Reset a valores de fábrica
- Más comandos disponibles vía API

## 🔧 Procesar Datos GNSS

Para procesar datos del ComNav K222:

```bash
cd ~/gnssai
python3 smart_processor.py
```

Este script:
- Lee datos NMEA desde `/dev/serial0` (ComNav K222)
- Procesa y clasifica señales con ML
- Genera JSON para el dashboard: `/tmp/gnssai_dashboard_data.json`
- Envía datos por FIFO para Bluetooth

## 🔄 Inicio Automático (Opcional)

### GPS Professional Server

```bash
sudo nano /etc/systemd/system/gps-professional.service
```

Contenido:

```ini
[Unit]
Description=GPS Professional Server - GNSS.AI
After=network.target

[Service]
Type=simple
User=gnssai2
WorkingDirectory=/home/gnssai2/gnssai
ExecStart=/usr/bin/python3 /home/gnssai2/gnssai/gps_server.py
Restart=always
RestartSec=10
Environment="GPS_PORT=/dev/serial0"

[Install]
WantedBy=multi-user.target
```

Activar:

```bash
sudo systemctl daemon-reload
sudo systemctl enable gps-professional
sudo systemctl start gps-professional
sudo systemctl status gps-professional
```

### Smart Processor (Procesador de Datos GNSS)

```bash
sudo nano /etc/systemd/system/gnss-processor.service
```

Contenido:

```ini
[Unit]
Description=GNSS Smart Processor
After=network.target

[Service]
Type=simple
User=gnssai2
WorkingDirectory=/home/gnssai2/gnssai
ExecStart=/usr/bin/python3 /home/gnssai2/gnssai/smart_processor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activar:

```bash
sudo systemctl daemon-reload
sudo systemctl enable gnss-processor
sudo systemctl start gnss-processor
sudo systemctl status gnss-processor
```

## 🧪 Verificar Funcionamiento

### 1. Verificar puerto serial

```bash
ls -l /dev/serial0
# Debería mostrar: lrwxrwxrwx 1 root root 5 ... /dev/serial0 -> ttyS0
```

### 2. Ver datos crudos del GPS

```bash
cat /dev/serial0
# Deberías ver sentencias NMEA como:
# $GNGGA,123456.00,1234.5678,N,12345.6789,W,1,12,0.9,100.0,M,0.0,M,,*XX
```

### 3. Verificar servicios

```bash
sudo systemctl status gps-professional
sudo systemctl status gnss-processor
```

### 4. Ver logs

```bash
journalctl -u gps-professional -f
journalctl -u gnss-processor -f
```

## 📊 Estructura de Archivos en la Pi

```
/home/gnssai2/gnssai/
├── dashboard_server.py          # Servidor Dashboard
├── gps_server.py                # Servidor GPS Professional ⭐
├── gnssai_collector.py          # Colector de datos
├── smart_processor.py           # Procesador inteligente ⭐
├── start_dashboard.sh           # Script inicio Dashboard
├── start_gps_professional.sh    # Script inicio GPS Professional
├── config_com3.sh               # Configuración COM3 (Windows)
├── .env                         # Variables de entorno
├── templates/
│   └── index.html              # Interfaz web Dashboard
├── static/
│   ├── css/
│   │   ├── chunk-vendors.d93e9d9a.css
│   │   └── index.8349ed33.css
│   └── js/
│       ├── chunk-common.22a6f926.js
│       ├── chunk-vendors.31517009.js
│       └── index.0bca27f0.js
└── README.md                    # Documentación general
```

## 🐛 Solución de Problemas

### No se ven datos del GPS

1. Verificar conexión del ComNav K222:
```bash
cat /dev/serial0
```

2. Verificar permisos:
```bash
groups gnssai2
# Debe incluir: dialout
```

3. Verificar baudrate:
```bash
stty -F /dev/serial0 115200
```

### El servidor no inicia

1. Verificar Python:
```bash
python3 --version
# Debería ser Python 3.7+
```

2. Verificar dependencias:
```bash
pip3 list | grep -E "(flask|serial)"
```

3. Ver errores:
```bash
python3 ~/gnssai/gps_server.py
```

### Puerto 5000 en uso

Editar el archivo `gps_server.py` y cambiar el puerto al final:

```python
socketio.run(app, host="0.0.0.0", port=8080, ...)  # Cambiar 5000 a 8080
```

### No se pueden enviar comandos ComNav

1. Verificar que smart_processor.py NO esté corriendo (bloquea el puerto):
```bash
sudo systemctl stop gnss-processor
```

2. Verificar puerto en uso:
```bash
lsof /dev/serial0
```

3. Matar procesos que usan el puerto:
```bash
sudo killall python3
# O más específico:
sudo fuser -k /dev/serial0
```

## 🎨 Personalización

### Cambiar URL del servidor

En la interfaz web, ve a "Configuración" y cambia la URL del servidor.

O edita directamente en el navegador el localStorage:

```javascript
// En la consola del navegador:
localStorage.setItem('gnssai_config', JSON.stringify({
    serverUrl: 'http://192.168.1.100:5000',
    // ... otras configuraciones
}));
```

### Agregar más comandos ComNav

Edita `templates/index.html` y agrega botones en la sección "Comandos ComNav":

```html
<button class="btn btn-primary" onclick="sendComNavCommand('TU_COMANDO')">
    📡 Descripción del Comando
</button>
```

## 📚 Comandos ComNav K222 Útiles

Algunos comandos que puedes enviar al ComNav K222:

- `SAVECONFIG`: Guardar configuración actual
- `FRESET`: Reset a valores de fábrica
- `LOG COM1 GNGGA ONTIME 1`: Activar salida GNGGA cada 1 segundo
- `LOG COM1 GPGSA ONTIME 1`: Activar salida GPGSA cada 1 segundo
- `SERIALCONFIG COM1 115200 N 8 1 N OFF ON`: Configurar puerto serial
- `ANTHEIGHT 0.0`: Establecer altura de antena
- `UNMASK GPS L1`: Desbloquear GPS L1
- `MASK GPS L1`: Bloquear GPS L1

**IMPORTANTE**: Siempre ejecuta `SAVECONFIG` después de hacer cambios para que persistan.

## 🔐 Seguridad

Si vas a exponer el servidor a Internet:

1. Usa un reverse proxy como nginx
2. Agrega autenticación
3. Usa HTTPS con Let's Encrypt
4. Configura firewall (ufw)

```bash
sudo apt install ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 5000/tcp # GPS Server
sudo ufw enable
```

## 📞 Soporte

Para más información:
- Revisa los logs: `journalctl -u gps-professional -f`
- Consulta el README.md en `~/gnssai/`
- Verifica el manual ComNav K222 en el repo

---

**Versión**: 1.0
**Última actualización**: 2025-01-18
**Compatible con**: Raspberry Pi Zero 2 W, ComNav K222
