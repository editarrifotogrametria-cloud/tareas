# 🎯 Integración FUNCIONABLE + GNSS.AI

## Guía Completa para Pi Zero 2W + ComNav K222

---

## ¿Qué hace esta integración?

✅ Usa **FUNCIONABLE** (Vue.js profesional) como frontend
✅ Conecta con tu **ComNav K222** vía `smart_processor.py`
✅ **Arregla** todos los errores Socket.IO EIO=3
✅ WebSocket en tiempo real (1 Hz)
✅ API REST para datos GNSS
✅ **Elimina** los HTMLs simples del repo

---

## 🚀 Instalación Rápida (5 pasos)

### Paso 1: Actualizar repositorio

En tu **Pi Zero 2W**:

```bash
cd ~/tareas
git pull origin claude/claude-md-mi67snote97rjpmm-01Wd1zLL1Tuk7eysVbqxNXQC

# Verificar que tienes los scripts
ls -lh integrar_funcionable.sh fix_funcionable_socketio.sh
```

### Paso 2: Copiar scripts a tu sistema

```bash
# Copiar scripts de integración
cp ~/tareas/integrar_funcionable.sh ~/gnss-system/
cp ~/tareas/fix_funcionable_socketio.sh ~/gnss-system/

cd ~/gnss-system
chmod +x integrar_funcionable.sh fix_funcionable_socketio.sh
```

### Paso 3: Ejecutar integración automática

```bash
cd ~/gnss-system
./integrar_funcionable.sh
```

Esto hará automáticamente:
- ✅ Clonar FUNCIONABLE desde GitHub
- ✅ Crear `gps_server_funcionable.py` (servidor compatible)
- ✅ Instalar `flask-cors`
- ✅ Crear script de inicio `start_funcionable.sh`
- ✅ Crear documentación

### Paso 4: Arreglar Socket.IO en FUNCIONABLE

```bash
cd ~/gnss-system
./fix_funcionable_socketio.sh
```

Esto parchea los archivos JavaScript compilados de FUNCIONABLE para usar Socket.IO v4+ (compatible con tu servidor).

### Paso 5: ¡Iniciar el sistema!

```bash
cd ~/gnss-system
./start_funcionable.sh
```

O manualmente en dos terminales:

**Terminal 1:**
```bash
cd ~/gnss-system/gnssai
source ../venv/bin/activate
python3 smart_processor.py
```

**Terminal 2:**
```bash
cd ~/gnss-system/gnssai
source ../venv/bin/activate
python3 gps_server_funcionable.py
```

---

## 🌐 Acceder a la Aplicación

Abre en tu navegador (desde tu PC o móvil):

```
http://192.168.0.109:5000
```

**Deberías ver:**
- ✅ Interfaz FUNCIONABLE completa (Vue.js)
- ✅ Datos en tiempo real del K222
- ✅ **SIN errores 400 Socket.IO**
- ✅ WebSocket conectado

---

## 📊 Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│  ComNav K222 (UART /dev/serial0)                        │
│  GPS + GLONASS + Galileo + BeiDou                       │
│  RTK FIXED/FLOAT + IMU/INS                              │
└──────────────────┬──────────────────────────────────────┘
                   │ NMEA @ 115200 baud
                   ↓
┌─────────────────────────────────────────────────────────┐
│  smart_processor.py                                     │
│  - Lee UART                                             │
│  - Parsea NMEA (GGA, GSV, TILT)                        │
│  - Clasificación ML (LOS/NLOS/Multipath)               │
│  - Escribe JSON → /tmp/gnssai_dashboard_data.json      │
└──────────────────┬──────────────────────────────────────┘
                   │ JSON file
                   ↓
┌─────────────────────────────────────────────────────────┐
│  gps_server_funcionable.py                              │
│  - Flask server (puerto 5000)                           │
│  - Socket.IO v5+ (sin errores EIO=3)                   │
│  - API REST: /api/stats, /api/config                   │
│  - WebSocket: actualizaciones en tiempo real           │
│  - Sirve archivos de FUNCIONABLE                        │
└──────────────────┬──────────────────────────────────────┘
                   │ HTTP + WebSocket
                   ↓
