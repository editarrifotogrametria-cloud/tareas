# GPS Point Collector - Interfaz Profesional

Sistema profesional de recolección de puntos GPS similar a Emlid Flow, optimizado para trabajar con receptores RTK en Raspberry Pi Zero.

## 🌟 Características

- **Interfaz Profesional**: Diseño moderno y limpio similar a Emlid Flow
- **Conexión por IP**: Conecta fácilmente a tu Raspberry Pi Zero por red
- **Tiempo Real**: Visualización en vivo de datos GPS/RTK
- **Recolección de Puntos**: Toma puntos con precisión RTK Fixed/Float
- **Exportación CSV**: Exporta tus puntos recolectados a formato CSV
- **Responsive**: Funciona en desktop, tablet y móvil
- **Multi-interfaz**: Dashboard técnico y collector profesional

## 📦 Archivos Incluidos

```
├── gps_collector.html      # Interfaz principal de recolección de puntos
├── gps_server.py           # Servidor Flask con múltiples interfaces
├── dashboard_server.py     # Servidor dashboard técnico (original)
└── README_GPS_COLLECTOR.md # Esta documentación
```

## 🚀 Inicio Rápido

### Opción 1: Servidor Completo (Recomendado)

```bash
python3 gps_server.py
```

Esto iniciará el servidor en `http://0.0.0.0:5000` con:
- `/` - Página de inicio con enlaces a las interfaces
- `/collector` - Interfaz de recolección de puntos (estilo Emlid Flow)
- `/dashboard` - Dashboard técnico con ML y Tilt
- `/api/stats` - API REST con datos GPS en JSON

### Opción 2: Solo Dashboard Técnico

```bash
python3 dashboard_server.py
```

### Opción 3: HTML Standalone

Abre directamente `gps_collector.html` en tu navegador y configura la IP manualmente.

## 📱 Uso de la Interfaz Collector

### 1. Conectar al Receptor

1. Abre la interfaz en tu navegador: `http://[IP-RASPBERRY]:5000/collector`
2. Ingresa la IP de tu Raspberry Pi Zero (ej: `192.168.1.100`)
3. Ingresa el puerto (por defecto: `5000`)
4. Click en "Conectar"

### 2. Esperar Fix RTK

- Verifica que el badge muestre **RTK FIXED** o **RTK FLOAT**
- Observa los satélites y HDOP
- La precisión debe ser < 5cm para RTK Fixed

### 3. Tomar Puntos

1. Click en el botón "Tomar Punto"
2. Ingresa un nombre para el punto (ej: `P1`, `ESQUINA_NE`, etc.)
3. El punto se guarda automáticamente con:
   - Coordenadas (lat, lon, altura)
   - Calidad RTK
   - Número de satélites
   - HDOP y precisión
   - Timestamp

### 4. Exportar Datos

1. Click en "Exportar CSV"
2. Se descargará un archivo `gps_points_YYYY-MM-DD.csv`
3. Formato del CSV:
   ```
   Nombre,Latitud,Longitud,Altura,Calidad,Satelites,HDOP,Precision,Fecha
   P1,-33.4567890,-70.6543210,550.123,RTK FIXED,24,0.8,1.2,2025-01-15T10:30:45.123Z
   ```

## 🔧 Configuración en Raspberry Pi Zero

### Requisitos

```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-flask
pip3 install flask flask-socketio
```

### Configuración Automática al Inicio

Crea un servicio systemd:

```bash
sudo nano /etc/systemd/system/gps-server.service
```

Contenido:

```ini
[Unit]
Description=GPS Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/gps
ExecStart=/usr/bin/python3 /home/pi/gps/gps_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Habilitar e iniciar:

```bash
sudo systemctl enable gps-server
sudo systemctl start gps-server
sudo systemctl status gps-server
```

## 🌐 Acceso desde Diferentes Dispositivos

### Mismo Wi-Fi

Si tu Pi Zero y tu dispositivo están en la misma red:

```
http://192.168.1.XXX:5000/collector
```

### Hotspot de la Pi Zero

Configura la Pi Zero como punto de acceso:

```bash
sudo apt-get install hostapd dnsmasq
# Configurar hostapd y dnsmasq
# Acceder en: http://192.168.4.1:5000/collector
```

### Conexión Directa USB (USB Gadget)

Configura USB Ethernet en la Pi Zero:

```
http://raspberrypi.local:5000/collector
```

## 📊 API REST

### GET /api/stats

Retorna datos GPS en formato JSON:

```json
{
  "position": {
    "lat": -33.4567890,
    "lon": -70.6543210,
    "alt": 550.123
  },
  "quality": 4,
  "rtk_status": "RTK FIXED",
  "satellites": 24,
  "hdop": 0.8,
  "estimated_accuracy": 1.2,
  "nmea_sent": 12345,
  "rtcm_sent": 6789,
  "uptime_sec": 3600,
  "tilt": {
    "pitch": 0.5,
    "roll": -0.3,
    "heading": 87.2,
    "angle": 0.6,
    "status": "VALID"
  }
}
```

## 🎨 Personalización

### Cambiar Puerto

Edita `gps_server.py` línea final:

```python
socketio.run(app, host="0.0.0.0", port=8080)  # Cambiar 5000 a 8080
```

### Modificar Intervalo de Actualización

En `gps_collector.html`, busca:

```javascript
pollInterval = setInterval(fetchGPSData, 1000);  // 1000ms = 1 segundo
```

## 🐛 Solución de Problemas

### No se puede conectar

1. Verifica que el servidor esté corriendo:
   ```bash
   sudo systemctl status gps-server
   ```

2. Verifica el firewall:
   ```bash
   sudo ufw allow 5000/tcp
   ```

3. Verifica la IP correcta:
   ```bash
   hostname -I
   ```

### No hay datos GPS

1. Verifica que el archivo `/tmp/gnssai_dashboard_data.json` exista
2. Verifica que el proceso de recolección GPS esté corriendo
3. Revisa los logs del servidor

### Puntos no se guardan

- Verifica que tengas fix RTK (badge verde)
- Mira la consola del navegador (F12) para errores
- Verifica que JavaScript esté habilitado

## 📝 Formato de Datos

### Calidad GPS

| Código | Descripción | Color |
|--------|-------------|-------|
| 0 | NO FIX | Rojo |
| 1 | GPS | Naranja |
| 2 | DGPS | Amarillo |
| 5 | RTK FLOAT | Azul |
| 4 | RTK FIXED | Verde |

### Precisión Esperada

- RTK Fixed: 1-2 cm horizontal, 2-3 cm vertical
- RTK Float: 10-50 cm
- DGPS: 0.5-2 m
- GPS: 2-10 m

## 🔗 Integración con Otros Sistemas

### QGIS

Importa el CSV exportado:
1. Capa → Añadir capa → Añadir capa de texto delimitado
2. Selecciona el archivo CSV
3. Geometría: Coordenadas de punto
4. X = Longitud, Y = Latitud
5. SRC: EPSG:4326 (WGS84)

### Google Earth

Convierte CSV a KML usando scripts o herramientas online.

### AutoCAD Civil 3D

Importa puntos desde CSV con formato personalizado.

## 📄 Licencia

Este software es de código abierto. Úsalo libremente para proyectos personales y comerciales.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📞 Soporte

Para problemas o preguntas:
- Abre un issue en GitHub
- Revisa la documentación
- Consulta los logs del servidor

---

**Desarrollado con ❤️ para la comunidad GPS/RTK**
