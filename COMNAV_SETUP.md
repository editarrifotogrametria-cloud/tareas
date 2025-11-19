# ComNav K222 - Guía Completa de Configuración y Uso

## Introducción

Sistema completo para control y monitoreo del módulo ComNav K222 GNSS con soporte para INS/TILT. Incluye interfaz web profesional con envío de comandos en tiempo real.

## Características

- ✅ Lectura de datos NMEA del ComNav K222
- ✅ Envío de comandos al módulo en tiempo real
- ✅ Activación y configuración de modo INS/TILT
- ✅ Visualización de actitud (heading, pitch, roll)
- ✅ Panel de control web interactivo
- ✅ Soporte para GPNAV, GPYBM, GPTRA
- ✅ Configuración de frecuencia de actualización
- ✅ Comandos rápidos pre-configurados

## Requisitos

### Hardware
- Raspberry Pi Zero (o superior)
- ComNav K222, K803, o K823 con IMU integrado
- Conexión UART (por defecto: `/dev/serial0`)

### Software
- Python 3.7+
- Flask y Flask-SocketIO
- pyserial

## Instalación Rápida

```bash
# 1. Navegar al directorio
cd /home/user/tareas/gnssai

# 2. Instalar dependencias (si es necesario)
pip3 install flask flask-socketio pyserial

# 3. Iniciar el procesador GPS
python3 smart_processor.py &

# 4. Iniciar el servidor web
python3 gps_server.py
```

## Acceso a la Interfaz Web

Abre tu navegador y visita:

```
http://<IP_DEL_PI>:5000/comnav
```

Por ejemplo:
- Local: `http://localhost:5000/comnav`
- Red local: `http://192.168.1.100:5000/comnav`

## Comandos ComNav Importantes

### Formato General
```
log com1 <mensaje> ontime <intervalo>
```

### Comandos Básicos NMEA

| Comando | Descripción | Frecuencia |
|---------|-------------|------------|
| `log com1 gpgga ontime 1` | Posición básica | 1 Hz |
| `log com1 gprmc ontime 1` | Recomendado mínimo | 1 Hz |
| `log com1 gpgsv ontime 5` | Satélites visibles | 0.2 Hz |
| `log com1 gpnav ontime 1` | Posición + Actitud | 1 Hz |
| `log com1 gpybm ontime 1` | Heading + Pitch | 1 Hz |
| `log com1 gptra ontime 1` | Heading (dual-antenna) | 1 Hz |
| `unlogall` | Detener todos los mensajes | - |

### Activación del Modo INS/TILT

#### Paso 1: Activar INS
```bash
INSMODE ENABLE 6
```
- El parámetro (1-8) define el tipo de eje IMU
- Valor 6 es el predeterminado más común
- Consulta el manual para tu orientación específica

#### Paso 2: Habilitar Mensajes de Actitud
```bash
log com1 gpnav ontime 1
log com1 gpybm ontime 1
```

#### Paso 3: Guardar Configuración
```bash
saveconfig
```

### Configuración Avanzada

#### Frecuencia de Actualización
```bash
# 5 Hz
log com1 gpgga ontime 0.2
log com1 gprmc ontime 0.2

# 10 Hz
log com1 gpgga ontime 0.1
log com1 gprmc ontime 0.1
```

#### Máscara de Elevación
```bash
# Ignorar satélites por debajo de 10°
ecutoff 10
saveconfig
```

#### Offset de Actitud
```bash
# Formato: HEADINGOFFSET <heading_deg> <pitch_deg>
HEADINGOFFSET 0.0 0.0
saveconfig
```

#### Ver Configuración Actual
```bash
log sysconfig
```

## Mensajes ComNav NMEA

### $GPNAV - Navegación Completa
Formato:
```
$GPNAV,time,lat,lat_dir,lon,lon_dir,quality,sats,hdop,alt,geoid,dgps_age,dgps_id,heading,pitch,roll,vel_n,vel_e,vel_d*checksum
```

Campos importantes:
- Campo 13: Heading (°)
- Campo 14: Pitch (°)
- Campo 15: Roll (°)

### $GPYBM - Heading y Pitch
Formato:
```
$GPYBM,time,heading,heading_type,pitch,pitch_type*checksum
```

Campos:
- Campo 2: Heading (°)
- Campo 3: Tipo (T=True, M=Magnetic)
- Campo 4: Pitch (°)

### $GPTRA - Heading (Dual-Antenna)
Formato:
```
$GPTRA,time,heading,heading_status,...*checksum
```

## Uso de la Interfaz Web

### Panel Principal

1. **Estado GPS/GNSS**: Muestra conexión, calidad, satélites, HDOP
2. **Posición**: Lat/Lon/Alt en tiempo real
3. **Actitud (TILT/INS)**: Heading, Pitch, Roll
4. **Brújula**: Visualización del heading

### Control ComNav

#### Comandos Rápidos NMEA
- Click en botones para enviar comandos pre-configurados
- GGA, RMC, GSV, GPNAV, GPYBM disponibles

