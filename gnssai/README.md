# GNSS.AI - Sistema Completo de GPS/RTK

Este directorio contiene todos los componentes necesarios para ejecutar el sistema GNSS.AI en tu Raspberry Pi Zero 2 W.

## 📁 Estructura de Archivos

```
gnssai/
├── dashboard_server.py          # Servidor del Dashboard técnico
├── gps_server.py                # Servidor GPS Professional (multi-interfaz)
├── gnssai_collector.py          # Colector de datos GNSS
├── gnssai_trainer.py            # Entrenador de modelos ML
├── smart_processor.py           # Procesador inteligente de señales
├── start_dashboard.sh           # Script para iniciar el Dashboard
├── start_gps_professional.sh    # Script para iniciar GPS Professional
├── templates/
│   └── index.html              # Interfaz web del Dashboard
└── README.md                    # Este archivo
```

## 🚀 Cómo Usar

### Opción 1: Dashboard Técnico

El Dashboard muestra estadísticas en tiempo real, clasificación ML y datos TILT.

```bash
cd ~/gnssai
./start_dashboard.sh
```

Accede en: `http://raspberrypi.local:5000` o `http://<IP>:5000`

### Opción 2: GPS Professional (RECOMENDADO)

Interfaz completa con gestión de proyectos, DATUM, tomar puntos, replantear, PPP, TILT y cámara.

```bash
cd ~/gnssai
./start_gps_professional.sh
```

Accede en:
- **Home**: `http://raspberrypi.local:5000`
- **Professional**: `http://raspberrypi.local:5000/professional` ⭐
- **Collector**: `http://raspberrypi.local:5000/collector`
- **Dashboard**: `http://raspberrypi.local:5000/dashboard`
- **API**: `http://raspberrypi.local:5000/api/stats`

## 🔧 Requisitos

### Python 3 y dependencias

```bash
# Instalar dependencias
pip3 install flask flask-socketio

# Para funcionalidades completas (opcional)
pip3 install numpy pandas scikit-learn pillow
```

### Permisos de puerto (opcional)

Si quieres usar el puerto 80 en lugar del 5000:

```bash
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.9
```

## 📊 Archivo de Datos

Ambos servidores leen datos desde:
```
/tmp/gnssai_dashboard_data.json
```

Este archivo debe ser actualizado por tu colector GNSS (gnssai_collector.py o smart_processor.py).

## 🔄 Inicio Automático (Systemd)

Para que el servidor inicie automáticamente al encender la Raspberry Pi:

### Para Dashboard:

```bash
sudo nano /etc/systemd/system/gnssai-dashboard.service
```

Contenido:
```ini
[Unit]
Description=GNSS.AI Dashboard Server
After=network.target

[Service]
Type=simple
User=gnssai2
WorkingDirectory=/home/gnssai2/gnssai
ExecStart=/usr/bin/python3 /home/gnssai2/gnssai/dashboard_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activar:
```bash
sudo systemctl enable gnssai-dashboard
sudo systemctl start gnssai-dashboard
sudo systemctl status gnssai-dashboard
```

### Para GPS Professional:

```bash
sudo nano /etc/systemd/system/gps-professional.service
```

Contenido:
```ini
[Unit]
Description=GPS Professional Server
After=network.target

[Service]
Type=simple
User=gnssai2
WorkingDirectory=/home/gnssai2/gnssai
ExecStart=/usr/bin/python3 /home/gnssai2/gnssai/gps_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activar:
```bash
sudo systemctl enable gps-professional
sudo systemctl start gps-professional
sudo systemctl status gps-professional
```

## 🐛 Solución de Problemas

### El servidor no inicia

1. Verifica que Python3 esté instalado: `python3 --version`
2. Verifica las dependencias: `pip3 list | grep -i flask`
3. Revisa los logs: `journalctl -u gps-professional -f`

### No se muestran datos

1. Verifica que el archivo JSON exista: `ls -lh /tmp/gnssai_dashboard_data.json`
2. Verifica el contenido: `cat /tmp/gnssai_dashboard_data.json`
3. Asegúrate de que el colector GNSS esté corriendo

### Puerto 5000 en uso

Si el puerto 5000 ya está en uso, puedes cambiar el puerto editando los archivos `.py`:

```python
# Al final del archivo, cambia:
socketio.run(app, host="0.0.0.0", port=5000, ...)
# Por ejemplo a puerto 8080:
socketio.run(app, host="0.0.0.0", port=8080, ...)
```

## 📝 Notas

- **Dashboard** (`dashboard_server.py`): Solo muestra el dashboard técnico
- **GPS Professional** (`gps_server.py`): Servidor completo con múltiples interfaces
- Ambos pueden correr simultáneamente en puertos diferentes si modificas la configuración

## 🆘 Soporte

Para más información, consulta la documentación principal en el directorio raíz del proyecto.
