# 📍 GNSS.AI Point Collector

**Aplicación profesional para toma de puntos RTK con Raspberry Pi Zero 2W + ComNav K222**

## 🎯 Características

- ✅ **Interfaz móvil profesional** - Diseño tipo app nativa, optimizada para celular
- ✅ **PWA (Progressive Web App)** - Instalable como aplicación en el celular
- ✅ **Visualización en tiempo real** - Posición, RTK status, satélites, precisión
- ✅ **Toma de puntos con un toque** - Botón grande y fácil de usar
- ✅ **Almacenamiento SQLite** - Base de datos local robusta
- ✅ **Exportación múltiple** - CSV y JSON con un toque
- ✅ **Estadísticas en vivo** - Total puntos, RTK fixed, precisión promedio
- ✅ **Auto-inicio** - Sistema listo al encender la Raspberry Pi
- ✅ **WiFi Hotspot opcional** - Acceso directo sin necesidad de router

---

## 📦 Requisitos

### Hardware
- **Raspberry Pi Zero 2W** (o superior)
- **ComNav K222** módulo GNSS/RTK
- **Tarjeta microSD** (mínimo 8GB, recomendado 16GB+)
- **Fuente de alimentación** 5V/2.5A

### Conexiones UART
```
K222 → Raspberry Pi
TXD1 → GPIO 15 (RXD)
RXD1 → GPIO 14 (TXD)
GND  → GND
VCC  → 5V
```

---

## 🚀 Instalación Rápida

### 1. Preparar Raspberry Pi OS

```bash
# Descargar Raspberry Pi OS Lite (64-bit recomendado)
# Flashear en microSD con Raspberry Pi Imager
# Habilitar SSH en primera configuración
```

### 2. Clonar repositorio

```bash
cd ~
git clone https://github.com/tu-usuario/gnssai.git
cd gnssai
```

### 3. Ejecutar instalador

```bash
chmod +x install_pi_zero.sh
./install_pi_zero.sh
```

El instalador realizará automáticamente:
- ✅ Verificación del sistema
- ✅ Instalación de dependencias
- ✅ Configuración de UART
- ✅ Creación de servicios systemd
- ✅ (Opcional) Configuración de WiFi Hotspot

### 4. Reiniciar

```bash
sudo reboot
```

### 5. ¡Listo!

Accede desde tu celular:
- **Red local**: `http://<IP_RASPBERRY>:8080`
- **WiFi Hotspot**: `http://192.168.4.1:8080`

---

## 📱 Uso de la Aplicación

### Interfaz Principal

```
┌─────────────────────────────────┐
│  📍 GNSS Point Collector        │
│                    🟢 Conectado │
├─────────────────────────────────┤
│  Posición Actual   [RTK FIXED]  │
│                                 │
│  Lat: 40.12345678               │
│  Lon: -105.12345678             │
│  Alt: 1650.234 m                │
│  Sats: 24                       │
│                                 │
│  Precisión: 2.3 cm ████████░░   │
├─────────────────────────────────┤
│                                 │
│         ┌─────────┐             │
│         │         │             │
│         │ 📍 TOMAR│             │
│         │  PUNTO  │             │
│         │         │             │
│         └─────────┘             │
│                                 │
├─────────────────────────────────┤
│  12 Total  │ 10 RTK  │ 2.1cm   │
│  Puntos    │ Fixed   │ Media   │
├─────────────────────────────────┤
│  Puntos Guardados  [Borrar Todo]│
│                                 │
│  📌 Punto PT_20241120_143022    │
│     2024-11-20 14:30:22         │
│     Lat: 40.12345678            │
│     Lon: -105.12345678          │
│     Alt: 1650.234 m             │
│                      🗑️ Eliminar│
│                                 │
└─────────────────────────────────┘
│ 📄 Exportar CSV │ 💾 Exportar JSON│
└─────────────────────────────────┘
```

### Tomar un Punto

1. **Esperar RTK FIXED** - El botón se habilitará automáticamente
2. **Presionar el botón** 📍 TOMAR PUNTO
3. **Confirmar guardado** - Aparecerá notificación verde
4. **El punto aparecerá** en la lista inmediatamente

### Exportar Datos