┌─────────────────────────────────────────────────────────┐
│  FUNCIONABLE (Vue.js)                                   │
│  - Interfaz profesional de captura de puntos           │
│  - Skyplot, SNR bars, baseline, DOP                    │
│  - Gestión de proyectos                                │
│  - Exportación CSV/KML/GeoJSON                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 API Endpoints

### REST API

**GET /api/stats**
Obtiene estadísticas GNSS actuales

Ejemplo:
```bash
curl http://192.168.0.109:5000/api/stats | jq
```

Respuesta:
```json
{
  "position": {"lat": -12.123456, "lon": -77.123456, "alt": 150.5},
  "satellites": 18,
  "quality": 4,
  "rtk_status": "RTK_FIXED",
  "hdop": 0.8,
  "tilt": {"pitch": 1.2, "roll": -0.5, "heading": 87.3},
  "uptime_sec": 3600
}
```

**GET /api/config**
Obtiene configuración del receptor

**POST /api/config**
Actualiza configuración del receptor

### WebSocket

**Namespace:** `/`

**Eventos:**

- `connect`: Cliente conectado
- `disconnect`: Cliente desconectado
- `gnss_update`: Servidor envía datos cada 1 segundo
- `request_stats`: Cliente solicita datos
- `send_command`: Cliente envía comando al receptor

---

## 🗑️ Limpiar HTMLs Antiguos del Repo

Ya que ahora usas FUNCIONABLE, puedes eliminar los HTMLs simples:

```bash
cd ~/gnss-system/gnssai

# Listar archivos HTML que ya no necesitas
ls -lh *.html templates/*.html 2>/dev/null

# Si quieres borrarlos (CUIDADO: hacer backup primero)
mkdir -p ~/backup_htmls_viejos
mv *.html ~/backup_htmls_viejos/ 2>/dev/null
mv templates/*.html ~/backup_htmls_viejos/ 2>/dev/null

# dashboard_server.py viejo ya no se usa
mv dashboard_server.py ~/backup_htmls_viejos/ 2>/dev/null
mv dashboard_server_old.py ~/backup_htmls_viejos/ 2>/dev/null
```

**IMPORTANTE:** No borres:
- ✅ `gps_server_funcionable.py` (servidor nuevo)
- ✅ `smart_processor.py` (procesador GNSS)
- ✅ Carpeta `~/gnss-system/funcionable/` (frontend Vue.js)

---

## 🐛 Solución de Problemas

### Error: "No se encuentra FUNCIONABLE"

```bash
cd ~/gnss-system
git clone https://github.com/editarrifotogrametria-cloud/FUNCIONABLE.git funcionable
```

### Error: "ModuleNotFoundError: No module named 'flask_cors'"

```bash
cd ~/gnss-system
source venv/bin/activate
pip install flask-cors
```

### Errores Socket.IO persisten

```bash
# Verificar versiones
cd ~/gnss-system
source venv/bin/activate
pip list | grep -i socket
pip list | grep -i flask

# Actualizar si es necesario
pip install --upgrade 'flask-socketio>=5.0.0' 'python-socketio>=5.0.0'

# Volver a aplicar parche
./fix_funcionable_socketio.sh
```

### FUNCIONABLE no muestra datos

1. **Verificar que smart_processor.py está corriendo:**
```bash
ps aux | grep smart_processor
```

2. **Verificar archivo JSON:**
```bash
cat /tmp/gnssai_dashboard_data.json
```

3. **Verificar API:**
```bash
curl http://localhost:5000/api/stats
```

4. **Ver logs del servidor:**
```bash
# Los logs aparecen en la terminal donde ejecutaste gps_server_funcionable.py
```

### Puerto 5000 ya está en uso