#### Control INS/TILT
1. Seleccionar tipo de eje IMU (1-8)
2. Click en "Activar INS"
3. Configurar mensajes de actitud
4. Guardar configuración

#### Comando Personalizado
- Ingresar comando en el campo de texto
- Click en "Enviar Comando" o presionar Enter

### Configuración Avanzada

- **Frecuencia de Actualización**: 1-20 Hz
- **Elevación Mínima**: 0-90°
- **Offset de Actitud**: Calibración de heading/pitch

## Solución de Problemas

### El módulo no responde

1. Verificar conexión UART:
```bash
sudo cat /dev/serial0
```

2. Verificar baudrate (debe ser 115200):
```bash
stty -F /dev/serial0 115200
```

3. Verificar permisos:
```bash
sudo usermod -a -G dialout $USER
sudo chmod 666 /dev/serial0
```

### No se reciben datos de TILT

1. Verificar que el módulo tenga IMU:
   - Solo K803 y K823 tienen IMU integrado
   - K222 puede requerir IMU externo

2. Activar modo INS:
```bash
INSMODE ENABLE 6
saveconfig
```

3. Habilitar mensajes:
```bash
log com1 gpnav ontime 1
log com1 gpybm ontime 1
```

4. Verificar en consola web si llegan datos

### Errores de parsing

Si ves errores en la consola, verifica el formato real de los mensajes:

```bash
# En el Pi, capturar mensajes reales
sudo cat /dev/serial0 | grep -i gpnav
sudo cat /dev/serial0 | grep -i gpybm
```

Luego ajusta el parser en `smart_processor.py` si es necesario.

## Tipos de Eje IMU

El parámetro de INSMODE define la orientación del módulo:

| Tipo | X | Y | Z | Descripción |
|------|---|---|---|-------------|
| 1 | Forward | Right | Down | Estándar |
| 2 | Forward | Left | Up | Invertido Z |
| 3 | Backward | Right | Up | 180° rotación |
| 4 | Backward | Left | Down | 180° + invertido |
| 5 | Right | Forward | Down | 90° derecha |
| 6 | Right | Backward | Up | 90° derecha + inv |
| 7 | Left | Forward | Up | 90° izquierda |
| 8 | Left | Backward | Down | 90° izq + inv |

Selecciona el tipo que coincida con tu instalación física.

## Arquitectura del Sistema

```
┌─────────────────┐
│  ComNav K222    │ ──(UART)──┐
│  /dev/serial0   │            │
└─────────────────┘            │
                               ▼
                    ┌──────────────────────┐
                    │  smart_processor.py  │
                    │  - Lee NMEA          │
                    │  - Parsea TILT       │
                    │  - Genera JSON       │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  /tmp/gnssai_        │
                    │  dashboard_data.json │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  gps_server.py       │
                    │  - API REST          │
                    │  - WebSocket         │
                    │  - Envío comandos    │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  comnav_control.html │
                    │  - Interfaz web      │
                    │  - Control tiempo    │
                    │    real              │
                    └──────────────────────┘
```

## Archivos Principales

- `smart_processor.py`: Procesador NMEA con soporte TILT
- `gps_server.py`: Servidor web y API
- `comnav_control.html`: Interfaz de control
- `/tmp/gnssai_dashboard_data.json`: Datos en tiempo real

## API REST

### Obtener Datos GPS
```
GET /api/stats
```

Retorna JSON con posición, satélites, TILT, etc.

### Enviar Comando ComNav
```
POST /api/comnav/command
Content-Type: application/json

{
  "command": "log com1 gpgga ontime 1"
}
```

Retorna:
```json
{
  "status": "success",
  "command": "log com1 gpgga ontime 1",
  "response": "...",
  "port": "/dev/serial0"
}
```

## Ejemplo de Configuración Completa

```bash
# 1. Activar INS con eje tipo 6
INSMODE ENABLE 6

# 2. Configurar mensajes NMEA a 5 Hz
log com1 gpgga ontime 0.2
log com1 gprmc ontime 0.2
log com1 gpgsv ontime 5

# 3. Activar mensajes de actitud a 1 Hz
log com1 gpnav ontime 1
log com1 gpybm ontime 1

# 4. Configurar elevación mínima
ecutoff 10

# 5. Guardar todo
saveconfig
```

## Recursos Adicionales

- [ComNav Technology Website](https://www.comnavtech.com)
- [K-series User Guide](https://comnavtech.com/uploads/soft/20240530/5af2a87fd8dac4ecff61ee14dc919470.pdf)
- [ComNav OEM Reference Manual](https://www.comnavtech.com/uploads/soft/20240530/13318ef4a1b9f626ada0ef3df759ec83.pdf)

## Soporte

Para soporte técnico de ComNav:
- Email: oem.support@comnavtech.com
- Website: www.comnavtech.com

## Licencia

Este software es de código abierto. Úsalo libremente para tus proyectos.

---

**¡Disfruta de tu sistema GNSS con TILT! 🛰️**