#### Formato CSV
```csv
id,point_id,name,latitude,longitude,altitude,quality,rtk_status,hdop,satellites,estimated_accuracy,timestamp,date_str,time_str
1,PT_20241120_143022,Punto PT_20241120_143022,40.12345678,-105.12345678,1650.234,4,RTK_FIXED,0.8,24,2.3,1700493022,2024-11-20,14:30:22
```

#### Formato JSON
```json
[
  {
    "id": 1,
    "point_id": "PT_20241120_143022",
    "name": "Punto PT_20241120_143022",
    "latitude": 40.12345678,
    "longitude": -105.12345678,
    "altitude": 1650.234,
    "quality": 4,
    "rtk_status": "RTK_FIXED",
    "hdop": 0.8,
    "satellites": 24,
    "estimated_accuracy": 2.3,
    "timestamp": 1700493022,
    "date_str": "2024-11-20",
    "time_str": "14:30:22"
  }
]
```

---

## 🎛️ Gestión de Servicios

### Ver estado
```bash
sudo systemctl status gnssai-processor
sudo systemctl status gnssai-collector
```

### Iniciar servicios
```bash
sudo systemctl start gnssai-processor
sudo systemctl start gnssai-collector
```

### Detener servicios
```bash
sudo systemctl stop gnssai-processor
sudo systemctl stop gnssai-collector
```

### Ver logs en tiempo real
```bash
# Logs del procesador NMEA
sudo journalctl -u gnssai-processor -f

# Logs de la aplicación web
sudo journalctl -u gnssai-collector -f
```

### Reiniciar servicios
```bash
sudo systemctl restart gnssai-processor
sudo systemctl restart gnssai-collector
```

---

## 📶 Configuración WiFi Hotspot

Si configuraste el WiFi Hotspot durante la instalación:

### Credenciales
- **SSID**: `GNSS-AI-Collector`
- **Contraseña**: `gnssai2024`
- **IP de la Pi**: `192.168.4.1`
- **URL de la app**: `http://192.168.4.1:8080`

### Cambiar credenciales

Editar `/etc/hostapd/hostapd.conf`:
```bash
sudo nano /etc/hostapd/hostapd.conf
```

Cambiar:
```
ssid=TU_NOMBRE_WIFI
wpa_passphrase=TU_CONTRASEÑA
```

Reiniciar:
```bash
sudo systemctl restart hostapd
```

---

## 🔧 Configuración Avanzada

### Cambiar puerto de la aplicación

Editar `point_collector_app.py`:
```python
# Línea ~279
socketio.run(app, host="0.0.0.0", port=8080, ...)
```

Cambiar `8080` por el puerto deseado.

### Cambiar baudrate del K222

Editar `smart_processor.py`:
```python
# Línea ~39
self.uart_baud = 115200
```

Cambiar a `230400`, `460800`, etc. según configuración del K222.

### Ubicación de la base de datos

Los puntos se guardan en:
```
/home/pi/gnssai/point_data/points.db
```

Para hacer backup:
```bash
cp /home/pi/gnssai/point_data/points.db ~/backup_points_$(date +%Y%m%d).db
```

---

## 🐛 Solución de Problemas

### La aplicación no se conecta

1. **Verificar servicios**:
```bash
sudo systemctl status gnssai-processor
sudo systemctl status gnssai-collector
```

2. **Ver logs**:
```bash
sudo journalctl -u gnssai-collector -n 50
```

3. **Verificar puerto abierto**:
```bash
sudo netstat -tulpn | grep 8080
```

### No recibo datos NMEA del K222

1. **Verificar conexión UART**:
```bash
sudo cat /dev/serial0
# Deberías ver frases NMEA
```

2. **Verificar baudrate**:
```bash
# Probar diferentes velocidades
sudo cat /dev/serial0 -b 115200
sudo cat /dev/serial0 -b 230400
```

3. **Ver logs del procesador**:
```bash
sudo journalctl -u gnssai-processor -f
```

### El botón "Tomar Punto" está deshabilitado

El botón solo se habilita cuando:
- ✅ Hay datos GNSS válidos
- ✅ Quality ≥ 1 (al menos GPS fix)
- ✅ Lat/Lon no son 0,0

Espera a que el K222 obtenga fix o RTK.

### WiFi Hotspot no aparece