```bash
# Ver qué proceso usa el puerto
sudo netstat -tlnp | grep 5000

# Matar proceso anterior
sudo kill -9 <PID>

# O cambiar el puerto en gps_server_funcionable.py (línea final):
# socketio.run(app, host="0.0.0.0", port=5001, ...)
```

### K222 no envía datos

```bash
# Verificar puerto serial
ls -l /dev/serial0

# Ver datos NMEA crudos
sudo cat /dev/serial0

# Si no hay datos, revisar:
# 1. Cableado K222 → Pi Zero
# 2. Alimentación del K222
# 3. Baudrate (debe ser 115200)
```

---

## ⚙️ Configuración Avanzada

### Cambiar puerto del servidor

Editar `~/gnss-system/gnssai/gps_server_funcionable.py`:

```python
# Línea final (aproximadamente línea 250)
socketio.run(app, host="0.0.0.0", port=5001, ...)  # Cambiar 5000 → 5001
```

### Habilitar modo debug

```python
# Última línea
socketio.run(app, host="0.0.0.0", port=5000, debug=True)  # Cambiar False → True
```

### Personalizar configuración GNSS

Editar el endpoint `/api/config` en `gps_server_funcionable.py` para devolver tu configuración específica del K222.

---

## 🚀 Inicio Automático con systemd

Crear servicio para que inicie al encender la Pi:

```bash
sudo nano /etc/systemd/system/gnssai-funcionable.service
```

Contenido:
```ini
[Unit]
Description=GNSS.AI + FUNCIONABLE Server
After=network.target

[Service]
Type=simple
User=gnssai2
WorkingDirectory=/home/gnssai2/gnss-system
ExecStart=/home/gnssai2/gnss-system/start_funcionable.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Activar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable gnssai-funcionable.service
sudo systemctl start gnssai-funcionable.service

# Ver estado
sudo systemctl status gnssai-funcionable.service

# Ver logs
sudo journalctl -u gnssai-funcionable.service -f
```

---

## 📝 Siguiente Nivel

Una vez que todo funcione:

1. **Configurar RTK:**
   - Conectar a base RTK o NTRIP
   - Configurar correcciones en FUNCIONABLE
   - Ver calidad RTK FIXED (1-2 cm)

2. **Calibrar TILT (K222 con IMU):**
   - Mantener bastón vertical
   - Girar 360° para calibración
   - Ver pitch/roll en dashboard

3. **Crear proyectos:**
   - Usar FUNCIONABLE para gestionar proyectos
   - Capturar puntos geodésicos
   - Exportar CSV/KML

4. **Personalizar:**
   - Editar configuración de FUNCIONABLE
   - Ajustar umbrales de precisión
   - Configurar formatos de exportación

---

## ✅ Checklist Final

- [ ] Repositorio actualizado con `git pull`
- [ ] Scripts copiados a `~/gnss-system/`
- [ ] Ejecutado `./integrar_funcionable.sh`
- [ ] Ejecutado `./fix_funcionable_socketio.sh`
- [ ] FUNCIONABLE clonado en `~/gnss-system/funcionable/`
- [ ] Dependencias instaladas (`flask-cors`)
- [ ] `smart_processor.py` corriendo
- [ ] `gps_server_funcionable.py` corriendo
- [ ] Navegador abierto en `http://192.168.0.109:5000`
- [ ] Sin errores 400 Socket.IO
- [ ] Datos GNSS visibles en interfaz
- [ ] WebSocket conectado (indicador en FUNCIONABLE)

---

## 🎉 ¡Listo!

Ahora tienes un sistema GNSS profesional con:

✅ Frontend Vue.js de calidad profesional (FUNCIONABLE)
✅ Backend Flask con Socket.IO v5+ sin errores
✅ Integración completa con ComNav K222
✅ RTK, TILT, ML signal classification
✅ API REST y WebSocket en tiempo real
✅ Gestión de proyectos y exportación de datos

**¡Disfruta capturando puntos geodésicos con precisión centimétrica!** 🛰️📍
