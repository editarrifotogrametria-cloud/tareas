# Configuración del Puerto COM3 para ComNav K222

## 📋 Resumen

El dispositivo ComNav K222 ahora está configurado para recibir comandos mediante el puerto COM3 (o el puerto serial equivalente en tu sistema).

## 🔧 Configuración

### Método 1: Archivo .env (Recomendado)

1. Edita el archivo `.env` en el directorio `gnssai/`:
```bash
GPS_PORT=COM3
GPS_BAUD=115200
```

2. En Windows:
```
GPS_PORT=COM3
```

3. En Linux/Raspberry Pi (USB):
```
GPS_PORT=/dev/ttyUSB2    # COM3 = tercer puerto USB (0, 1, 2)
```

4. En Linux/Raspberry Pi (ACM):
```
GPS_PORT=/dev/ttyACM2    # COM3 = tercer puerto ACM (0, 1, 2)
```

5. En Raspberry Pi (serial por defecto):
```
GPS_PORT=/dev/serial0
```

### Método 2: Script de inicio

Ejecuta el script que detecta automáticamente el puerto:

```bash
cd gnssai/
./config_com3.sh
```

Este script:
- Detecta automáticamente el sistema operativo
- Configura el puerto correcto (COM3 en Windows, /dev/ttyUSB2 en Linux, etc.)
- Inicia el servidor automáticamente

### Método 3: Variable de entorno manual

```bash
# En Linux/Mac
export GPS_PORT=COM3
python3 gps_server.py

# En Windows (CMD)
set GPS_PORT=COM3
python gps_server.py

# En Windows (PowerShell)
$env:GPS_PORT="COM3"
python gps_server.py
```

## 🌐 Mejoras en el HTML

El archivo `templates/index.html` ahora incluye:

1. **Archivos CSS estáticos** (para mejor rendimiento):
   - `/static/css/chunk-vendors.d93e9d9a.css`
   - `/static/css/index.8349ed33.css`

2. **Archivos JavaScript estáticos**:
   - `/static/js/chunk-vendors.31517009.js`
   - `/static/js/chunk-common.22a6f926.js`
   - `/static/js/index.0bca27f0.js`

Estos archivos proporcionan:
- Estilos profesionales con Ant Design
- Componentes Vue.js optimizados
- Mejor UX para la aplicación web

## 📡 Comandos ComNav disponibles

Los comandos se envían automáticamente al puerto COM3 cuando haces clic en los botones de la interfaz web:

- **SAVECONFIG**: Guardar configuración en el GPS
- **FRESET**: Reset a valores de fábrica
- **CONFIG**: Configurar parámetros
- **RTCM**: Configurar correcciones RTK

## 🚀 Inicio rápido

```bash
cd /home/user/tareas/gnssai/

# Opción 1: Con detección automática de puerto
./config_com3.sh

# Opción 2: Manual con puerto específico
export GPS_PORT=COM3
python3 gps_server.py
```

Luego abre en tu navegador:
```
http://localhost:5000/professional
```

## 🛠️ Verificar puerto serial

### En Windows
1. Abre el Administrador de Dispositivos
2. Busca "Puertos (COM y LPT)"
3. Identifica tu dispositivo ComNav K222
4. Anota el número COM (ej: COM3, COM4, etc.)

### En Linux
```bash
# Ver todos los puertos USB
ls -la /dev/ttyUSB*

# Ver todos los puertos ACM
ls -la /dev/ttyACM*

# Ver información detallada
dmesg | grep tty
```

## 📝 Archivos modificados

- `templates/index.html` - Actualizado con archivos CSS/JS estáticos
- `gps_server.py` - Agregada ruta `/api/comnav/command` para comandos
- `smart_processor.py` - Puerto configurable via variable GPS_PORT
- `gnssai_collector.py` - Puerto configurable via variable GPS_PORT
- `config_com3.sh` - Script de inicio con detección automática
- `.env` - Archivo de configuración

## ✅ Verificación

Para verificar que el puerto está configurado correctamente:

1. Inicia el servidor
2. Abre la interfaz web en `/professional`
3. Ve a la pestaña "Config"
4. Haz clic en "Conectar GPS"
5. Envía un comando de prueba (ej: SAVECONFIG)

Si todo funciona correctamente, verás una confirmación en pantalla.
