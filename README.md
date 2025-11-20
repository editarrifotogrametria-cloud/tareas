# 📍 GNSS.AI - Sistema RTK Professional para Raspberry Pi

Sistema completo de procesamiento GNSS/RTK con interfaz web profesional para toma de puntos.

[![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)

## 🎯 Características Principales

- ✅ **Interfaz Web Profesional** - PWA instalable en celular
- ✅ **Toma de Puntos RTK** - Un toque para guardar coordenadas
- ✅ **Clasificación ML** - Detección LOS/Multipath/NLOS en tiempo real
- ✅ **Dashboard en Vivo** - Visualización de posición y estadísticas
- ✅ **Exportación Múltiple** - CSV y JSON
- ✅ **Auto-inicio** - Servicios systemd configurados
- ✅ **WiFi Hotspot** - Acceso directo sin router

## 📦 Hardware Soportado

- **Módulos GNSS**: ComNav K222, K902, K922
- **Plataforma**: Raspberry Pi Zero 2W (o superior)
- **Interface**: UART @ 115200 baud
- **Conectividad**: WiFi, Bluetooth SPP (opcional)

## 🚀 Instalación Rápida

### Opción 1: Instalación Automática (Recomendada)

```bash
# En tu Raspberry Pi
git clone https://github.com/editarrifotogrametria-cloud/tareas.git gnssai
cd gnssai
chmod +x install_pi_zero.sh
./install_pi_zero.sh
sudo reboot
```

### Opción 2: Instalación Manual

```bash
# Instalar dependencias
sudo apt-get update
sudo apt-get install python3 python3-pip python3-serial

# Instalar paquetes Python
pip3 install -r requirements.txt

# Configurar UART
sudo raspi-config
# Interface Options → Serial Port
# Login shell: No
# Serial hardware: Yes

# Iniciar aplicación
python3 point_collector_app.py
```

## 📱 Uso

### Acceso a la Aplicación Web

Desde tu celular o navegador:

```
WiFi Hotspot: http://192.168.4.1:8080
Red Local:    http://[IP-RASPBERRY]:8080
```

### Tomar un Punto

1. Espera que aparezca **RTK FIXED** (verde)
2. Presiona el botón **📍 TOMAR PUNTO**
3. El punto se guarda automáticamente

### Exportar Datos

- **📄 CSV**: Para Excel/LibreOffice
- **💾 JSON**: Para procesamiento programático

## 📂 Estructura del Proyecto

```
gnssai/
├── 📱 Aplicaciones
│   ├── point_collector_app.py      # App web de puntos (puerto 8080)
│   ├── dashboard_server.py         # Dashboard general (puerto 5000)
│   └── bluetooth_spp_server.py     # Servidor Bluetooth SPP
│
├── 🔧 Procesamiento GNSS
│   ├── smart_processor.py          # Procesador NMEA principal
│   ├── ml_classifier.py            # Clasificador ML de señales
│   ├── gnssai_collector.py         # Recolección datos ML
│   └── gnssai_trainer.py           # Entrenamiento modelos
│
├── 🌐 Interfaz Web
│   ├── templates/
│   │   └── point_collector.html    # PWA móvil
│   └── static/
│       ├── manifest.json            # Config PWA
│       └── icon-*.svg               # Iconos app
│
├── 🔧 Configuración
│   ├── app.js                       # Panel config K922
│   ├── index.guia.html             # UI configuración
│   └── styles.css                  # Estilos
│
├── 📚 Documentación
│   ├── README.md                    # Este archivo
│   ├── README_POINT_COLLECTOR.md   # Guía completa
│   ├── QUICK_START.md              # Inicio rápido
│   ├── CLAUDE.md                   # Docs técnicas
│   └── RESUMEN_INSTALACION.txt     # Referencia visual
│
├── 🛠️ Scripts
│   ├── install_pi_zero.sh          # Instalador automático
│   └── generate_icons.py           # Generador iconos PWA
│
├── 📊 Datos (creados en runtime)
│   ├── point_data/                 # Base de datos puntos
│   ├── ml_training_data/           # Datos entrenamiento
│   └── ml_models/                  # Modelos entrenados
│
└── 📦 Configuración
    ├── requirements.txt             # Dependencias Python
    └── .gitignore                  # Archivos ignorados
```

## 🎮 Comandos Útiles

```bash
# Ver estado de servicios
sudo systemctl status gnssai-processor
sudo systemctl status gnssai-collector

# Ver logs en tiempo real
sudo journalctl -u gnssai-processor -f
sudo journalctl -u gnssai-collector -f

# Ver datos NMEA del módulo
sudo cat /dev/serial0

# Reiniciar servicios
sudo systemctl restart gnssai-processor
sudo systemctl restart gnssai-collector

# Backup de base de datos
cp ~/gnssai/point_data/points.db ~/backup_$(date +%Y%m%d).db
```

## 📖 Documentación Completa

- **[QUICK_START.md](QUICK_START.md)** - Instalación paso a paso con diagramas
- **[README_POINT_COLLECTOR.md](README_POINT_COLLECTOR.md)** - Guía completa de Point Collector
- **[CLAUDE.md](CLAUDE.md)** - Documentación técnica del sistema
- **[RESUMEN_INSTALACION.txt](RESUMEN_INSTALACION.txt)** - Referencia rápida

## 🔧 Configuración Avanzada

### Cambiar Puerto UART

Editar `smart_processor.py`:
```python
self.uart_port = "/dev/serial0"
self.uart_baud = 115200  # Cambiar a 230400 si es necesario
```

### Cambiar Puerto Web

Editar `point_collector_app.py`:
```python
socketio.run(app, host="0.0.0.0", port=8080, ...)  # Cambiar puerto
```

### Configurar WiFi Hotspot

Editar `/etc/hostapd/hostapd.conf`:
```
ssid=TU_NOMBRE_WIFI
wpa_passphrase=TU_CONTRASEÑA
```

## 🐛 Solución de Problemas

### No recibo datos NMEA

```bash
# Verificar puerto serial
ls -l /dev/serial0

# Ver datos en vivo
sudo cat /dev/serial0
```

### Aplicación no carga

```bash
# Reiniciar servicios
sudo systemctl restart gnssai-processor
sudo systemctl restart gnssai-collector

# Ver logs de errores
sudo journalctl -u gnssai-collector -n 50
```

### Botón deshabilitado

El botón solo se habilita cuando:
- ✅ Hay datos GNSS válidos
- ✅ Quality ≥ 1 (al menos GPS fix)
- ✅ Coordenadas no son 0,0

## 🌟 Características Futuras

- [ ] Sincronización en la nube
- [ ] Edición de puntos guardados
- [ ] Visualización en mapa
- [ ] Exportación a formatos GIS (Shapefile, KML, GeoJSON)
- [ ] Cálculo de áreas y distancias
- [ ] Navegación a puntos guardados

## 📄 Licencia

MIT License - Ver archivo LICENSE para más detalles

## 🙏 Agradecimientos

- ComNav Technology por los módulos K222/K902/K922
- Raspberry Pi Foundation
- Comunidad Flask y Python

---

**Desarrollado para profesionales de topografía y geomática** 📍

Para soporte y preguntas: Ver documentación en `CLAUDE.md`