1. **Verificar hostapd**:
```bash
sudo systemctl status hostapd
```

2. **Reiniciar servicios**:
```bash
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
```

3. **Verificar configuración**:
```bash
sudo nano /etc/hostapd/hostapd.conf
```

---

## 📊 Arquitectura del Sistema

```
┌─────────────────────────────────────────┐
│  ComNav K222 GNSS Module                │
│  UART @ 115200 baud                     │
└──────────────┬──────────────────────────┘
               │ NMEA Sentences
               ▼
┌──────────────────────────────────────────┐
│  smart_processor.py                      │
│  • Parse NMEA (GGA, GSV, TILT)          │
│  • ML Classification (LOS/NLOS)         │
│  • Write /tmp/gnssai_dashboard_data.json│
└──────────────┬───────────────────────────┘
               │ JSON Updates (20 msgs)
               ▼
┌──────────────────────────────────────────┐
│  point_collector_app.py                  │
│  • Flask + SocketIO Server               │
│  • SQLite Database                       │
│  • WebSocket Real-time Updates          │
│  • REST API for Points                   │
└──────────────┬───────────────────────────┘
               │ HTTP/WebSocket
               ▼
┌──────────────────────────────────────────┐
│  Mobile Web Browser                      │
│  • PWA (Installable App)                 │
│  • Real-time Position Display            │
│  • One-touch Point Capture               │
│  • Data Export (CSV/JSON)                │
└──────────────────────────────────────────┘
```

---

## 📝 Base de Datos

### Esquema SQLite

```sql
CREATE TABLE points (
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
);
```

### Acceso directo a la BD

```bash
sqlite3 /home/pi/gnssai/point_data/points.db

# Comandos útiles:
.tables                          # Ver tablas
SELECT * FROM points;            # Ver todos los puntos
SELECT COUNT(*) FROM points;     # Contar puntos
DELETE FROM points WHERE id=1;   # Eliminar punto
.quit                            # Salir
```

---

## 🔐 Seguridad

### Cambiar credenciales WiFi Hotspot

```bash
sudo nano /etc/hostapd/hostapd.conf
# Cambiar: wpa_passphrase=TU_CONTRASEÑA_SEGURA
sudo systemctl restart hostapd
```

### Firewall (opcional)

```bash
# Instalar UFW
sudo apt-get install ufw

# Permitir solo puerto 8080
sudo ufw allow 8080/tcp
sudo ufw enable
```

### Acceso remoto SSH

```bash
# Cambiar puerto SSH (por defecto 22)
sudo nano /etc/ssh/sshd_config
# Cambiar: Port 2222

sudo systemctl restart ssh
```

---

## 📈 Rendimiento

### Optimización para Pi Zero 2W

La configuración está optimizada para:
- ⚡ Procesamiento NMEA a 115200 baud
- ⚡ Actualización web cada 0.5s (2Hz)
- ⚡ Actualización JSON cada 20 frases NMEA
- ⚡ Base de datos SQLite (rápida y eficiente)

### Consumo de recursos

- **CPU**: ~5-10% (Pi Zero 2W)
- **RAM**: ~100MB total
- **Almacenamiento**: ~50KB por 1000 puntos

---

## 🌟 Características Futuras

- [ ] Modo offline completo
- [ ] Sincronización en la nube
- [ ] Edición de puntos guardados
- [ ] Grupos/proyectos de puntos
- [ ] Exportación a formatos GIS (Shapefile, GeoJSON, KML)
- [ ] Visualización de puntos en mapa
- [ ] Navegación a puntos guardados
- [ ] Cálculo de áreas y distancias
- [ ] Importación de puntos

---

## 📄 Licencia

MIT License - Uso libre para proyectos personales y comerciales

---

## 🆘 Soporte

**Documentación completa**: Ver `CLAUDE.md` en el repositorio

**Issues**: https://github.com/tu-usuario/gnssai/issues

**Email**: tu-email@ejemplo.com

---

## 🙏 Créditos

- **GNSS Module**: ComNav K222
- **Hardware**: Raspberry Pi Foundation
- **Framework**: Flask, SocketIO
- **Icons**: Emoji Unicode Standard

---

**¡Disfruta de tu sistema de toma de puntos RTK profesional! 📍**
